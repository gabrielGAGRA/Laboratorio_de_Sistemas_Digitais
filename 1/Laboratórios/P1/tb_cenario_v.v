`timescale 1ms/1us

module tb_cenario_v;
    reg clock, reset, jogar;
    reg [1:0] configuracao;
    reg [3:0] botoes;
    wire [2:0] leds_rgb;
    wire ganhou, perdeu, pronto, timeout;
    wire [3:0] leds;
    
     // Debug signals
    wire db_igual, db_clock, db_iniciar, db_enderecoIgualLimite, db_timeout, db_modo, db_configuracao, db_escrita;
    wire [6:0] db_contagem, db_memoria, db_estado, db_jogadafeita, db_limite_rodada;

    jogo_desafio_memoria dut (
        .clock(clock), .reset(reset), .jogar(jogar), .configuracao(configuracao), .botoes(botoes),
        .leds_rgb(leds_rgb), .ganhou(ganhou), .perdeu(perdeu), .pronto(pronto), .timeout(timeout), .leds(leds),
        .db_igual(db_igual), .db_contagem(db_contagem), .db_memoria(db_memoria), .db_estado(db_estado),
        .db_jogadafeita(db_jogadafeita), .db_clock(db_clock), .db_iniciar(db_iniciar), .db_enderecoIgualLimite(db_enderecoIgualLimite),
        .db_timeout(db_timeout), .db_modo(db_modo), .db_configuracao(db_configuracao), .db_escrita(db_escrita), .db_limite_rodada(db_limite_rodada)
    );

    always #0.5 clock = ~clock;

    // Tasks for gameplay
    reg [3:0] sequencia [0:15];
    integer k;

    task wait_leds;
        input integer num_leds;
        integer i;
        begin
            for (i = 0; i < num_leds; i = i + 1) begin
                wait(dut.unidade_controle.Eatual == 5'b00011);
                wait(dut.unidade_controle.Eatual == 5'b00101);
            end
            wait(dut.unidade_controle.Eatual == 5'b00111);
            #100;
        end
    endtask

    task press_button;
        input [3:0] btn;
        begin
            botoes = btn; #100; botoes = 0; #100;
        end
    endtask

    initial begin
        sequencia[0] = 4'b0001; sequencia[1] = 4'b0010;
        clock = 0; reset = 0; jogar = 0; botoes = 0;
        #10 reset = 1; #40 reset = 0; #40;

        // ------------ Cenário v: Modo de operação "10" (Jogo normal com timeout) ------------
        $display(">>> CENARIO v: Modo 10 (Normal + Timeout)");
        configuracao = 2'b10;
        jogar = 1; 
        #2; 
        jogar = 0;

        // Testar funcionamento do timeout
        wait_leds(1);
        
        $display("Esperando timeout...");
        // Use a loop similar to tb_cenario_ii to catch timeout reliably
        // Timeout in mode 10 depends on counters. M=5000, Period=1ms -> 5s.
        // Wait long enough (e.g., 6s = 6000ms)
        // With #1.0 steps, we need 6000 iterations.
        
        {timeout_detected, lost} = 0;
        for (i = 0; i < 7000; i = i + 1) begin
             #1.0;
             if (timeout || dut.unidade_controle.Eatual == 5'b01111) begin
                 timeout_detected = 1;
                 i = 7000; // break
             end
             if (perdeu) begin
                 lost = 1;
                 i = 7000;
             end
        end
        
        if (timeout_detected || lost) $display(">>> Timeout verificado no modo 10.");
        else $display(">>> FALHA: Timeout nao ocorreu no modo 10.");

        $stop;
    end
    
    integer i;
    reg timeout_detected, lost;
endmodule
