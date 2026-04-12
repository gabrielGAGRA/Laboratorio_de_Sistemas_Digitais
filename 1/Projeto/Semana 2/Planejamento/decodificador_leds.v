// ---------------------------------------------------------------------------
// Modulo: decodificador_leds
// Descricao: Converte o ID da nota (1 a 7) para 7 LEDs difusos (one-hot).
// ---------------------------------------------------------------------------
module decodificador_leds (
    input      [2:0] nota_id,
    output reg [6:0] leds
);

    always @(*) begin
        case (nota_id)
            3'd1: leds = 7'b1000110; // Dó (C)
            3'd2: leds = 7'b0100001; // Ré (D)
            3'd3: leds = 7'b0000110; // Mi (E)
            3'd4: leds = 7'b0001110; // Fá (F)
            3'd5: leds = 7'b0010000; // Sol (G)
            3'd6: leds = 7'b0001000; // Lá (A)
            3'd7: leds = 7'b0000011; // Si (B)
            default: leds = 7'b1111111;
        endcase
    end

endmodule