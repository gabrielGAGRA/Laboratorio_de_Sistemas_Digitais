//------------------------------------------------------------------
// Arquivo   : registrador_1.v
// Projeto   : Experiencia 5 - Jogo do Genius
//------------------------------------------------------------------
// Descricao : Registrador de 1 bit
//------------------------------------------------------------------
module registrador_1 (
    input        clock,
    input        clear,
    input        enable,
    input        D,
    output       Q
);

    reg IQ;

    always @(posedge clock or posedge clear) begin
        if (clear)
            IQ <= 1'b0;
        else if (enable)
            IQ <= D;
    end

    assign Q = IQ;

endmodule
