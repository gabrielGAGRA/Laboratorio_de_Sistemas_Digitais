module unidade_controle (
    input      clock,
    input      reset,
    input      iniciar,             // jogar
    input      fim_jogo,            // Limite atingiu o maximo e acabou a sequencia
    input      enderecoIgualLimite, // Fim da sequencia atual
    input      jogada,
    input      igual,
    input      timeout,
    output reg zera_endereco,       // Zera contador da sequencia
    output reg conta_endereco,      // Incrementa contador da sequencia
    output reg zera_limite,         // Zera contador de rodadas
    output reg conta_limite,        // Incrementa contador de rodadas
    output reg zeraR,
    output reg registrarR,
    output reg registra_modo,
    output reg zera_modo,
    output reg acertou,             // ganhou
    output reg errou,               // perdeu
    output reg pronto,
    output reg [3:0] db_estado,
    output reg db_timeout,
    output reg zera_s_timeout,
    output reg enable_timeout
);

    reg [3:0] Eatual, Eprox;

    // Definição dos estados
    parameter inicial        = 4'b0000;
    parameter preparacao     = 4'b0001;
    parameter espera         = 4'b0010;
    parameter registra       = 4'b0011;
    parameter comparacao     = 4'b0100;
    parameter proximo        = 4'b0101; // proximo endereco dentro da sequencia
    parameter final_acerto   = 4'b0110;
    parameter final_erro     = 4'b0111;
    parameter proxima_rodada = 4'b1000; // incrementa limite
    parameter final_timeout  = 4'b1111;

    always @(posedge clock or posedge reset) begin
        if (reset) Eatual <= inicial;
        else Eatual <= Eprox;
    end

    always @* begin
        case (Eatual)
            inicial:        Eprox = iniciar ? preparacao : inicial;
            preparacao:     Eprox = espera;
            espera:         if (timeout) Eprox = final_timeout;
                            else Eprox = jogada ? registra : espera;
            registra:       Eprox = comparacao;
            comparacao:     begin
                                if (!igual) 
                                    Eprox = final_erro;
                                else begin
                                    // Se acertou, verifica se terminou a sequencia atual
                                    if (enderecoIgualLimite) begin
                                        // Se terminou sequencia, verifica se era a ULTIMA rodada
                                        if (fim_jogo) Eprox = final_acerto;
                                        else Eprox = proxima_rodada;
                                    end else begin
                                        // Se nao terminou sequencia, vai para proximo item
                                        Eprox = proximo;
                                    end
                                end
                            end
            proximo:        Eprox = espera;
            proxima_rodada: Eprox = espera;
            final_acerto:   Eprox = iniciar ? preparacao : final_acerto;
            final_erro:     Eprox = iniciar ? preparacao : final_erro;
            final_timeout:  Eprox = iniciar ? preparacao : final_timeout;
            default:        Eprox = inicial;
        endcase
    end

    // Sinais de controle do fluxo de dados
    always @* begin        
        // Inicio do jogo OU mudanca de rodada
        zera_endereco = (Eatual == preparacao || Eatual == proxima_rodada);

        // dentro da mesma rodada
        conta_endereco = (Eatual == proximo);
        
        // inicio total do jogo
        zera_limite = (Eatual == preparacao);

        // passar de rodada
        conta_limite = (Eatual == proxima_rodada);

        zeraR      = (Eatual == preparacao || Eatual == proxima_rodada || Eatual == proximo); 
        registrarR = (Eatual == registra);

        // controle do registrador de modo
        zera_modo     = (Eatual == inicial);
        registra_modo = (Eatual == preparacao);

        // reseta o timer toda vez que voltamos a esperar uma nova jogada
        zera_s_timeout = (Eatual == preparacao || Eatual == proximo || Eatual == proxima_rodada || Eatual == inicial);
        enable_timeout = (Eatual == espera);
        
        // sinais de saídas
        acertou    = (Eatual == final_acerto);
        errou      = (Eatual == final_erro);
        pronto     = (Eatual == final_timeout || Eatual == final_acerto || Eatual == final_erro);
        
        db_estado  = Eatual;
        db_timeout = (Eatual == final_timeout);
    end
endmodule