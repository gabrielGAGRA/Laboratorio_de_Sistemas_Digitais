`timescale 1ms/10us

module tb_cenario_viii;
    reg clock, reset, jogar;
    reg [1:0] configuracao;
    reg [3:0] botoes;
    wire [2:0] leds_rgb;
    wire ganhou, perdeu, pronto, timeout;
    wire [3:0] leds;
    
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

    task press_button;
        input [3:0] btn;
        begin
            botoes = btn;
            #100;
            botoes = 4'b0000;
            #100;
        end
    endtask

    reg [3:0] sequencia [0:15];
    integer i;
    reg timeout_detected, lost;
    integer wait_counter;

    initial begin
        sequencia[0] = 4'b0001; 
        sequencia[1] = 4'b0010;
        sequencia[2] = 4'b0100;
        sequencia[3] = 4'b1000;

        clock = 0; reset = 0; jogar = 0; botoes = 0; configuracao = 0;
        #1.0 reset = 1; #4.0 reset = 0; #4.0;

        $display(">>> CENARIO viii: Modo 10 (Normal + Timeout na ultima jogada da quarta rodada)");
        configuracao = 2'b10;
        jogar = 1; 
        #2.0; 
        jogar = 0;

        wait_leds(1);
        press_button(sequencia[0]);
        wait(dut.unidade_controle.Eatual == 5'b01101); 
        #1;
        press_button(sequencia[1]);

        wait_leds(2);
        press_button(sequencia[0]);
        press_button(sequencia[1]);
        
        wait(dut.unidade_controle.Eatual == 5'b01101); 
        #1;
        press_button(sequencia[2]);

        wait_leds(3);
        press_button(sequencia[0]);
        press_button(sequencia[1]);
        press_button(sequencia[2]);
        
        wait(dut.unidade_controle.Eatual == 5'b01101); 
        #1;
        press_button(sequencia[3]);

        wait_leds(4);
        press_button(sequencia[0]);
        press_button(sequencia[1]);
        press_button(sequencia[2]);
        
        
        timeout_detected = 0;
        lost = 0;
        wait_counter = 0;
        
        while (!(timeout || dut.unidade_controle.Eatual == 5'b01111) && wait_counter < 6000) begin
            #1.0;
            if (perdeu) begin
                lost = 1;
            end
            if (timeout) begin
                timeout_detected = 1;
            end
            wait_counter = wait_counter + 1;
        end
        
        if (timeout_detected || lost) $display(">>> Timeout verificado com sucesso na ultima jogada da 4a rodada");
        else $display(">>> FALHA");

        $stop;
    end
endmodule
