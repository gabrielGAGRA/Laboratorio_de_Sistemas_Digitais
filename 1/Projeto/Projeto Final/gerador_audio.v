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

    // 2. Modulação de Volume (Envelope via PWM de 50kHz)
    // Clock de 50MHz / 50kHz = 1000 ciclos.
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

            // Base de tempo do PWM de volume
            if (contador_pwm_hf >= 10'd1000) 
                contador_pwm_hf <= 10'd0;
            else 
                contador_pwm_hf <= contador_pwm_hf + 1'b1;

            // Maquina de Estados Simplificada do Envelope
            if (habilitar && !habilitar_antigo) begin
                // ATTACK: Nota acabou de ser pressionada. Volume estoura em 100%.
                volume_atual   <= 10'd1000;
                timer_envelope <= 20'd0;
            end 
            else if (habilitar) begin
                // DECAY/SUSTAIN: A corda do piano perde energia com o tempo.
                timer_envelope <= timer_envelope + 1'b1;
                // Ajuste "50_000" para mudar o quão rápido o som morre enquanto segura a tecla
                if (timer_envelope >= 20'd50_000) begin 
                    timer_envelope <= 20'd0;
                    // Não deixa zerar, mantém um Sustain de 15% para a nota continuar soando
                    if (volume_atual > 10'd150) 
                        volume_atual <= volume_atual - 1'b1;
                end
            end 
            else begin
                // RELEASE: Soltou a tecla. O som não corta seco, ele apaga rapidamente.
                timer_envelope <= timer_envelope + 1'b1;
                if (timer_envelope >= 20'd10_000) begin
                    timer_envelope <= 20'd0;
                    if (volume_atual > 10'd0)
                        volume_atual <= volume_atual - 1'b1;
                end
            end
        end
    end

    // O buzzer só apita se a onda da nota estiver em alta E o ciclo de trabalho do PWM de volume permitir
    assign buzzer = onda_quadrada & (contador_pwm_hf < volume_atual);

endmodule