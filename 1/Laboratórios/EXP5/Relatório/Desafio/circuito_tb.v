`timescale 1ns/1ns

module circuito_tb;

    // Sinais de entrada
    reg clock;
    reg reset;
    reg iniciar;
    reg [3:0] chaves;
    reg modo;

    // Sinais de saída
    wire acertou;    // Ganhou o jogo todo
    wire errou;
    wire pronto;
    wire [3:0] leds;
    wire timeout;
    
    // Debug signals
    wire db_igual;
    wire [6:0] db_contagem;
    wire [6:0] db_memoria;
    wire [6:0] db_estado;
    wire [6:0] db_limite_view;
    wire db_enderecoIgualLimite;
    wire db_timeout;
    wire db_modo;

    // Parâmetros de tempo
    parameter CLOCK_PERIOD = 1000000; // 1 kHz -> 1.000.000ns

    // Instância do DUT
    circuito_jogo_sequencias dut (
        .clock(clock),
        .reset(reset),
        .jogar(iniciar),       
        .botoes(chaves),       
        .modo(modo),
        .ganhou(acertou),      
        .perdeu(errou),        
        .pronto(pronto),
        .leds(leds),
        .timeout(timeout),
        .db_igual(db_igual),
        .db_contagem(db_contagem),
        .db_memoria(db_memoria),
        .db_estado(db_estado),
        .db_limite_view(db_limite_view),
        .db_enderecoIgualLimite(db_enderecoIgualLimite),
        .db_timeout(db_timeout),
        .db_modo(db_modo)
    );

    // Gerador de clock
    always #(CLOCK_PERIOD/2) clock = ~clock;

    // TAREFAS AUXILIARES
    // Task para resetar o sistema
    task reset_sistema;
        begin
            @(negedge clock);
            reset = 1'b1;
            iniciar = 1'b0;
            chaves = 4'b0000;
            #(CLOCK_PERIOD*5);
            reset = 1'b0;
            #(CLOCK_PERIOD*5);
        end
    endtask

    // Task para pressionar uma chave
    task pressiona_chave;
        input [3:0] valor;
        begin
            @(negedge clock);
            #(CLOCK_PERIOD*5); 
            chaves = valor;
            #(CLOCK_PERIOD*10);  // Mantém pressionado
            chaves = 4'b0000;    // Solta
            #(CLOCK_PERIOD*20);  // Intervalo entre jogadas
        end
    endtask

    // Task para iniciar o jogo escolhendo o modo
    task iniciar_novo_jogo;
        input modo_jogo;
        begin
            @(negedge clock);
            modo = modo_jogo;
            iniciar = 1'b1; // Pulso em jogar
            #(CLOCK_PERIOD*5);
            iniciar = 1'b0;
            #(CLOCK_PERIOD*10); // Tempo para entrar em preparacao/espera
        end
    endtask

    reg [3:0] gabarito [0:15];
    initial begin
        // Preenche com a sequencia esperada da ROM 
        gabarito[0] = 4'b0001; gabarito[1] = 4'b0010; gabarito[2] = 4'b0100; gabarito[3] = 4'b1000;
        gabarito[4] = 4'b0001; gabarito[5] = 4'b0010; gabarito[6] = 4'b0100; gabarito[7] = 4'b1000;
        gabarito[8] = 4'b0001; gabarito[9] = 4'b0010; gabarito[10]= 4'b0100; gabarito[11]= 4'b1000;
        gabarito[12]= 4'b0001; gabarito[13]= 4'b0010; gabarito[14]= 4'b0100; gabarito[15]= 4'b1000;
    end

    // Task para jogar um "Nivel" completo (ex: Nivel 3 joga seq[0], seq[1], seq[2])
    task jogar_nivel_k;
        input integer k; // Qual nivel estamos (limite atual = k-1)
        integer i;
        begin
            $display("    ... Jogando nivel %0d (sequencia de %0d itens) ...", k+1, k+1);
            for (i = 0; i <= k; i = i + 1) begin
                                
                // Verifica se nao perdemos antes da hora
                if (errou) begin
                    $display("    [FALHA] Perdeu prematuramente no indice %0d do nivel %0d", i, k);
                    i = k + 1; // break
                end else begin
                    pressiona_chave(gabarito[i]);
                end
            end
        end
    endtask

    // TESTES
    initial begin
        $display("==================================================");
        $display("   TESTBENCH - GENIUS PROGRESSIVO (DESAFIO 2)     ");
        $display("==================================================");

        clock = 0;
        reset_sistema();

        // CENARIO 1: Jogo Completo em Modo Demo (4 rodadas progressivas)
        $display("\nTESTE 1: MODO DEMO (4 Rodadas Progressivas)");
        $display("-------------------------------------------");
        
        iniciar_novo_jogo(1'b1); // Modo 1 = Demo

        // Loop para vencer os 4 niveis (0 a 3)
        // Rodada 0: joga gabarito[0]
        // Rodada 1: joga gabarito[0], gabarito[1]
        begin : jogo_demo
            integer nivel;
            for (nivel = 0; nivel < 4; nivel = nivel + 1) begin
                #(CLOCK_PERIOD*10); 
                jogar_nivel_k(nivel);
                
                #(CLOCK_PERIOD*5);
                if (errou) begin 
                    $display("[FALHA] Errou durante o nivel %0d", nivel); 
                    disable jogo_demo; 
                end
            end
        end

        #(CLOCK_PERIOD*20);
        if (acertou && pronto) 
            $display(">>> SUCESSO: Ganhou o jogo no Modo Demo!");
        else 
            $display(">>> FALHA: Nao ganhou apos 4 rodadas. Acertou=%b, Pronto=%b", acertou, pronto);


        // CENARIO 2: Erro Proposital na Rodada 3 (Modo Normal)
        $display("\nTESTE 2: MODO NORMAL - ERRO NA RODADA 2 (3 itens)");
        $display("-------------------------------------------------");
        
        reset_sistema();
        iniciar_novo_jogo(1'b0); // Modo 0 = Normal

        // Rodada 0 (1 item): Acerta
        jogar_nivel_k(0); 
        #(CLOCK_PERIOD*20);

        // Rodada 1 (2 itens): Acerta
        jogar_nivel_k(1);
        #(CLOCK_PERIOD*20);

        // Rodada 2 (3 itens): Erra no ultimo
        $display("    ... Jogando nivel 3 (Erro proposital no ultimo item) ...");
        pressiona_chave(gabarito[0]);
        pressiona_chave(gabarito[1]);
        pressiona_chave(~gabarito[2]); 

        #(CLOCK_PERIOD*10);
        if (errou && pronto && !acertou) 
            $display(">>> SUCESSO: Detectou erro corretamente na rodada 3.");
        else 
            $display(">>> FALHA: Nao detectou erro. Errou=%b", errou);


        // CENARIO 3: Teste de Timeout
        $display("\nTESTE 3: TIMEOUT (Esperar sem jogar)");
        $display("------------------------------------");
        
        reset_sistema();
        iniciar_novo_jogo(1'b1);

        $display("    Aguardando timeout (aprox 5000 ciclos)...");
        #(CLOCK_PERIOD * 5500); 

        if (timeout && pronto) 
            $display(">>> SUCESSO: Timeout detectado e jogo encerrado.");
        else 
            $display(">>> FALHA: Timeout nao gerado. Timeout=%b, Pronto=%b", timeout, pronto);

        // CENARIO 4: Travamento de Modo
        $display("\nTESTE 4: TRAVAMENTO DE MODO");
        $display("---------------------------");
        
        reset_sistema();
        @(negedge clock);
        modo = 1'b1;
        iniciar = 1'b1;
        #(CLOCK_PERIOD*2);
        iniciar = 1'b0;
        
        #(CLOCK_PERIOD*10);
        modo = 1'b0; 
        #(CLOCK_PERIOD*5);
        
        if (db_modo == 1'b1) 
            $display(">>> SUCESSO: Modo travou em 1 mesmo mudando a chave para 0.");
        else 
            $display(">>> FALHA: Modo mudou durante o jogo! db_modo=%b", db_modo);

        
        $display("   FIM DOS TESTES");
        $finish;
    end

endmodule