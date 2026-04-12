// ---------------------------------------------------------------------------
// Módulo: unidade_controle
// ---------------------------------------------------------------------------
// FSM (Máquina de Estados Finita) do jogo.
//
// Controla o fluxo do jogo em três fases principais:
//   1. EXIBIÇÃO  – apresenta a sequência de cores nos LEDs RGB, uma a uma,
//                   com intervalo apagado entre cada cor.
//   2. RESPOSTA  – aguarda as jogadas do jogador, registra cada botão
//                   pressionado e compara com a sequência armazenada.
//   3. EXPANSÃO  – após acerto completo, solicita ao jogador um novo
//                   elemento para expandir a sequência (modo cumulativo).
//
// ---------------------------------------------------------------------------
module unidade_controle (
    // -- Sinais globais -------------------------------------------------------
    input      clock,
    input      reset,

    // -- Entradas de controle do jogo -----------------------------------------
    input      iniciar,             // pulso do botão "jogar"
    input      fim_jogo,
    input      enderecoIgualLimite,
    input      jogada,
    input      igual,
    input      timeout,
    input      timeout_habilitado,
    input      timeout_led,
    input      fim_sequencia,

    // -- Saídas de comando para o fluxo de dados ------------------------------
    output reg zera_endereco,
    output reg conta_endereco,
    output reg zera_limite,
    output reg conta_limite,
    output reg zeraR,
    output reg registrarR,
    output reg registra_modo,
    output reg zera_modo,
    output reg zera_s_timeout,
    output reg enable_timeout,
    output reg conf_leds,
    output reg registra_jogada,
    output reg zera_s_led,
    output reg enable_led,

    // -- Sinais de status / resultado -----------------------------------------
    output reg acertou,
    output reg errou,
    output reg pronto,

    // -- Depuração ------------------------------------------------------------
    output reg [4:0] db_estado,
    output reg db_timeout
);

    reg [4:0] Eatual, Eprox;

    // =========================================================================
    // Codificação dos estados
    // =========================================================================
    //
    // Fase de exibição da sequência:
    //   preparacao  → carrega_led → mostra_led ⇄ (espera timer)
    //                 ↑             zera_led → mostra_apagado → proximo_led ─┘
    //
    // Fase de resposta do jogador:
    //   espera → registra → comparacao ──→ proximo (próximo item)
    //                                  └─→ adiciona_jogada (rodada concluída)
    //                                  └─→ final_erro / final_acerto
    //
    parameter inicial         = 5'b00000;
    parameter preparacao      = 5'b00001; // registra configuração e zera contadores
    parameter carrega_led     = 5'b00010;
    parameter mostra_led      = 5'b00011;
    parameter zera_led        = 5'b00100;
    parameter mostra_apagado  = 5'b00101;
    parameter proximo_led     = 5'b00110;
    parameter espera          = 5'b00111; // com timeout opcional
    parameter registra        = 5'b01000;
    parameter comparacao      = 5'b01001;
    parameter proximo         = 5'b01010;
    parameter final_acerto    = 5'b01011;
    parameter final_erro      = 5'b01100;
    parameter adiciona_jogada = 5'b01101; // aguarda novo elemento para expandir sequência
    parameter proxima_rodada  = 5'b01110;
    parameter final_timeout   = 5'b01111;
	parameter fim_sequencia_timer = 5'b10000;
	parameter atualiza_endereco_nova_jogada = 5'b10001;
	parameter erro_verilog = 5'b10010;

    // =========================================================================
    // Registrador de estado (com reset assíncrono)
    // =========================================================================
    always @(posedge clock or posedge reset) begin
        if (reset) Eatual <= inicial;
        else       Eatual <= Eprox;
    end

    // =========================================================================
    // Lógica de próximo estado
    // =========================================================================
    always @* begin
        case (Eatual)
            inicial:        Eprox = iniciar ? preparacao : inicial;
            preparacao:     Eprox = carrega_led;

            // --- Exibição da sequência (LED aceso → apagado → próximo) -------
            carrega_led:    Eprox = mostra_led;
            mostra_led:     Eprox = timeout_led ? zera_led : mostra_led;
            zera_led:       Eprox = mostra_apagado;
            mostra_apagado: Eprox = fim_sequencia  ? fim_sequencia_timer : proximo_led;
            proximo_led:    Eprox = carrega_led;

            // --- Fase de resposta do jogador ---------------------------------
            espera:         if (timeout && timeout_habilitado) Eprox = final_timeout;
                            else Eprox = jogada ? registra : espera;
            registra:       Eprox = comparacao;

            comparacao:     begin
                                if (!igual)
                                    Eprox = final_erro;
                                else if (enderecoIgualLimite)
                                    Eprox = fim_jogo ? final_acerto : atualiza_endereco_nova_jogada;
                                else
                                    Eprox = proximo;
                            end

            // --- Expansão da sequência e avanço de rodada --------------------
            adiciona_jogada:Eprox = jogada ? proxima_rodada : adiciona_jogada;
            proximo:        Eprox = espera;
            proxima_rodada: Eprox = carrega_led;

            // --- Estados terminais (reiniciáveis com "jogar") ----------------
            final_acerto:   Eprox = iniciar ? preparacao : final_acerto;
            final_erro:     Eprox = iniciar ? preparacao : final_erro;
            final_timeout:  Eprox = iniciar ? preparacao : final_timeout;
				fim_sequencia_timer: Eprox = espera;
				atualiza_endereco_nova_jogada: Eprox = adiciona_jogada;
            default:        Eprox = erro_verilog;
        endcase
    end

    // =========================================================================
    // Lógica de saída
    // =========================================================================
    always @* begin
        // BUG: alterei pra zerar o endereço depois da luz mostrar, caso contrário ele fica preso comparando com a primeira jogada sempre 
        zera_endereco  = (Eatual == preparacao || Eatual == proxima_rodada || Eatual == fim_sequencia_timer);

        // Avanço antecipado ao acertar o último item: o endereço já aponta
        // para a posição livre usada em adiciona_jogada.
        conta_endereco = (Eatual == proximo || Eatual == proximo_led
                          || Eatual == atualiza_endereco_nova_jogada);

        zera_limite    = (Eatual == preparacao);
        conta_limite   = (Eatual == proxima_rodada);

        zeraR          = (Eatual == preparacao || Eatual == proxima_rodada);
        registrarR     = (Eatual == registra);

        zera_modo      = (Eatual == inicial);
        registra_modo  = (Eatual == preparacao);

        // Zerado em todos os predecessores de espera para evitar
        // timeout residual acumulado de rodadas anteriores.
        zera_s_timeout = (Eatual == preparacao || Eatual == proximo
                          || Eatual == proxima_rodada || Eatual == inicial);
        
        // TODO: Timeout também está valendo para escolher a nova cor. Não sei se era o intencionado. Verificar.
        enable_timeout = (Eatual == espera || Eatual == adiciona_jogada);
			
        acertou = (Eatual == final_acerto);
        errou   = (Eatual == final_erro) || (Eatual == final_timeout);
        pronto  = (Eatual == final_timeout || Eatual == final_acerto || Eatual == final_erro);

        // Condicionada ao pulso de jogada para evitar escrita
        // na borda de entrada do estado.
        registra_jogada = (Eatual == adiciona_jogada);

        zera_s_led = (Eatual == carrega_led || Eatual == zera_led);
        enable_led = (Eatual == mostra_led  || Eatual == mostra_apagado);
        conf_leds  = (Eatual == mostra_led);

        db_estado  = Eatual;
        db_timeout = (Eatual == final_timeout);
    end
endmodule