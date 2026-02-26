`timescale 1ns / 1ps

module my_bram (
    input wire clka,
    input wire wea,
    input wire [16:0] addra, // ★ 17비트 명시 (Writer 주소)
    input wire [11:0] dina,
    
    input wire clkb,
    input wire enb,
    input wire [16:0] addrb, // ★ 17비트 명시 (Reader 주소)
    output reg [11:0] doutb
    );

    // 76,800개 깊이의 메모리 배열 선언 (Vivado가 알아서 BRAM으로 합성함)
    (* ram_style = "block" *) 
    reg [11:0] mem [0:76799]; 

    // Port A: 쓰기 (Writer)
    always @(posedge clka) begin
        if (wea) begin
            mem[addra] <= dina;
        end
    end

    // Port B: 읽기 (Reader)
    always @(posedge clkb) begin
        if (enb) begin
            doutb <= mem[addrb];
        end
    end

endmodule
