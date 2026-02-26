`timescale 1ns / 1ps

module tb_SRAM_writer;

    // Inputs
    reg clk;
    reg rst;
    reg [11:0] scaled_data;
    reg scaled_valid;

    // Outputs
    wire [16:0] bram_addr;
    wire [11:0] bram_data;
    wire bram_we;

    // DUT (Device Under Test) 인스턴스
    SRAM_writer uut (
        .clk(clk), 
        .rst(rst), 
        .scaled_data(scaled_data), 
        .scaled_valid(scaled_valid), 
        .bram_addr(bram_addr), 
        .bram_data(bram_data), 
        .bram_we(bram_we)
    );

    // 1. 클럭 생성 (25MHz -> 40ns)
    always #20 clk = ~clk;

    initial begin
        // 초기화
        clk = 0;
        rst = 1;
        scaled_data = 0;
        scaled_valid = 0;

        // 리셋 해제
        #100;
        rst = 0;
        #40;

        $display("=== Simulation Start ===");

        // ---------------------------------------------------------
        // 시나리오 1: 연속 데이터 쓰기 테스트
        // Downscaler가 데이터를 팍팍 줄 때 주소가 잘 올라가는지 확인
        // ---------------------------------------------------------
        $display("Test 1: Continuous Write");
        
        // Data 0xAA1 (Valid) -> Address 0에 써져야 함
        @(posedge clk);
        scaled_data = 12'hAA1;
        scaled_valid = 1;

        // Data 0xAA2 (Valid) -> Address 1에 써져야 함
        @(posedge clk);
        scaled_data = 12'hAA2;
        scaled_valid = 1;

        // Data 0xAA3 (Valid) -> Address 2에 써져야 함
        @(posedge clk);
        scaled_data = 12'hAA3;
        scaled_valid = 1;
        
        // ---------------------------------------------------------
        // 시나리오 2: 데이터가 띄엄띄엄 올 때 (Gaps)
        // Downscaler가 홀수 픽셀을 버릴 때 주소가 멈추는지 확인
        // ---------------------------------------------------------
        $display("Test 2: Write with Gaps (Hold Address)");

        // Data Invalid (Valid=0) -> 주소 증가하면 안 됨! (Address 3 유지해야 함)
        @(posedge clk);
        scaled_valid = 0;
        scaled_data = 12'hFFF; // 쓰레기 값 (무시되어야 함)

        @(posedge clk); // 한 번 더 쉼
        scaled_valid = 0;

        // Data 0xBB1 (Valid) -> Address 3에 써져야 함 (이제서야 증가)
        @(posedge clk);
        scaled_data = 12'hBB1;
        scaled_valid = 1;

        // 다시 쉼
        @(posedge clk);
        scaled_valid = 0;

        // Data 0xBB2 (Valid) -> Address 4에 써져야 함
        @(posedge clk);
        scaled_data = 12'hBB2;
        scaled_valid = 1;

        // ---------------------------------------------------------
        // 종료
        // ---------------------------------------------------------
        @(posedge clk);
        scaled_valid = 0;
        
        #100;
        $display("=== Simulation End ===");
        $finish;
    end
    
    // 모니터링
    always @(posedge clk) begin
        if (bram_we) begin
            $display("Time: %t | Write Addr: %d | Data: %h", $time, bram_addr, bram_data);
        end
    end

endmodule
