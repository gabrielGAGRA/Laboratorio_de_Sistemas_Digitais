module teste_audio_piano (
    input        CLOCK_50,   // Pin AF14
    input        reset_n,    // KEY0 da placa (reset e ativo baixo)
    input  [6:0] gpio_keys,  // 7 pinos vindos do Waveforms (Dó a Si)
    output       buzzer      // Pino de saída para o Buzzer Passivo
);

    wire [2:0] s_nota_id;
    wire [17:0] s_n_ticks;
    wire s_tem_nota;
    wire reset = !reset_n;

    // 1. Lógica de Prioridade (Override) usa agora os botões diretamente
    logica_notas_prioridade logic_inst (
        .clock(CLOCK_50),
        .reset(reset),
        .botoes(gpio_keys),
        .nota_id(s_nota_id),
        .tem_nota(s_tem_nota)
    );

    // 2. Tabela de Frequências (Software/LUT)
    frequency_lut lut_inst (
        .nota_id(s_nota_id),
        .n_ticks(s_n_ticks)
    );

    // 3. Gerador de Áudio (PWM 50%)
    gerador_audio audio_inst (
        .clock(CLOCK_50),
        .reset(reset),
        .fim_contagem(s_n_ticks),
        .habilitar(s_tem_nota),
        .buzzer(buzzer)
    );

endmodule