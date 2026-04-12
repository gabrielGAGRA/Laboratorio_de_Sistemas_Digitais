// Converte o código one-hot do botão (bit 3=verde, 1=azul, 2=amarelo, 0=vermelho)
// para o sinal RGB do LED.
module cores_rgb(
    input  [3:0] codigo,
    output reg [2:0] leds_rgb
);
    always @* begin
        case (codigo)
            4'b1000: leds_rgb = 3'b010; // verde    (A=0, V=1, R=0)
            4'b0001: leds_rgb = 3'b001; // vermelho (A=0, V=0, R=1)
            4'b0010: leds_rgb = 3'b100; // azul     (A=1, V=0, R=0)
            4'b0100: leds_rgb = 3'b011; // amarelo  (Vermelho + Verde -> A=0, V=1, R=1)
        endcase
    end

endmodule