module exp4_unidade_controle (
    input      clock,
    input      reset,
    input      iniciar,
    input      fim,
    input      fim_4_jogadas,
    input      modo,
    input      jogada,    // pulso jogada_feita do FD
    input      igual,
    input timeout,
    output reg zerac,
    output reg contac,
    output reg zeraR,
    output reg registrarR,
    output reg registra_modo,
    output reg acertou,
    output reg errou,
    output reg pronto,
    output reg [3:0] db_estado,
    output reg db_timeout,
    output reg zera_s_timeout
);

    reg [3:0] Eatual, Eprox;

    // estados
    parameter inicial      = 4'b0000; // inicial = 0
    parameter aguarda_modo = 4'b1000; // aguarda_modo = 8
    parameter preparacao   = 4'b0001; // preparacao = 1
    parameter espera       = 4'b0010; // espera =  2
    parameter registra     = 4'b0011; // registra = 3
    parameter comparacao   = 4'b0100; // comparacao = 4
    parameter proximo      = 4'b0101; // proximo = 5
    parameter final_acerto = 4'b0110; // acertou = 6
    parameter final_erro   = 4'b0111; // errou = 7 
    parameter final_timeout = 4'b1111; // timeout = F

    always @(posedge clock or posedge reset) begin
        if (reset) Eatual <= inicial;
        else Eatual <= Eprox;
    end

    always @* begin
        case (Eatual)
            inicial:    Eprox = iniciar ? aguarda_modo : inicial;
            aguarda_modo: Eprox = preparacao;
            preparacao: Eprox = espera;
            espera:     if (timeout) Eprox = final_timeout; // vai pro timeout
                        else Eprox = jogada ? registra : espera; 
            registra:   Eprox = comparacao;
            comparacao: if (!igual) Eprox = final_erro;
                        else if (modo == 1'b0) Eprox = fim ? final_acerto : proximo;  // modo=0: 16 jogadas
                        else Eprox = fim_4_jogadas ? final_acerto : proximo;  // modo=1: 4 jogadas
            proximo:    Eprox = espera;
            final_acerto: Eprox = iniciar ? aguarda_modo : final_acerto;
            final_erro:   Eprox = iniciar ? aguarda_modo : final_erro;
            final_timeout: Eprox = iniciar ? aguarda_modo : final_timeout;
            default:    Eprox = inicial;
        endcase
    end

    always @* begin
        // sinais de controle
        zerac      = (Eatual == preparacao);
        zeraR      = (Eatual == preparacao);
        registrarR = (Eatual == registra);
        contac     = (Eatual == proximo);
        registra_modo = (Eatual == aguarda_modo);

        //sinal zera s para  preparacao e a cada jogada
        zera_s_timeout = (Eatual == preparacao || Eatual == proximo);
        
        // sinais de status
        acertou    = (Eatual == final_acerto);
        errou      = (Eatual == final_erro);
        pronto     = (Eatual == final_timeout || Eatual == final_acerto || Eatual == final_erro);
        
        db_estado  = Eatual;
        db_timeout = (Eatual == final_timeout);
    end
endmodule