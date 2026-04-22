// ---------------------------------------------------------------------------
// Modulo: gerador_audio
// Descricao: Gera frequencias com controle de volume e envelope de decaimento.
// ---------------------------------------------------------------------------
module gerador_audio #(
    parameter TIME_DECAY = 12_500_000 // ~250ms por estagio em 50MHz
) (
    input        clock,       
    input        reset,
    input [17:0] fim_contagem,  
    input        habilitar,     
    input  [1:0] volume_master, // 0: 100%, 1: 75%, 2: 50%
    output       buzzer
);
    reg [17:0] contador;
    reg        s_buzzer;
    reg [31:0] tempo_env;
    reg [3:0]  estagio_env;

    // Define o volume inicial espremendo o Duty Cycle base
    // 100% = 50% DC (>>1), 75% = 25% DC (>>2), 50% = 12.5% DC (>>3)
    wire [17:0] t_base = (volume_master == 2'd0) ? (fim_contagem >> 1) :
                         (volume_master == 2'd1) ? (fim_contagem >> 2) :
                                                   (fim_contagem >> 3);

    // Aplica o decaimento (Envelope logarítmico super eficiente)
    wire [17:0] threshold = (t_base >> estagio_env);

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            contador <= 18'd0;
            tempo_env <= 32'd0;
            estagio_env <= 4'd0;
            s_buzzer <= 1'b0;
        end else if (habilitar) begin
            // Oscilador Principal
            if (contador >= fim_contagem) contador <= 18'd0;
            else contador <= contador + 1'b1;
            
            s_buzzer <= (contador < threshold) && (threshold > 0);

            // Temporizador do Envelope
            if (tempo_env >= TIME_DECAY) begin
                tempo_env <= 32'd0;
                // Limita o decaimento para não "passar direto"
                if (estagio_env < 4'd8) estagio_env <= estagio_env + 1'b1; 
            end else begin
                tempo_env <= tempo_env + 1'b1;
            end
        end else begin
            // Reset instantâneo ao soltar a tecla
            contador <= 18'd0;
            tempo_env <= 32'd0;
            estagio_env <= 4'd0;
            s_buzzer <= 1'b0;
        end
    end

    assign buzzer = s_buzzer;
endmodule