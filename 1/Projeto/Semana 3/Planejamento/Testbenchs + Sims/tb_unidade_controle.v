`timescale 1ns/1ns

module tb_unidade_controle;

    reg clock;
    reg reset;
    reg mudou_modo;
    reg tem_nota_ativa;
    reg acerto_nota;
    reg fim_musica;

    wire modo_aprendizado;
    wire zera_endereco;
    wire conta_endereco;
    wire [4:0] estado_hex;

    unidade_controle dut (
        .clock(clock),
        .reset(reset),
        .mudou_modo(mudou_modo),
        .tem_nota_ativa(tem_nota_ativa),
        .acerto_nota(acerto_nota),
        .fim_musica(fim_musica),
        .modo_aprendizado(modo_aprendizado),
        .zera_endereco(zera_endereco),
        .conta_endereco(conta_endereco),
        .estado_hex(estado_hex)
    );

    always #10 clock = ~clock;

    initial begin
        $display("Iniciando Testbench da Unidade de Controle...");
        $dumpfile("tb_unidade_controle.vcd");
        $dumpvars(0, tb_unidade_controle);

        // Inicializacao
        clock = 0;
        reset = 1;
        mudou_modo = 0;
        tem_nota_ativa = 0;
        acerto_nota = 0;
        fim_musica = 0;

        #25 reset = 0;
        
        // Verifica transicao para LIVRE
        #20;
        $display("Estado atual (Livre esperado): %h", dut.state);

        // Transicao para INICIA_MUSICA -> ESPERA_NOTA
        mudou_modo = 1; #20 mudou_modo = 0;
        #20;
        $display("Estado atual (Espera Nota esperado): %h", dut.state);

        // Simula o usuario errando uma nota
        tem_nota_ativa = 1; 
        acerto_nota = 0;
        #20;
        $display("Estado atual (Compara Nota - Erro esperado): %h", dut.state);
        
        // Simula o usuario acertando a nota
        acerto_nota = 1;
        #20;
        $display("Estado atual (Proximo esperado): %h", dut.state);

        // Volta para Espera Soltar
        #20;
        $display("Estado atual (Espera Soltar esperado): %h", dut.state);

        // O usuario solta a nota
        tem_nota_ativa = 0;
        acerto_nota = 0;
        #20;
        $display("Estado atual (Espera Nota esperado): %h", dut.state);

        // Fim do teste
        #50;
        $display("Teste Finalizado.");
        $finish;
    end

endmodule
