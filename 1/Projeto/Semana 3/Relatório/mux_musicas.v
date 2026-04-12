module mux_musicas (
    input [3:0] sel,
    input [6:0] d0,  d1,  d2,  d3,  
    input [6:0] d4,  d5,  d6,  d7,  
    input [6:0] d8,  d9,  d10, d11, 
    input [6:0] d12, d13, d14,
    output reg [6:0] out
);
    always @(*) begin
        case (sel)
            4'd0:  out = d0;
            4'd1:  out = d1;
            4'd2:  out = d2;
            4'd3:  out = d3;
            4'd4:  out = d4;
            4'd5:  out = d5;
            4'd6:  out = d6;
            4'd7:  out = d7;
            4'd8:  out = d8;
            4'd9:  out = d9;
            4'd10: out = d10;
            4'd11: out = d11;
            4'd12: out = d12;
            4'd13: out = d13;
            4'd14: out = d14;
            default: out = d0;
        endcase
    end
endmodule
