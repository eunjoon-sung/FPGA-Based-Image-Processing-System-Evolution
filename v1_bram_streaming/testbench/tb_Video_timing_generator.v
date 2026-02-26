`timescale 1ns / 1ps

module tb_Video_timing_generator();

    // 1. Inputs
    reg clk;
    reg rst;
    reg [11:0] sram_data;

    // 2. Outputs
    wire [16:0] rd_addr;
    wire hsync;
    wire vsync;
    wire de;
    wire [23:0] rgb_data;

    // 3. DUT 연결
    Video_timing_generator dut (
        .clk(clk),
        .rst(rst),
        .sram_data(sram_data),
        .rd_addr(rd_addr),
        .hsync(hsync),
        .vsync(vsync),
        .de(de),
        .rgb_data(rgb_data)
    );

    // 4. 클럭 생성 (25MHz = 40ns)
    always begin
        #20 clk = ~clk; 
    end

    // =========================================================
    // [수정됨] 정확히 2클럭 지연(Latency=2)을 갖는 가짜 SRAM 모델
    // =========================================================
    reg [16:0] addr_d1; // 1클럭 지연용 레지스터

    always @(posedge clk) begin
        // [T=1] 첫 번째 클럭: 주소를 내부 레지스터에 저장
        addr_d1 <= rd_addr;
        
        // [T=2] 두 번째 클럭: 저장된 주소로 데이터 출력
        // (테스트를 위해 데이터 값 = 주소 값으로 설정)
        sram_data <= addr_d1[11:0]; 
    end
    // =========================================================

    // 6. 테스트 시나리오
    initial begin
        // 초기화
        clk = 0;
        rst = 1;
        sram_data = 0;
        addr_d1 = 0;

        // 리셋 유지
        #100;
        
        // 리셋 해제
        rst = 0;
        $display("=== Simulation Start ===");

        // 충분히 실행 (약 2~3라인)
        #150000; 

        $stop;
    end

endmodule
