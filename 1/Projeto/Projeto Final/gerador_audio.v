// ---------------------------------------------------------------------------
// Modulo: gerador_audio
// Descricao: Frequencias musicais com Envelope ADSR independente 
// do estagio de ganho (Volume Master).
// ---------------------------------------------------------------------------
module gerador_audio (
    input        clock,       
    input        reset,
    input [17:0] fim_contagem,  
    input        habilitar,     
    input  [3:0] nivel_volume,  // 0 a 15 (Vem do s_duty_cycle)
    output       buzzer
);

    // 1. Geração da Onda Base (A frequência pura)
    reg [17:0] contador_freq;
    reg        onda_quadrada;
    wire [17:0] threshold = (fim_contagem >> 1);

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            contador_freq <= 18'd0;
            onda_quadrada <= 1'b0;
        end else if (habilitar) begin
            if (contador_freq >= fim_contagem) contador_freq <= 18'd0;
            else contador_freq <= contador_freq + 1'b1;
            
            onda_quadrada <= (contador_freq < threshold);
        end else begin
            contador_freq <= 18'd0;
            onda_quadrada <= 1'b0;
        end
    end

    // 2. Gerador de Envelope Normalizado (Sempre de 0 a 1000)
    // O tempo de decaimento agora é 100% consistente, não importa o volume.
    reg [9:0]  envelope_val;
    reg [19:0] timer_envelope;
    reg        habilitar_antigo;

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            envelope_val     <= 10'd0;
            timer_envelope   <= 20'd0;
            habilitar_antigo <= 1'b0;
        end else begin
            habilitar_antigo <= habilitar;

            if (habilitar && !habilitar_antigo) begin
                // ATTACK: Sempre estoura em 1000
                envelope_val   <= 10'd1000; 
                timer_envelope <= 20'd0;
            end 
            else if (habilitar) begin
                // DECAY / SUSTAIN
                timer_envelope <= timer_envelope + 1'b1;
                if (timer_envelope >= 20'd50_000) begin 
                    timer_envelope <= 20'd0;
                    // Piso do Sustain normalizado em 150
                    if (envelope_val > 10'd150) 
                        envelope_val <= envelope_val - 1'b1;
                end
            end 
            else begin
                // RELEASE
                timer_envelope <= timer_envelope + 1'b1;
                if (timer_envelope >= 20'd10_000) begin
                    timer_envelope <= 20'd0;
                    if (envelope_val > 10'd0)
                        envelope_val <= envelope_val - 1'b1;
                end
            end
        end
    end

    // 3. Estágio de Ganho (Multiplicador de Volume)
    // Fio de 14 bits evita o overflow na multiplicacao (1000 * 15 = 15000)
    wire [13:0] calc_ganho = envelope_val * nivel_volume;
    
    // Agora sim, reduzimos de volta para a escala de 10 bits do PWM (>> 4)
    wire [9:0] volume_final = calc_ganho[13:4];
    
    // 4. Modulação de Alta Frequência (PWM de 50kHz)
    reg [9:0] contador_pwm_hf;
    always @(posedge clock or posedge reset) begin
        if (reset) contador_pwm_hf <= 10'd0;
        else if (contador_pwm_hf >= 10'd1000) contador_pwm_hf <= 10'd0;
        else contador_pwm_hf <= contador_pwm_hf + 1'b1;
    end

    // Saída junta a nota com o envelope atenuado pelo volume
    assign buzzer = onda_quadrada & (contador_pwm_hf < volume_final);

endmodule