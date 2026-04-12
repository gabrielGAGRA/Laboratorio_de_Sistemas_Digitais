module unidade_controle (
    input      clock,
    input      reset,
    input      iniciar,
    input      fim,
    input      jogada,    // Vem do pulso jogada_feita do FD
    input      igual,
    output reg zerac,
    output reg contac,
    output reg zeraR,
    output reg registrarR,
    output reg acertou,
    output reg errou,
    output reg pronto,
    output reg [3:0] db_estado
);

    reg [3:0] Eatual, Eprox;

    // Definição dos estados conforme Figura 6 [cite: 160, 187]
    parameter inicial      = 4'b0000; 
    parameter preparacao   = 4'b0001; 
    parameter espera       = 4'b0010; // Novo estado de espera
    parameter registra     = 4'b0100; 
    parameter comparacao   = 4'b0101; 
    parameter proximo      = 4'b0110; 
    parameter final_acerto = 4'b1000; // Estado azul
    parameter final_erro   = 4'b1001; // Estado vermelho

    always @(posedge clock or posedge reset) begin
        if (reset) Eatual <= inicial;
        else Eatual <= Eprox;
    end

    always @* begin
        case (Eatual)
            inicial:    Eprox = iniciar ? preparacao : inicial;
            preparacao: Eprox = espera;
            espera:     Eprox = jogada ? registra : espera; // Aguarda pulso [cite: 162]
            registra:   Eprox = comparacao;
            comparacao: if (!igual) Eprox = final_erro;
                        else Eprox = fim ? final_acerto : proximo;
            proximo:    Eprox = espera;
            final_acerto: Eprox = iniciar ? preparacao : final_acerto;
            final_erro:   Eprox = iniciar ? preparacao : final_erro;
            default:    Eprox = inicial;
        endcase
    end

    always @* begin
        // Sinais de controle
        zerac      = (Eatual == preparacao);
        zeraR      = (Eatual == preparacao);
        registrarR = (Eatual == registra);
        contac     = (Eatual == proximo);
        
        // Sinais de status fixos [cite: 166]
        acertou    = (Eatual == final_acerto);
        errou      = (Eatual == final_erro);
        pronto     = (Eatual == final_acerto || Eatual == final_erro);
        
        db_estado  = Eatual;
    end
endmodule