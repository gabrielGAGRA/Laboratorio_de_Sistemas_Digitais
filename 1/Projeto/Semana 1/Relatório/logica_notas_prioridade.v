// ---------------------------------------------------------------------------
// Modulo: logica_notas_prioridade
// Descricao: Implementa a prioridade da ultima tecla pressionada.
// ---------------------------------------------------------------------------
module logica_notas_prioridade (
    input        clock,
    input        reset,
    input  [6:0] botoes,       // Do=0 a Si=6
    output reg [2:0] nota_id,  // ID da nota ativa (1 a 7)
    output       tem_nota      // Flag se alguma nota deve soar
);

    reg [6:0] botoes_ant;
    assign tem_nota = |botoes;

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            nota_id    <= 3'd0;
            botoes_ant <= 7'd0;
        end else begin
            botoes_ant <= botoes;

            // Override: Detecta borda de subida em cada botao
            if      (botoes[0] && !botoes_ant[0]) nota_id <= 3'd1; // Do
            else if (botoes[1] && !botoes_ant[1]) nota_id <= 3'd2; // Re
            else if (botoes[2] && !botoes_ant[2]) nota_id <= 3'd3; // Mi
            else if (botoes[3] && !botoes_ant[3]) nota_id <= 3'd4; // Fa
            else if (botoes[4] && !botoes_ant[4]) nota_id <= 3'd5; // Sol
            else if (botoes[5] && !botoes_ant[5]) nota_id <= 3'd6; // La
            else if (botoes[6] && !botoes_ant[6]) nota_id <= 3'd7; // Si
            
            // Fallback: Se a ultima nota ativa foi solta, mas outras estao pressionadas, volta para a de maior indice (comportamento previsivel)
            if (tem_nota && !botoes[nota_id-1]) begin
                if      (botoes[6]) nota_id <= 3'd7;
                else if (botoes[5]) nota_id <= 3'd6;
                else if (botoes[4]) nota_id <= 3'd5;
                else if (botoes[3]) nota_id <= 3'd4;
                else if (botoes[2]) nota_id <= 3'd3;
                else if (botoes[1]) nota_id <= 3'd2;
                else if (botoes[0]) nota_id <= 3'd1;
            end
        end
    end

endmodule