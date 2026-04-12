// ---------------------------------------------------------------------------
// Modulo: gerador_audio
// Descricao: Gera frequencias musicais com controle de volume via PWM.
// ---------------------------------------------------------------------------
module gerador_audio (
    input        clock,       
    input        reset,
    input [17:0] fim_contagem,  // Periodo da nota calculado para 50MHz
    input        habilitar,     // Toca apenas se nota estiver pressionada
    output       buzzer
);

    reg [17:0] contador;
    reg        s_buzzer;

    // Duty cycle fixo de 50% (onda quadrada) que eh o volume maximo
    wire [17:0] threshold = (fim_contagem >> 1); 

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            contador <= 18'd0;
            s_buzzer <= 1'b0;
        end else if (habilitar) begin
            if (contador >= fim_contagem) begin
                contador <= 18'd0;
            end else begin
                contador <= contador + 1'b1;
            end
            
            // Define o sinal de saida
            s_buzzer <= (contador < threshold);
        end else begin
            contador <= 18'd0;
            s_buzzer <= 1'b0;
        end
    end

    assign buzzer = s_buzzer;

endmodule