`timescale 1ns/1ns

module jogo_desafio_memoria_tb;

    // =========================================================================
    // Declaração de Sinais
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
    wire [6:0] db_limite_rodada;

    // =========================================================================
    // Instanciação do DUT (Device Under Test)
    // =========================================================================
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
        .db_limite_rodada(db_limite_rodada)
    );

    // =========================================================================
    // Geração de Clock (1 MHz -> Período de 1000ns)
    // =========================================================================
    always #500 clock = ~clock;

    // =========================================================================
    // Tarefas Auxiliares para Simulação
    // =========================================================================
    
    // Tarefa para aguardar a exibição da sequência de LEDs
    task wait_leds;
        input integer num_leds;
        integer i;
        begin
            for (i = 0; i < num_leds; i = i + 1) begin
                // Aguarda o LED acender (estado mostra_led = 4'b0011)
                wait(dut.unidade_controle.Eatual == 4'b0011);
                // Aguarda o LED apagar (estado mostra_apagado = 4'b0101)
                wait(dut.unidade_controle.Eatual == 4'b0101);
            end
            // Aguarda a máquina ir para o estado de espera (4'b0111)
            wait(dut.unidade_controle.Eatual == 4'b0111);
            #100; // Pequeno atraso para estabilidade
        end
    endtask

    // Tarefa para simular o pressionamento de um botão
    task press_button;
        input [3:0] btn;
        begin
            botoes = btn;
            #200; // Mantém o botão pressionado por 200ns (10 ciclos de clock)
            botoes = 4'b0000;
            #200; // Aguarda 200ns antes da próxima ação
        end
    endtask

    reg [3:0] sequencia_correta [0:15];
    integer k_rodada;

    // Tarefa para jogar uma rodada completa com sucesso
    task play_round_success;
        input integer n_rodada;
        input integer ultima_rodada; 
        integer j;
        begin
            $display("[%0t] --- Rodada %0d ---", $time, n_rodada+1);
            wait_leds(n_rodada + 1);
            for (j = 0; j <= n_rodada; j = j + 1) begin
                press_button(sequencia_correta[j]);
            end
            if (!ultima_rodada) begin
                wait(dut.unidade_controle.Eatual == 4'b1101 || dut.perdeu);
                if (dut.perdeu) begin
                    $display("ERRO: Perdeu inesperadamente na rodada %0d", n_rodada+1);
                    $stop;
                end
                press_button(sequencia_correta[n_rodada+1]);
            end
        end
    endtask

    // =========================================================================
    // Bloco Principal de Teste
    // =========================================================================
    initial begin
        // Inicializa sequencia correta
        sequencia_correta[0]  = 4'b0001; // RAM init
        sequencia_correta[1]  = 4'b0010;
        sequencia_correta[2]  = 4'b0100;
        sequencia_correta[3]  = 4'b1000;
        sequencia_correta[4]  = 4'b0001;
        sequencia_correta[5]  = 4'b0010;
        sequencia_correta[6]  = 4'b0100;
        sequencia_correta[7]  = 4'b1000;
        sequencia_correta[8]  = 4'b0001;
        sequencia_correta[9]  = 4'b0010;
        sequencia_correta[10] = 4'b0100;
        sequencia_correta[11] = 4'b1000;
        sequencia_correta[12] = 4'b0001;
        sequencia_correta[13] = 4'b0010;
        sequencia_correta[14] = 4'b0100;
        sequencia_correta[15] = 4'b1000;

        // Configuração inicial para o ModelSim
        $display("==================================================");
        $display("Iniciando Testbench: Jogo Desafio Memoria");
        $display("==================================================");

        // Inicialização dos sinais
        clock = 0;
        reset = 0;
        jogar = 0;
        configuracao = 2'b00;
        botoes = 4'b0000;

        // Aplica o Reset
        $display("[%0t] Aplicando Reset...", $time);
        #10 reset = 1;
        #40 reset = 0;
        #40;

        // ---------------------------------------------------------------------
        // TESTE 1: Jogo Completo (Modo Demonstração - 4 rodadas) sem timeout
        // ---------------------------------------------------------------------
        $display("\n[%0t] ---> INICIANDO TESTE 1: Vitoria no Modo Demonstracao", $time);
        configuracao = 2'b01; 
        jogar = 1; #40 jogar = 0;

        for (k_rodada = 0; k_rodada < 4; k_rodada = k_rodada + 1) begin
            play_round_success(k_rodada, (k_rodada == 3));
        end

        wait(ganhou == 1 || perdeu == 1);
        if (perdeu) begin
            $display("ERRO: O jogo perdeu na ultima rodada!");
            $stop;
        end
        $display("[%0t] TESTE 1 CONCLUIDO: Vitoria detectada com sucesso!", $time);
        #1000;

        // ---------------------------------------------------------------------
        // TESTE 2: Erro do jogador
        // ---------------------------------------------------------------------
        $display("\n[%0t] ---> INICIANDO TESTE 2: Erro do jogador", $time);
        reset = 1; #40 reset = 0; #40;
        jogar = 1; #40 jogar = 0;

        $display("[%0t] Rodada 1: Aguardando LEDs...", $time);
        wait_leds(1);
        $display("[%0t] Rodada 1: Inserindo jogada ERRADA (1000)...", $time);
        press_button(4'b1000); // Erra de propósito

        wait(perdeu == 1);
        $display("[%0t] TESTE 2 CONCLUIDO: Erro detectado corretamente!", $time);
        #1000;

        // ---------------------------------------------------------------------
        // TESTE 3: Timeout
        // ---------------------------------------------------------------------
        $display("\n[%0t] ---> INICIANDO TESTE 3: Timeout", $time);
        reset = 1; #40 reset = 0; #40;

        configuracao = 2'b11; // Modo demo, timeout hab
        jogar = 1; #40 jogar = 0;

        $display("[%0t] Rodada 1: Aguardando LEDs...", $time);
        wait_leds(1);
        
        $display("[%0t] Rodada 1: Aguardando estourar o tempo (timeout)...", $time);
        wait(dut.timeout == 1 || dut.unidade_controle.Eatual == 4'b1111);
        $display("[%0t] TESTE 3 CONCLUIDO: Timeout detectado corretamente!", $time);
        #1000;

        // ---------------------------------------------------------------------
        // TESTE 4: Vitoria no Modo Completo (16 rodadas)
        // ---------------------------------------------------------------------
        $display("\n[%0t] ---> INICIANDO TESTE 4: Vitoria no Modo Completo (16 rodadas)", $time);
        reset = 1; #40 reset = 0; #40;
        configuracao = 2'b00; // Modo completo, timeout desab
        jogar = 1; #40 jogar = 0;

        for (k_rodada = 0; k_rodada < 16; k_rodada = k_rodada + 1) begin
            play_round_success(k_rodada, (k_rodada == 15));
        end

        wait(ganhou == 1);
        $display("[%0t] TESTE 4 CONCLUIDO: Vitoria em 16 rodadas detectada!", $time);
        #1000;

        // ---------------------------------------------------------------------
        // TESTE 5: Derrota no Modo Completo (16 rodadas)
        // ---------------------------------------------------------------------
        $display("\n[%0t] ---> INICIANDO TESTE 5: Derrota no Modo Completo (Rodada 8)", $time);
        reset = 1; #40 reset = 0; #40;
        jogar = 1; #40 jogar = 0;

        // Joga 7 rodadas com sucesso
        for (k_rodada = 0; k_rodada < 7; k_rodada = k_rodada + 1) begin
            play_round_success(k_rodada, 0);
        end

        // Na rodada 8, erra de propósito
        $display("[%0t] --- Rodada 8 (Tentativa de Erro) ---", $time);
        wait_leds(8);
        press_button(sequencia_correta[0]);
        press_button(sequencia_correta[1]);
        $display("   Inserindo ERRO proposital...");
        press_button(~sequencia_correta[2]); // Inverte os bits para errar

        wait(perdeu == 1);
        $display("[%0t] TESTE 5 CONCLUIDO: Derrota detectada corretamente!", $time);
        #1000;

        // ---------------------------------------------------------------------
        // TESTE 6: Reiniciar Jogo (Verifica limpeza de contadores)
        // ---------------------------------------------------------------------
        $display("\n[%0t] ---> INICIANDO TESTE 6: Reinicio Apos Derrota (Verifica Limpeza)", $time);
        // Nao damos reset aqui de proposito, apenas apertamos jogar para ver se limpa
        jogar = 1; #40 jogar = 0;

        $display("[%0t] Rodada 1 apos reinicio...", $time);
        play_round_success(0, 0); // Joga a primeira rodada com sucesso

        $display("[%0t] TESTE 6 CONCLUIDO: Sistema reiniciado e contadores limpos corretamente.", $time);
        #1000;

        // ---------------------------------------------------------------------
        // TESTE 7: Esperar com Timeout Desligado
        // ---------------------------------------------------------------------
        $display("\n[%0t] ---> INICIANDO TESTE 7: Esperar com Timeout Desligado", $time);
        reset = 1; #40 reset = 0; #40;
        configuracao = 2'b00; // Timeout desabilitado
        jogar = 1; #40 jogar = 0;

        $display("[%0t] Rodada 1: Aguardando LEDs...", $time);
        wait_leds(1);

        $display("[%0t] Rodada 1: Aguardando um longo tempo (simulando inatividade)...", $time);
        #500000; // Espera um tempo longo (maior que o timeout normal)

        $display("[%0t] Rodada 1: Inserindo jogada apos longa espera...", $time);
        press_button(sequencia_correta[0]);
        
        wait(dut.unidade_controle.Eatual == 4'b1101);
        $display("[%0t] TESTE 7 CONCLUIDO: Jogo continuou normalmente apos longa espera!", $time);
        #1000;

        // Fim da simulação
        $display("\n==================================================");
        $display("[%0t] TODOS OS TESTES FORAM CONCLUIDOS COM SUCESSO!", $time);
        $display("==================================================");
        $stop;
    end

endmodule
