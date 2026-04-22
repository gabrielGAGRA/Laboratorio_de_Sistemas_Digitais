// ---------------------------------------------------------------------------
// Modulo: mux_musicas
// Descricao: Seletor de dados das memorias ROM (musicas) e RAM (gravacao)
// ---------------------------------------------------------------------------
module mux_musicas (
    input [5:0] sel,
    input [6:0] d0, d1, d2, d3, d4, d5, d6, d7, d8, d9, d10, d11, d12, d13, d14, d15, d16, d17, d18, d19, d20, d21, d22, d23, d24, d25, d26, d27, d28, d29, d30, d31, d32, d33, d34, d35, d36, d37, d38,
    output reg [6:0] out
);
    always @(*) begin
        case(sel)
            4'd0: out = d0;
            4'd1: out = d1;
            4'd2: out = d2;
            4'd3: out = d3;
            4'd4: out = d4;
            4'd5: out = d5;
            4'd6: out = d6;
            4'd7: out = d7;
            4'd8: out = d8;
            4'd9: out = d9;
            4'd10: out = d10;
            4'd11: out = d11;
            4'd12: out = d12;
            4'd13: out = d13;
            4'd14: out = d14;
            4'd15: out = d15;
            4'd16: out = d16;
            4'd17: out = d17;
            4'd18: out = d18;
            4'd19: out = d19;
            4'd20: out = d20;
            4'd21: out = d21;
            4'd22: out = d22;
            4'd23: out = d23;
            4'd24: out = d24;
            4'd25: out = d25;
            4'd26: out = d26;
            4'd27: out = d27;
            4'd28: out = d28;
            4'd29: out = d29;
            4'd30: out = d30;
            4'd31: out = d31;
			4'd32: out = d32;
            4'd33: out = d33;
            4'd34: out = d34;
            4'd35: out = d35;
            4'd36: out = d36;
            4'd37: out = d37;
            4'd38: out = d38;
            default: out = 7'b0;
        endcase
    end
endmodule
