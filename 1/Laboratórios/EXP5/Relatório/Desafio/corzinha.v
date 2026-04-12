module corzinha(
    input  [3:0] codigo,
    output reg [2:0] rgb
);
    always @* begin
        case (codigo)
            4'b1000: rgb = 3'b100; // verde
            4'b0001: rgb = 3'b001; // vermelho
            4'b0010: rgb = 3'b010; // azul
            4'b0100: rgb = 3'b101; // amarelo
            default: rgb = 3'b000; // nada
        endcase
    end

endmodule