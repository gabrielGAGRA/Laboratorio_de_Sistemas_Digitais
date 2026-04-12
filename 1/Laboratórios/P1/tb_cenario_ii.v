`timescale 1ms/10us

module tb_cenario_ii;

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
    
    integer wait_counter;

    initial begin
        clock = 0; reset = 0; jogar = 0; botoes = 0; configuracao = 0;
        #0.01 reset = 1; #0.04 reset = 0; #0.04;

        // ------------ Cenário ii: Derrota por timeout no modo 11 (Demo, Timeout Hab) ------------
        $display(">>> CENARIO ii: Derrota por Timeout (Modo 11)");
        configuracao = 2'b11;
        jogar = 1; 
        #1.0; 
        jogar = 0;

        wait_leds(1);

        $display("Esperando timeout");
        // Wait loop: espera ate 6 segundos (6000 * 1ms) para garantir
        wait_counter = 0;
        while (!(timeout || dut.unidade_controle.Eatual == 5'b01111) && wait_counter < 6000) begin
            #1.0;
            wait_counter = wait_counter + 1;
        end
        
        if (perdeu || timeout) $display(">>> Timeout detectado com sucesso!");
        else $display(">>> FALHA: Nao detectou timeout.");

        $stop;
    end
endmodule
