//------------------------------------------------------------------
// Arquivo   : circuito_exp4_tb.v
// Projeto   : Experiencia 5 - Jogo do Genius
//------------------------------------------------------------------
// Descricao : Testbench para circuito_exp4
//             Testa: modo normal (16 jogadas), modo demo (4 jogadas),
//             timeout, sequencia correta e sequencia errada
//------------------------------------------------------------------

`timescale 1ns/1ns

module circuito_exp4_tb;

    // Sinais de entrada
    reg clock;
    reg reset;
    reg iniciar;
    reg [3:0] chaves;
    reg modo;

    // Sinais de saída
    wire acertou;
    wire errou;
    wire pronto;
    wire [3:0] leds;
    wire db_igual;
    wire [6:0] db_contagem;
    wire [6:0] db_memoria;
    wire [6:0] db_estado;
    wire [6:0] db_jogadafeita;
    wire db_clock;
    wire db_iniciar;
    wire db_zerac;
    wire db_contac;
    wire db_fimc;
    wire db_zerar;
    wire db_registrar;
    wire db_timeout;
    wire db_tem_jogada;
    wire db_enable_timeout;
    wire db_zera_s_timeout;
    wire db_modo;

    // Parâmetros de tempo
    parameter CLOCK_PERIOD = 1000000; // 1kHz -> 1ms = 1.000.000

    // Instância do DUT
    circuito_exp4 dut (
        .clock(clock),
        .reset(reset),
        .iniciar(iniciar),
        .chaves(chaves),
        .modo(modo),
        .acertou(acertou),
        .errou(errou),
        .pronto(pronto),
        .leds(leds),
        .db_igual(db_igual),
        .db_contagem(db_contagem),
        .db_memoria(db_memoria),
        .db_estado(db_estado),
        .db_jogadafeita(db_jogadafeita),
        .db_clock(db_clock),
        .db_iniciar(db_iniciar),
        .db_zerac(db_zerac),
        .db_contac(db_contac),
        .db_fimc(db_fimc),
        .db_zerar(db_zerar),
        .db_registrar(db_registrar),
        .db_timeout(db_timeout),
        .db_tem_jogada(db_tem_jogada),
        .db_enable_timeout(db_enable_timeout),
        .db_zera_s_timeout(db_zera_s_timeout),
        .db_modo(db_modo)
    );

    // Gerador de clock
    always #(CLOCK_PERIOD/2) clock = ~clock;

    // Task para pressionar uma chave
    task pressiona_chave;
        input [3:0] valor;
        begin
            @(negedge clock);
            chaves = valor;
            #(CLOCK_PERIOD*10);  // Mantém pressionado por 10 ciclos
            chaves = 4'b0000;
            #(CLOCK_PERIOD*20); // Espera entre jogadas
        end
    endtask

    // Task para iniciar o jogo
    task inicia_jogo;
        input modo_jogo;
        begin
            @(negedge clock);
            modo = modo_jogo;
            iniciar = 1'b1;
            #(CLOCK_PERIOD*5);
            iniciar = 1'b0;
            #(CLOCK_PERIOD*10);
        end
    endtask

    // Task para jogar sequência correta (usa leds como referência da ROM)
    task joga_sequencia_correta_auto;
        input integer num_jogadas;
        integer i;
        begin
            for (i = 0; i < num_jogadas; i = i + 1) begin
                // Espera estabilizar e lê o valor esperado dos LEDs
                #(CLOCK_PERIOD*5);
                $display("[%0t] Jogada %0d: Pressionando %b (leds=%b)", $time, i, leds, leds);
                pressiona_chave(leds);
            end
        end
    endtask

    // Task para jogar sequência errada
    task joga_sequencia_errada_auto;
        input integer jogada_errada;
        integer i;
        begin
            for (i = 0; i < jogada_errada; i = i + 1) begin
                #(CLOCK_PERIOD*5);
                $display("[%0t] Jogada %0d: Pressionando %b (correta)", $time, i, leds);
                pressiona_chave(leds);
            end
            // Jogada errada - pressiona valor diferente do esperado
            #(CLOCK_PERIOD*5);
            $display("[%0t] Jogada %0d: Pressionando %b (ERRADA! esperado=%b)", $time, jogada_errada, ~leds, leds);
            pressiona_chave(~leds);  // Inverte para garantir erro
        end
    endtask

    // Teste principal
    initial begin
        $display("=========================================");
        $display("   TESTBENCH - CIRCUITO EXP4 (GENIUS)   ");
        $display("=========================================");

        // Inicialização
        clock = 1'b0;
        reset = 1'b0;
        iniciar = 1'b0;
        chaves = 4'b0000;
        modo = 1'b0;

        // Reset inicial
        #(CLOCK_PERIOD*2);
        reset = 1'b1;
        #(CLOCK_PERIOD*5);
        reset = 1'b0;
        #(CLOCK_PERIOD*10);

        //--------------------------------------------------
        // TESTE 1: Modo Demo (4 jogadas) - Sequência Correta
        //--------------------------------------------------
        $display("\n=========================================");
        $display("TESTE 1: Modo Demo (4 jogadas) - Acerto");
        $display("=========================================");
        
        inicia_jogo(1'b1); // modo = 1 (demo, 4 jogadas)
        
        $display("[%0t] Modo registrado: %b", $time, db_modo);
        
        joga_sequencia_correta_auto(4);
        
        #(CLOCK_PERIOD*30);
        
        if (acertou && pronto) begin
            $display("[%0t] TESTE 1 PASSOU: Acertou = %b, Pronto = %b", $time, acertou, pronto);
        end else begin
            $display("[%0t] TESTE 1 FALHOU: Acertou = %b, Pronto = %b, Errou = %b", $time, acertou, pronto, errou);
        end

        // Reset para próximo teste
        reset = 1'b1;
        #(CLOCK_PERIOD*5);
        reset = 1'b0;
        #(CLOCK_PERIOD*10);

        //--------------------------------------------------
        // TESTE 2: Modo Normal (16 jogadas) - Sequência Correta
        //--------------------------------------------------
        $display("\n=========================================");
        $display("TESTE 2: Modo Normal (16 jogadas) - Acerto");
        $display("=========================================");
        
        inicia_jogo(1'b0); // modo = 0 (normal, 16 jogadas)
        
        $display("[%0t] Modo registrado: %b", $time, db_modo);
        
        joga_sequencia_correta_auto(16);
        
        #(CLOCK_PERIOD*30);
        
        if (acertou && pronto) begin
            $display("[%0t] TESTE 2 PASSOU: Acertou = %b, Pronto = %b", $time, acertou, pronto);
        end else begin
            $display("[%0t] TESTE 2 FALHOU: Acertou = %b, Pronto = %b, Errou = %b", $time, acertou, pronto, errou);
        end

        // Reset para próximo teste
        reset = 1'b1;
        #(CLOCK_PERIOD*5);
        reset = 1'b0;
        #(CLOCK_PERIOD*10);

        //--------------------------------------------------
        // TESTE 3: Modo Demo - Sequência Errada
        //--------------------------------------------------
        $display("\n=========================================");
        $display("TESTE 3: Modo Demo - Erro na jogada 2");
        $display("=========================================");
        
        inicia_jogo(1'b1); // modo = 1 (demo)
        
        joga_sequencia_errada_auto(2); // Erra na terceira jogada (índice 2)
        
        #(CLOCK_PERIOD*30);
        
        if (errou && pronto) begin
            $display("[%0t] TESTE 3 PASSOU: Errou = %b, Pronto = %b", $time, errou, pronto);
        end else begin
            $display("[%0t] TESTE 3 FALHOU: Errou = %b, Pronto = %b, Acertou = %b", $time, errou, pronto, acertou);
        end

        // Reset para próximo teste
        reset = 1'b1;
        #(CLOCK_PERIOD*5);
        reset = 1'b0;
        #(CLOCK_PERIOD*10);

        //--------------------------------------------------
        // TESTE 4: Timeout
        //--------------------------------------------------
        $display("\n=========================================");
        $display("TESTE 4: Timeout (sem jogada)");
        $display("=========================================");
        
        inicia_jogo(1'b1); // modo = 1 (demo)
        
        $display("[%0t] Aguardando timeout (3000+ ciclos)...", $time);
        
        // Aguarda timeout (3000 ciclos de clock + margem)
        #(CLOCK_PERIOD * 3200);
        
        if (db_timeout && pronto) begin
            $display("[%0t] TESTE 4 PASSOU: Timeout = %b, Pronto = %b", $time, db_timeout, pronto);
        end else begin
            $display("[%0t] TESTE 4 FALHOU: Timeout = %b, Pronto = %b", $time, db_timeout, pronto);
        end

        // Reset para próximo teste
        reset = 1'b1;
        #(CLOCK_PERIOD*5);
        reset = 1'b0;
        #(CLOCK_PERIOD*10);

        //--------------------------------------------------
        // TESTE 5: Reinício após acerto
        //--------------------------------------------------
        $display("\n=========================================");
        $display("TESTE 5: Reinicio apos acerto");
        $display("=========================================");
        
        inicia_jogo(1'b1); // modo = 1 (demo)
        joga_sequencia_correta_auto(4);
        #(CLOCK_PERIOD*30);
        
        $display("[%0t] Primeiro jogo concluido. Reiniciando...", $time);
        
        // Reinicia o jogo
        inicia_jogo(1'b1);
        joga_sequencia_correta_auto(4);
        #(CLOCK_PERIOD*30);
        
        if (acertou && pronto) begin
            $display("[%0t] TESTE 5 PASSOU: Reinicio funcionou!", $time);
        end else begin
            $display("[%0t] TESTE 5 FALHOU: Acertou = %b, Pronto = %b", $time, acertou, pronto);
        end

        //--------------------------------------------------
        // TESTE 6: Mudança de modo entre jogos
        //--------------------------------------------------
        $display("\n=========================================");
        $display("TESTE 6: Mudanca de modo entre jogos");
        $display("=========================================");
        
        // Reset
        reset = 1'b1;
        #(CLOCK_PERIOD*5);
        reset = 1'b0;
        #(CLOCK_PERIOD*10);
        
        // Primeiro jogo: modo demo
        inicia_jogo(1'b1);
        $display("[%0t] Jogo 1 - Modo Demo: db_modo = %b", $time, db_modo);
        joga_sequencia_correta_auto(4);
        #(CLOCK_PERIOD*30);
        
        // Segundo jogo: modo normal (mas só joga 4)
        inicia_jogo(1'b0);
        $display("[%0t] Jogo 2 - Modo Normal: db_modo = %b", $time, db_modo);
        joga_sequencia_correta_auto(4);
        #(CLOCK_PERIOD*30);
        
        // No modo normal, 4 jogadas não devem terminar o jogo
        if (!pronto) begin
            $display("[%0t] TESTE 6 PASSOU: Modo normal requer mais jogadas", $time);
        end else begin
            $display("[%0t] TESTE 6 FALHOU: Jogo terminou com apenas 4 jogadas no modo normal", $time);
        end

        //--------------------------------------------------
        // Fim dos testes
        //--------------------------------------------------
        $display("\n=========================================");
        $display("   FIM DOS TESTES   ");
        $display("=========================================");
        
        #(CLOCK_PERIOD*10);
        $finish;
    end

endmodule