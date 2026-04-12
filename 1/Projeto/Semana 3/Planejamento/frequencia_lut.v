// ---------------------------------------------------------------------------
// Modulo: frequency_lut
// Descricao: Converte nota e oitava no limite do contador (N_ticks).
// Base: Clock de 50MHz.
// ---------------------------------------------------------------------------
module frequency_lut (
    input  [2:0] nota_id,    
    output reg [17:0] n_ticks
);

    reg [17:0] base_freq;

    // Valores calculados para a Oitava 4 (261Hz a 493Hz)
    // N = 50.000.000 / Freq_Nota. Definimos quantos clocks ele deve contar para cada nota usando a formula.
    always @(*) begin
        case (nota_id)
            3'd1: base_freq = 18'd191113; // Do4 (261.63 Hz)
            3'd2: base_freq = 18'd170262; // Re4 (293.66 Hz)
            3'd3: base_freq = 18'd151686; // Mi4 (329.63 Hz)
            3'd4: base_freq = 18'd143173; // Fa4 (349.23 Hz)
            3'd5: base_freq = 18'd127553; // Sol4(392.00 Hz)
            3'd6: base_freq = 18'd113636; // La4 (440.00 Hz)
            3'd7: base_freq = 18'd101239; // Si4 (493.88 Hz)
            default: base_freq = 18'd0;
        endcase

        n_ticks = base_freq;
    end
endmodule