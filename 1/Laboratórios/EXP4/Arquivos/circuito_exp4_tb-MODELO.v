`timescale 1ns/1ns

module circuito_exp4_tb;
    reg clock_in = 1;
    reg reset_in = 0;
    reg iniciar_in = 0;
    reg [3:0] chaves_in = 4'b0000;

    // ... (wires de saída idênticos ao seu modelo)

    circuito_exp4 dut ( // Nome corrigido para Exp 4
        .clock(clock_in), .reset(reset_in), .iniciar(iniciar_in), .chaves(chaves_in),
        // ... conexões de saída
    );

    parameter clockPeriod = 1000000; // 1kHz

    initial begin
        // Reset inicial
        reset_in = 1; #(2*clockPeriod); reset_in = 0;
        
        // Teste: Iniciar jogo
        iniciar_in = 1; #(2*clockPeriod); iniciar_in = 0;

        // Jogada 1 (Certa) - Assume ROM[0] = 4'b0001
        chaves_in = 4'b0001; #(5*clockPeriod); chaves_in = 4'b0000;
        #(10*clockPeriod);

        // Jogada 2 (Certa) - Assume ROM[1] = 4'b0010
        chaves_in = 4'b0010; #(5*clockPeriod); chaves_in = 4'b0000;
        #(10*clockPeriod);

        // Jogada 3 (Certa) - Assume ROM[2] = 4'b0100
        chaves_in = 4'b0100; #(5*clockPeriod); chaves_in = 4'b0000;
        #(10*clockPeriod);

        // Jogada 4 (ERRADA) - Usuário errou!
        chaves_in = 4'b0111; #(5*clockPeriod); chaves_in = 4'b0000;
        
        // Aqui errou_out deve ir para 1 e pronto_out para 1
        #(20*clockPeriod);
        $stop;
    end
endmodule