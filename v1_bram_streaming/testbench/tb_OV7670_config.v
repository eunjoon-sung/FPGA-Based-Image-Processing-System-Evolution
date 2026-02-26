`timescale 1ns / 1ps

module tb_OV7670_config(
    );
    // 1. 파라미터 및 클럭 생성
    parameter CLK_FREQ = 25_000_000;
    // 25MHz -> 40ns 주기
    parameter CLK_PERIOD = 40; 

    reg clk = 0;
    reg rst = 0;

    // 2. DUT I/O 신호 선언
    // DUT (FSM)의 입력 (reg)
    wire SCCB_interface_ready;
    reg start;
    // DUT (FSM)의 출력 (wire)
    wire [7:0] rom_addr;
    wire done;
    wire [7:0] SCCB_interface_addr;
    wire [7:0] SCCB_interface_data;
    wire SCCB_interface_start;
    // ROM의 출력 (wire)
    wire [15:0] rom_data;
    
    wire SIOC_oe; // <--- SCCB 모듈 출력을 받기 위해 추가
    wire SIOD_oe; // <--- SCCB 모듈 출력을 받기 위해 추가

    // 클럭 생성기
    always #(CLK_PERIOD / 2) clk = ~clk;

    // 3. 모듈 인스턴스화 (DUT + ROM)

    // DUT (Device Under Test) - 우리가 만든 FSM
    OV7670_config #(
        .CLK_FREQ(CLK_FREQ)
    ) uut (
        .clk(clk),
        .rst(rst),
        .SCCB_interface_ready(SCCB_interface_ready),
        .rom_data(rom_data), // <--- ROM에서 받음
        .start(start),
        .rom_addr(rom_addr), // ---> ROM으로 보냄
        .done(done),
        .SCCB_interface_addr(SCCB_interface_addr),
        .SCCB_interface_data(SCCB_interface_data),
        .SCCB_interface_start(SCCB_interface_start)
    );

    // 우리가 검증한 2-cycle Latency ROM
    OV7670_config_rom rom (
        .clk(clk),
        .rst(rst),
        .addr(rom_addr), // <--- DUT에서 받음
        .dout(rom_data)  // ---> DUT로 보냄
    );
    
    SCCB_interface SCCB (
        .clk(clk),
        .rst(rst),
        .start(SCCB_interface_start),
        .address(SCCB_interface_addr),
        .data(SCCB_interface_data),
        .ready(SCCB_interface_ready),
        .SIOC_oe(SIOC_oe),
        .SIOD_oe(SIOD_oe)
    );

    // 4. 테스트 시퀀스 (Stimulus)

   // 4. 테스트 시퀀스 (Stimulus)

    // 모니터링: FSM의 핵심 I/O를 관찰
    initial begin
        $monitor("Time: %0t | FSM state: %s | rom_addr: %h | rom_data: %h | SCCB_start: %b | SCCB_ready: %b | done: %b",
                 $time, uut.state, rom_addr, rom_data, SCCB_interface_start, SCCB_interface_ready, done);
    end

    // (가짜 SCCB Stub 로직은 삭제됨)

    // 메인 테스트 시퀀스
    initial begin
        // 1. 초기화
        $display("TB: 시뮬레이션 시작...");
        rst = 1;
        start = 0;
        // SCCB_interface_ready는 SCCB 모듈이 스스로 1로 초기화할 것임
        #(CLK_PERIOD * 10);
        
        rst = 0;
        #(CLK_PERIOD * 10);

        // 2. FSM 시작
        $display("TB: FSM 'start' 펄스 전송.");
        start = 1;
        #(CLK_PERIOD);
        start = 0;

        // 3. FSM이 'done' 신호를 보낼 때까지 대기
        wait (done == 1'b1);
        
        $display("TB: 'done' 신호 감지!");
        #(CLK_PERIOD * 10);

        // 4. 시뮬레이션 종료
        $display("TB: 시뮬레이션 종료.");
        $finish;
    end

endmodule
