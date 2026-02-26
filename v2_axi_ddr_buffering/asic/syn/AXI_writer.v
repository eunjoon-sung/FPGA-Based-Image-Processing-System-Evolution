`timescale 1ns / 1ps
// 만약 Stream 데이터를 DDR에 넣고 싶다면? -> 누군가가 중간에서 "주소표"를 붙여줘야 함. 주소가 필수인 "Memory Mapped" 방식
// 그게 이 모듈의 역할
// VDMA의 핵심 기능(Stream to MM)을 구현하는 모듈울 설계

module AXI_writer #(
    parameter AXI_ADDR_WIDTH = 32,
    parameter AXI_DATA_WIDTH = 64
)
(
    input wire pclk,
    input wire clk_100Mhz,
    input wire rst,
    input wire [15:0] mixed_data, // from Chroma_key_mixer.v
    input wire pixel_valid, // from Camera_capture.v
    input wire frame_done, 
    input wire [31:0] FRAME_BASE_ADDR, // for Double / Triple Frame Buffer
    
    // AXI master port
    // 1. 주소 채널
    output reg [AXI_ADDR_WIDTH -1 : 0] AWADDR,
    output reg AWVALID,
    input wire AWREADY,
    output wire [7:0] AWLEN, // burst 길이 0-255
    output wire [2:0] AWSIZE, // data size
    output wire [1:0] AWBURST, //  burst type
    output wire [3:0] AWCACHE,
    output wire [2:0] AWPROT,
    
    // 2. 데이터 채널
    output wire [AXI_DATA_WIDTH -1 : 0] WDATA,
    output reg WVALID,
    input wire WREADY,
    output reg WLAST, // 마지막 Data
    output wire [7:0] WSTRB, // Write Strobe
    
    // 3. 응답 채널
    input wire BVALID,
    output wire BREADY,
    input wire [1:0] BRESP, // [추가] 이거 빠져서 AXI 통신 먹통이었음.
    
    output wire o_prog_full,
    output reg [1:0] state,
    output reg [AXI_ADDR_WIDTH -1 : 0] ADDR_OFFSET
    );


    localparam IDLE = 0;
    localparam ADDR_SEND = 1;
    localparam DATA_SEND = 2;
    localparam WAIT_RES = 3;

        
    reg [1:0] next_state;
    reg [7:0] data_count; // 64개 세는 용도
        

    assign AWLEN   = 8'd15;     // 64 burst
    assign AWSIZE  = 3'b011;   // 8 byte (64 bit)
    assign AWBURST = 2'b01;    // INCR (주소 증가 모드)
    assign AWCACHE = 4'b0010; // DDR 컨트롤러 활성화 
    assign AWPROT  = 3'b000;  // 보안 검사 통과용
    assign WSTRB   = 8'hFF;    // 모든 바이트 유효    
    assign BREADY = 1;

    
    // fifo
    wire fifo_full;
    wire prog_full; // 253 까지 차면 출발신호 보냄
    wire fifo_empty;
    wire [63:0] fifo_data;
    wire fifo_rd_en;
    wire [12:0] rd_data_count;

    // frame_done▒~]~D ▒~N~D▒~J▒▒~\ ▒~@▒~Y~X
    reg frame_done_d1;
    reg frame_done_d2;
    wire frame_done_pulse = (frame_done_d1 == 1'b1 && frame_done_d2 == 1'b0);
    wire vsync_negedge = (frame_done_d2 == 1'b1 && frame_done_d1 == 1'b0);



    assign o_prog_full = prog_full;   
    
    // WREADY▒~K| ▒~X▒▒~W~P ▒~T▒~\ ▒| ~D▒~K▒▒~P~X▒~V▒▒~U▒ ▒~U~X▒~@▒~\ wire▒~\ ▒~W▒결▒~U▒▒~L
    assign WDATA = fifo_data;
    assign fifo_rd_en = (state == DATA_SEND) && (WREADY == 1) && (WVALID == 1); // WVALID▒~@ 1▒~]▒ ▒~P~X▒~V▒▒~U▒ ▒~K▒▒| ~\▒~\ ▒~M▒▒~]▒▒~D▒를 ▒~O|  ▒~H~X ▒~^~H▒~\▒▒~@▒~\, 그▒~U~L▒~@▒~D▒ FIFO를 ▒~]▒▒~V▒▒~U▒ ▒~U▒
    
        
    always @(posedge clk_100Mhz) begin
        frame_done_d1 <= frame_done;
        frame_done_d2 <= frame_done_d1;
    end
    
    // 1. sequential logic
    always @(posedge clk_100Mhz) begin
        if (rst) begin
            state <= 0;
            data_count <= 0;
            AWADDR <= FRAME_BASE_ADDR;
            ADDR_OFFSET <= 0;
            AWVALID <= 0; WVALID <= 0;
        end
        else begin
            if (frame_done_d2) begin
                ADDR_OFFSET <= 0;   // 주소 0x0100_0000 세팅
                state <= IDLE;      
                data_count <= 0;
                AWVALID <= 0; WVALID <= 0;
            end
            else begin
                state <= next_state;
    
                case (state)
                    IDLE: begin
                        data_count <= 0;
                        AWVALID <= 0;
                        AWADDR <= FRAME_BASE_ADDR + ADDR_OFFSET;
                    end
                    
                    ADDR_SEND: begin // 주소는 64번 동안 자동으로 8씩 증가하며 알아서 써짐 (64bit -> 8 byte)
                        if (AWVALID && AWREADY) begin // valid, ready 둘 다 1인 순간 모두 전송됨
                            AWVALID <= 0;
                        end
                        else begin
                            AWVALID <= 1;
                        end
                    end
                    
                    DATA_SEND: begin
                        WVALID <= 1;
                        if (fifo_rd_en) begin // "FWFT mode" 이므로 이 신호는 데이터 받았다는 확인 신호임. wdata는 이미 나와있는 상태.
                            data_count <= data_count + 1;
                            
                            if (data_count == 14) begin
                                WLAST <= 1'b1;
                            end
                            
                            if (data_count == 15) begin
                                data_count <= 0;
                                WLAST <= 0;
                                WVALID <= 0; // 64번 데이터 전송 (총 256픽셀)
                            end
                        end
                    end
                    
                    WAIT_RES: begin
                        if (BREADY && BVALID == 1) begin
                            if (ADDR_OFFSET < 32'd153472) begin // 32'd153088 (64 burst) , 32'd153472 (16 burst)
                                ADDR_OFFSET <= ADDR_OFFSET + 32'd128;//32'd512;
                            end
                        end
                    end
                endcase
            end
        end
    end
    
    // 2. combinational logic
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (rd_data_count >= 10'd16) begin
                    next_state = ADDR_SEND;
                end
            end
            
            ADDR_SEND: begin
                if (AWREADY == 1 && AWVALID == 1) begin
                    next_state = DATA_SEND;
                end
            end
            
            DATA_SEND: begin
                if (data_count == 15 && WREADY == 1) begin
                    next_state = WAIT_RES;
                end
            end
            
            WAIT_RES: begin
                if (BREADY == 1 && BVALID == 1) begin
                    next_state = IDLE;
                end
            end
        endcase
    end
    
    
    // FIFO DUT
// ==========================================
    // 순수 RTL 비동기 FIFO (Xilinx IP 대체)
    // ==========================================
    async_fifo #(
        .DATA_WIDTH(64),
        .ADDR_WIDTH(8) // 2^8 = 256 Depth
    ) u_fifo_writer (
        .rst(rst || frame_done_d2),
        
        // --- Write Domain (pclk: 24MHz) ---
        .wr_clk(pclk),
        .wr_en(pixel_valid),
        .din({48'd0, mixed_data}), // [팩트 체크 필요] 16bit -> 64bit 패딩 적용
        .full(fifo_full),
        .prog_full(prog_full),
        
        // --- Read Domain (clk_100Mhz: 100MHz) ---
        .rd_clk(clk_100Mhz),
        .rd_en(fifo_rd_en),
        .dout(fifo_data), // 64bit 출력
        .empty(fifo_empty),
        .rd_data_count(rd_data_count[8:0]) // 기존 13bit wire에 9bit만 연결
    );
    
 
endmodule
