// ---------------------------------------------------------------------------
// Modulo: piano_top
// Descricao: Top-Level do MVP do Piano Adaptativo. Interliga Fluxo de Dados e Controle.
// ---------------------------------------------------------------------------
module piano_top (
    input        CLOCK_50,
    input        reset_n,       // Ativo baixo
    
    // Controles pelo Waveforms (Patterns)
    input  [6:0] gpio_keys,     // 7 notas
    input        btn_modo,      // Troca os modos
    
    // Pinos Virtuais/Futuros (fixados por enquanto por não ter Hardware)
    // input  [1:0] sw_oitava, 
    // input  [3:0] sw_volume, 

    // Saídas Físicas / FPGA
    output       buzzer,        // Sai no pino pro buzzer (Onda quadrada)
    output [6:0] led_vermelho,  // Feedback de notas na placa (LEDR)
    output [6:0] hex0_estado    // Display da FPGA mostrando "0" (Livre) ou "1" (Aprendizado)
);

    wire reset = ~reset_n; // Inverte para ativo alto para os modulos internos

    // Sinais de interligação FSM <-> Fluxo de Dados
    wire fsm_modo_apr, fsm_zera_end, fsm_conta_end;
    wire fd_pulso_acerto, fd_fim_musica;
    wire [4:0] dbg_estado;

    // FSM
    unidade_controle fsm_inst (
        .clock(CLOCK_50),
        .reset(reset),
        .btn_modo(btn_modo),
        .pulso_acerto(fd_pulso_acerto),
        .fim_musica(fd_fim_musica),
        .modo_aprendizado(fsm_modo_apr),
        .zera_endereco(fsm_zera_end),
        .conta_endereco(fsm_conta_end),
        .estado_hex(dbg_estado)
    );

    // Caminho de Dados Principal
    fluxo_dados fluxo_inst (
        .clock(CLOCK_50),
        .reset(reset),
        .botoes(gpio_keys),
        .sw_oitava(2'd0), // Fixo na Oitava 5 por enquanto
        .sw_volume(4'd8), // Nao usado (PWM é 50%), mas mantém pino plugado
        .modo_aprendizado(fsm_modo_apr),
        .conta_endereco(fsm_conta_end),
        .zera_endereco(fsm_zera_end),
        .buzzer(buzzer),
        .leds(led_vermelho),
        .pulso_acerto(fd_pulso_acerto),
        .fim_musica(fd_fim_musica)
    );

    // Decodificador para o Display de Status
    hexa7seg disp0_inst (
        .hexa(dbg_estado),
        .display(hex0_estado)
    );

endmodule