`timescale 1ms/1us

module tb_cenario_vii;
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

    initial begin
        clock = 0; reset = 0; jogar = 0; botoes = 0;
        #10 reset = 1; #40 reset = 0; #40;

        // ------------ Cenário vii: Tentar mudar configuração no meio do jogo ------------
        $display(">>> CENARIO vii: Mudanca de config durante o jogo");
        
        // Config Inicial: 01 (Demo)
        configuracao = 2'b01;
        jogar = 1; 
        #2; 
        jogar = 0;
        
        wait_leds(1);
        
        // Tenta mudar para Normal (00) durante a espera da jogada
        $display("Mudando config de %b para 01...", configuracao);
        configuracao = 2'b00; 
        #100;
        
        // Verifica se o sinal interno mudou (db_modo reflete s_modo registrado)
        if (db_modo == 1'b1) 
            $display(">>> SUCESSO: O modo interno manteve-se 1 (Demo), ignorando a troca externa.");
        else
            $display(">>> FALHA: O modo interno mudou indevidamente!");

        $stop;
    end
endmodule
