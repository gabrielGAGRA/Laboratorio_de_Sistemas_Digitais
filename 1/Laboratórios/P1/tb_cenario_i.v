`timescale 1ms/1us

module tb_cenario_i;

    // =========================================================================
    // Sinais
    // =========================================================================
    reg clock;
    reg reset;
    reg jogar;
    reg [1:0] configuracao;
    reg [3:0] botoes;

    wire [2:0] leds_rgb;
    wire ganhou;
    wire perdeu;
    wire pronto;
    wire timeout;
    wire [3:0] leds;

    // Sinais de depuração
    wire db_igual;
    wire [6:0] db_contagem;
    wire [6:0] db_memoria;
    wire [6:0] db_estado;
    wire [6:0] db_jogadafeita;
    wire db_clock;
    wire db_iniciar;
    wire db_enderecoIgualLimite;
    wire db_timeout;
    wire db_modo;
    wire db_configuracao;
    wire db_escrita;
    wire [6:0] db_limite_rodada;

    // Instanciação
    jogo_desafio_memoria dut (
        .clock(clock),
        .reset(reset),
        .jogar(jogar),
        .configuracao(configuracao),
        .botoes(botoes),
        .leds_rgb(leds_rgb),
        .ganhou(ganhou),
        .perdeu(perdeu),
        .pronto(pronto),
        .timeout(timeout),
        .leds(leds),
        .db_igual(db_igual),
        .db_contagem(db_contagem),
        .db_memoria(db_memoria),
        .db_estado(db_estado),
        .db_jogadafeita(db_jogadafeita),
        .db_clock(db_clock),
        .db_iniciar(db_iniciar),
        .db_enderecoIgualLimite(db_enderecoIgualLimite),
        .db_timeout(db_timeout),
        .db_modo(db_modo),
        .db_configuracao(db_configuracao),
        .db_escrita(db_escrita),
        .db_limite_rodada(db_limite_rodada)
    );

    // Clock (1kHz: Período 1ms)
    always #0.5 clock = ~clock;

    // Tasks
    task wait_leds;
        input integer num_leds;
        integer i;
        begin
            for (i = 0; i < num_leds; i = i + 1) begin
                wait(dut.unidade_controle.Eatual == 5'b00011); // mostra_led
                wait(dut.unidade_controle.Eatual == 5'b00101); // mostra_apagado
            end
            wait(dut.unidade_controle.Eatual == 5'b00111); // espera
            #0.1;
        end
    endtask

    task press_button;
        input [3:0] btn;
        begin
            botoes = btn;
            #100; // 100ms
            botoes = 4'b0000;
            #100; // 100ms
        end
    endtask

    reg [3:0] sequencia [0:15];
    integer k;

    task play_round;
        input integer n_rod;
        input integer is_last;
        integer j;
        begin
            $display("[%0t] --- Rodada %0d ---", $time, n_rod+1);
            wait_leds(n_rod + 1);
            for (j = 0; j <= n_rod; j = j + 1) begin
                press_button(sequencia[j]);
            end
            if (!is_last) begin
                wait(dut.unidade_controle.Eatual == 5'b01101 || dut.perdeu); // adiciona_jogada
                if (dut.perdeu) begin
                    $display("ERRO: Perdeu na rodada %0d", n_rod+1);
                    $stop;
                end
                press_button(sequencia[n_rod+1]);
            end
        end
    endtask

    initial begin
        // Sequencia fixa baseada no ram_init.txt
        sequencia[0] = 4'b0001; sequencia[1] = 4'b0010; sequencia[2] = 4'b0100; sequencia[3] = 4'b1000;
        sequencia[4] = 4'b0001; sequencia[5] = 4'b0010; sequencia[6] = 4'b0100; sequencia[7] = 4'b1000;
        sequencia[8] = 4'b0001; sequencia[9] = 4'b0010; sequencia[10] = 4'b0100; sequencia[11] = 4'b1000;
        sequencia[12] = 4'b0001; sequencia[13] = 4'b0010; sequencia[14] = 4'b0100; sequencia[15] = 4'b1000;

        clock = 0; reset = 0; jogar = 0; botoes = 0; configuracao = 0;

        // Reset inicial
        #0.01 reset = 1; #0.04 reset = 0; #0.04;

        // ------------ Jogo 1: Modo 01 (Demo, sem timeout), Vitória ------------
        $display(">>> JOGO 1: Modo 01 (Demo, No Timeout) - Vitoria");
        configuracao = 2'b01; 
        jogar = 1; 
        #1.0; 
        jogar = 0;

        for (k = 0; k < 4; k = k + 1) begin
            play_round(k, (k==3));
        end
        wait(ganhou);
        $display(">>> Jogo 1 finalizado (Vitoria).");
        #2.0;

        // Reset entre jogos
        $display(">>> Reset");
        reset = 1; #0.04 reset = 0; #0.04;

        // ------------ Jogo 2: Modo 11 (Demo, Com Timeout), Derrota por falha ------------
        $display(">>> JOGO 2: Modo 11 (Demo, Timeout) - Derrota por erro de jogada");
        configuracao = 2'b11;
        jogar = 1; 
        #1.0;
        jogar = 0;

        // Joga a primeira rodada ok
        play_round(0, 0); 
        
        // Na segunda rodada, erra
        $display("[%0t] --- Rodada 2 (Erro) ---", $time);
        wait_leds(2);
        press_button(4'b1111); // Erro proposital (esperado sequencia[0]=0001)

        wait(perdeu);
        $display(">>> Jogo 2 finalizado (Derrota detectada).");

        $stop;
    end
endmodule
