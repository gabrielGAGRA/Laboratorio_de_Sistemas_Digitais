// ---------------------------------------------------------------------------
// Modulo: gerador_audio
// Descricao: Frequencias musicais com Envelope ADSR independente 
// Ajustado para tempos 2.5x mais longos e transicoes suaves.
// ---------------------------------------------------------------------------
module gerador_audio (
    input        clock,       
    input        reset,
    input [17:0] fim_contagem,  
    input        habilitar,     
    input  [3:0] nivel_volume,  // 0 a 15
    output       buzzer
);

    // 1. Geração da Onda Base
    reg [17:0] contador_freq;
    reg        onda_quadrada;
    wire [17:0] threshold = (fim_contagem >> 3); // Duty cycle de 12.5%

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            contador_freq <= 18'd0;
            onda_quadrada <= 1'b0;
        end else if (habilitar || envelope_val > 0) begin
            // Mantem a frequencia rodando enquanto houver som (mesmo no release)
            if (contador_freq >= fim_contagem) contador_freq <= 18'd0;
            else contador_freq <= contador_freq + 1'b1;
            
            onda_quadrada <= (contador_freq < threshold);
        end else begin
            contador_freq <= 18'd0;
            onda_quadrada <= 1'b0;
        end
    end

    // 2. Gerador de Envelope (ADSR)
    // Tempos multiplicados por 2.5 para maior duracao.
    reg [9:0]  envelope_val;
    reg [19:0] timer_envelope; // 20 bits comportam ate ~1 milhao
    reg        habilitar_antigo;

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            envelope_val     <= 10'd0;
            timer_envelope   <= 20'd0;
            habilitar_antigo <= 1'b0;
        end else begin
            habilitar_antigo <= habilitar;

            // Transicao: Nota ligada (Attack)
            if (habilitar && !habilitar_antigo) begin
                envelope_val   <= 10'd1000; 
                timer_envelope <= 20'd0;
            end 
            // Transicao: Nota desligada (Inicio do Release)
            else if (!habilitar && habilitar_antigo) begin
                timer_envelope <= 20'd0; // Reset para consistencia no release
            end
            // Estado: Nota Ativa (Decay / Sustain)
            else if (habilitar) begin
                if (timer_envelope >= 20'd125_000) begin // 50k * 2.5
                    timer_envelope <= 20'd0;
                    if (envelope_val > 10'd150) // Piso de Sustain
                        envelope_val <= envelope_val - 1'b1;
                end else begin
                    timer_envelope <= timer_envelope + 1'b1;
                end
            end 
            // Estado: Nota em Release
            else begin
                if (timer_envelope >= 20'd25_000) begin // 10k * 2.5
                    timer_envelope <= 20'd0;
                    if (envelope_val > 10'd0)
                        envelope_val <= envelope_val - 1'b1;
                end else begin
                    timer_envelope <= timer_envelope + 1'b1;
                end
            end
        end
    end

    // 3. Estágio de Ganho
    wire [13:0] calc_ganho = envelope_val * nivel_volume;
    wire [9:0] volume_final = calc_ganho[13:4];
    
    // 4. Modulação PWM (50kHz para clock de 50MHz)
    reg [9:0] contador_pwm_hf;
    always @(posedge clock or posedge reset) begin
        if (reset) contador_pwm_hf <= 10'd0;
        else if (contador_pwm_hf >= 10'd1000) contador_pwm_hf <= 10'd0;
        else contador_pwm_hf <= contador_pwm_hf + 1'b1;
    end

    // Saida final
    assign buzzer = onda_quadrada & (contador_pwm_hf < volume_final);

endmodule
