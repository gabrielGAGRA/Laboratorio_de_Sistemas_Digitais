// ---------------------------------------------------------------------------
// Modulo: gerador_audio
// Descricao: Gera frequencias musicais com controle de volume via PWM 
// simulando o decaimento (envelope) de um piano real.
// ---------------------------------------------------------------------------
module gerador_audio (
    input        clock,       
    input        reset,
    input [17:0] fim_contagem,  
    input        habilitar,     
    input  [3:0] nivel_volume,
    output       buzzer
);
    
    reg [17:0] contador_freq;
    reg        onda_quadrada;

    wire [17:0] threshold = (fim_contagem >> 1);

    // 1. Geração da Onda Base (A frequência pura da nota)
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            contador_freq <= 18'd0;
            onda_quadrada <= 1'b0;
        end else if (habilitar) begin
            if (contador_freq >= fim_contagem) begin
                contador_freq <= 18'd0;
            end else begin
                contador_freq <= contador_freq + 1'b1;
            end
            onda_quadrada <= (contador_freq < threshold);
        end else begin
            contador_freq <= 18'd0;
            onda_quadrada <= 1'b0;
        end
    end

    // O pico do volume é o duty cycle deslocado 6 bits (multiplicado por 64)
    wire [9:0] pico_volume = {nivel_volume, 6'b000000};

// 2. Modulação de Volume (Envelope via PWM de 50kHz)
    reg [9:0]  contador_pwm_hf;
    reg [9:0]  volume_atual;
    reg [19:0] timer_envelope;
    reg        habilitar_antigo;

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            volume_atual     <= 10'd0;
            timer_envelope   <= 20'd0;
            habilitar_antigo <= 1'b0;
            contador_pwm_hf  <= 10'd0;
        end else begin
            habilitar_antigo <= habilitar;

            if (contador_pwm_hf >= 10'd1000) 
                contador_pwm_hf <= 10'd0;
            else 
                contador_pwm_hf <= contador_pwm_hf + 1'b1;

            if (habilitar && !habilitar_antigo) begin
                // ATTACK: Em vez de fixar em 1000, inicia com o volume master selecionado
                volume_atual   <= pico_volume; 
                timer_envelope <= 20'd0;
            end 
            else if (habilitar) begin
                // DECAY/SUSTAIN
                timer_envelope <= timer_envelope + 1'b1;
                if (timer_envelope >= 20'd50_000) begin 
                    timer_envelope <= 20'd0;
                    if (volume_atual > 10'd150) 
                        volume_atual <= volume_atual - 1'b1;
                end
            end 
            else begin
                // RELEASE
                timer_envelope <= timer_envelope + 1'b1;
                if (timer_envelope >= 20'd10_000) begin
                    timer_envelope <= 20'd0;
                    if (volume_atual > 10'd0)
                        volume_atual <= volume_atual - 1'b1;
                end
            end
        end
    end

    assign buzzer = onda_quadrada & (contador_pwm_hf < volume_atual);

endmodule