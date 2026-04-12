`timescale 1ns/1ns

module tb_logica_notas_prioridade;

    reg clock;
    reg reset;
    reg [6:0] botoes;

    wire [2:0] nota_id;
    wire tem_nota;

    logica_notas_prioridade dut (
        .clock(clock),
        .reset(reset),
        .botoes(botoes),
        .nota_id(nota_id),
        .tem_nota(tem_nota)
    );

    // Clock
    always #10 clock = ~clock;

    initial begin
        $display("Iniciando Testbench da Logica de Prioridade de Notas...");
        $dumpfile("tb_logica_notas_prioridade.vcd");
        $dumpvars(0, tb_logica_notas_prioridade);

        // Inicializacao
        clock = 0;
        reset = 1;
        botoes = 7'b0000000;

        #25 reset = 0;

        // Toca Do (botao 0)
        #20 botoes = 7'b0000001; 
        #20 $display("Tem nota (1 exp): %b, Nota ID (1 exp): %d", tem_nota, nota_id);

        // Sem soltar o Do, toca Mi (botao 2) -> Override de prioridade por evento
        #20 botoes = 7'b0000101;
        #20 $display("Tem nota (1 exp): %b, Nota ID (3 exp): %d", tem_nota, nota_id);

        // Sem soltar, toca Re (botao 1) -> Novo override
        #20 botoes = 7'b0000111;
        #20 $display("Tem nota (1 exp): %b, Nota ID (2 exp): %d", tem_nota, nota_id);

        // Solta o Re (botao 1), devem sobrar Do e Mi. O Fallback deve assumir a maior nota ativa (Mi = 3)
        #20 botoes = 7'b0000101;
        #20 $display("Tem nota (1 exp): %b, Nota ID (3 exp): %d", tem_nota, nota_id);

        // Solta tudo
        #20 botoes = 7'b0000000;
        #20 $display("Tem nota (0 exp): %b, Nota ID (qualquer exp): %d", tem_nota, nota_id);

        // Fim do teste
        #50;
        $display("Teste Finalizado.");
        $finish;
    end

endmodule
