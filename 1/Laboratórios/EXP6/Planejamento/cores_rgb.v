// Converte o código one-hot do botão (bit 3=verde, 1=azul, 2=amarelo, 0=vermelho)
// para o sinal RGB do LED.
module cores_rgb(
    input  [3:0] codigo,
    output reg [2:0] leds_rgb
);
    always @* begin
        case (codigo)
            4'b1000: leds_rgb = 3'b100; // verde
            4'b0001: leds_rgb = 3'b001; // vermelho
            4'b0010: leds_rgb = 3'b010; // azul
            4'b0100: leds_rgb = 3'b101; // amarelo
            default: leds_rgb = 3'b000;
        endcase
    end

endmodule