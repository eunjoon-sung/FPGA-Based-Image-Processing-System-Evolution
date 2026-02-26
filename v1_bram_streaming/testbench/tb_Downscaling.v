`timescale 1ns / 1ps

module tb_Downscaling;

    // Inputs
    reg clk;
    reg rst;
    reg [11:0] fifo_dout;
    reg fifo_empty;

    // Outputs
    wire fifo_rd_en;
    wire [11:0] scaled_data;
    wire scaled_valid;

    // 내부 변수 (FIFO 시뮬레이션용)
    reg [11:0] sim_fifo_mem [0:2047]; // 가상의 FIFO 메모리
    reg [10:0] rd_ptr; // 읽기 포인터
    
    // DUT (Device Under Test) 인스턴스
    Downscaling uut (
        .clk(clk), 
        .rst(rst), 
        .fifo_dout(fifo_dout), 
        .fifo_empty(fifo_empty), 
        .fifo_rd_en(fifo_rd_en), 
        .scaled_data(scaled_data), 
        .scaled_valid(scaled_valid)
    );

    // 1. 클럭 생성 (25MHz -> 40ns 주기)
    always #20 clk = ~clk;

    // 2. Standard FIFO 동작 모델링 (핵심!)
    // rd_en이 1인 "다음 클럭"에 데이터가 업데이트되어야 함
    always @(posedge clk) begin
        if (rst) begin
            fifo_dout <= 0;
            rd_ptr <= 0;
        end
        else if (!fifo_empty && fifo_rd_en) begin
            // 요청이 들어오면, 포인터를 증가시키고 데이터를 내보냄
            // (Standard FIFO는 Latency 1이므로 Non-blocking 할당 <= 사용하면 딱 맞음)
            fifo_dout <= sim_fifo_mem[rd_ptr]; 
            rd_ptr <= rd_ptr + 1;
        end
    end

    // 3. 테스트 시나리오
    integer i;
    initial begin
        // 초기화
        clk = 0;
        rst = 1;
        fifo_empty = 1;
        fifo_dout = 0; // 초기값 (쓰레기값 대신 0으로 둠)
        rd_ptr = 0;

        // 가상의 FIFO에 데이터 채우기 (0 ~ 639...)
        // 값 자체가 x좌표라고 생각하면 편함.
        for (i = 0; i < 2048; i = i + 1) begin
            sim_fifo_mem[i] = i; 
        end

        $display("=== Simulation Start ===");
        
// 리셋 해제
        #100;
        rst = 0;
        #40;

        // 시나리오 시작: FIFO가 찼다고 알림
        $display("Step 1: FIFO Not Empty (Data Stream Start)");
        fifo_empty = 0; 
        
        // Standard FIFO 특성상 첫 데이터는 rd_en 전에 미리 나와있지 않음 (Valid한 데이터는 아님)
        // 하지만 편의상 0번지에 있는 값을 미리 띄워놓기도 함.
        // 여기서는 rd_en에 반응하도록 둠.

        // 640 픽셀 (1줄) + 알파 만큼 돌려봄
        repeat (700) @(posedge clk);

        // FIFO 비우기 (테스트 종료)
        fifo_empty = 1;
        #100;
        
        $display("=== Simulation End ===");
        $finish;
    end

    // 4. 결과 모니터링 (콘솔 출력)
    always @(posedge clk) begin
        if (scaled_valid) begin
            $display("Time: %t | Saved Data: %d (Expected Even)", $time, scaled_data);
            
            // 검증 로직
            if (scaled_data % 2 != 0) 
                $display("ERROR: 홀수 데이터(%d)가 저장되었습니다! 로직 반대!", scaled_data);
            else 
                $display("PASS: 짝수 데이터(%d) 저장됨.", scaled_data);
        end
    end

endmodule
