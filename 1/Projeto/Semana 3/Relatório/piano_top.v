// ---------------------------------------------------------------------------
// Modulo: piano_top
// Descricao: Top-Level do MVP do Piano Adaptativo. Interliga Fluxo de Dados e Controle.
// ---------------------------------------------------------------------------
module piano_top #(
    parameter DEBOUNCE_TECLA = 500_000, // 10ms 
    parameter DEBOUNCE_CONTROLE  = 250_000 // 5ms
) (
    input        CLOCK_50,
    input        reset_n,       // Ativo em baixo
    input  [6:0] gpio_keys,     
    input        btn_modo,      
    input        btn_musica,    
    input        btn_intensidade, // LED (PWM)
    input        btn_oitava_up,
    input        btn_oitava_down,
    input        btn_sustenido,
    
    // Saídas Físicas
    output       buzzer,        // Sai no pino pro buzzer (Onda quadrada)
    output [6:0] led_vermelho,  // Feedback de notas em LEDR
    output       led_sustenido,   // 1 LED para sustenido
    output       led_oitava_up,   // 1 LED para oitava up
    output       led_oitava_down, // 1 LED para oitava down
    
    // RF_STATUS_HEX
    output [6:0] hex5_modo,
    output [6:0] hex4_oitava,
    output [6:0] hex3_musica_dezena,
    output [6:0] hex2_musica_unidade,
    output [6:0] hex1_nota,
    output [6:0] hex0_sustenido
);

    wire reset = ~reset_n; // Inverte para ativo alto para os modulos internos

    // Sinais UC <-> Fluxo de Dados
    wire fsm_modo_apr, fsm_zera_end, fsm_conta_end;
    wire fd_tem_nota_ativa, fd_acerto_nota, fd_fim_musica;
    wire [4:0] dbg_estado;
    wire [9:0] fd_endereco_ram;
    wire [2:0] fd_id_nota;
    wire [3:0] s_sel_musica;
    wire [6:0] s_db_botoes;
    wire fd_mudou_modo;
    wire s_pwm_out;

    // UC (RF_MODOS)
    unidade_controle fsm_inst (
        .clock(CLOCK_50),
        .reset(reset),
        .mudou_modo(fd_mudou_modo),
        .tem_nota_ativa(fd_tem_nota_ativa),
        .acerto_nota(fd_acerto_nota),
        .fim_musica(fd_fim_musica),
        .modo_aprendizado(fsm_modo_apr),
        .zera_endereco(fsm_zera_end),
        .conta_endereco(fsm_conta_end),
        .estado_hex(dbg_estado)
    );


    wire [2:0] s_oitava_atual;
    wire       s_sustenido_atual;
    
    fluxo_dados #(
        .DEBOUNCE_TECLA(DEBOUNCE_TECLA),
        .DEBOUNCE_CONTROLE(DEBOUNCE_CONTROLE)
    ) fluxo_inst (
        .clock(CLOCK_50),
        .reset(reset),
        .botoes(gpio_keys),
        .btn_modo(~btn_modo),
        .btn_musica(~btn_musica),
        .btn_intensidade(~btn_intensidade),
        .btn_oitava_up(~btn_oitava_up),
        .btn_oitava_down(~btn_oitava_down),
        .btn_sustenido(~btn_sustenido),
        .modo_aprendizado(fsm_modo_apr),
        .conta_endereco(fsm_conta_end),
        .zera_endereco(fsm_zera_end),
        .buzzer(buzzer),
        .leds(hex1_nota),
        .mudou_modo(fd_mudou_modo),
        .tem_nota_ativa(fd_tem_nota_ativa),
        .acerto_nota(fd_acerto_nota),
        .fim_musica(fd_fim_musica),
        .s_endereco_ram(fd_endereco_ram),
        .s_id_para_led(fd_id_nota),
        .out_sel_musica(s_sel_musica),
        .db_botoes(s_db_botoes),
        .pwm_out(s_pwm_out),
        .oitava_atual(s_oitava_atual),
        .sustenido_atual(s_sustenido_atual),
        .led_oitava_up(led_oitava_up),
        .led_oitava_down(led_oitava_down)
    );

    // Mapeamento extra de LEDs físicos
    assign led_sustenido = fsm_modo_apr ? s_sustenido_atual : 1'b0;

    // DECODIFICADORES PARA DISPLAYS (RF_STATUS_HEX)

    // HEX5: Modo atual
    hexa7seg disp5_inst (
        .hexa({4'd0, fsm_modo_apr}),
        .display(hex5_modo)
    );

    // HEX4: Oitava atual / esperada
    hexa7seg disp4_inst (
        .hexa({2'b00, s_oitava_atual}), 
        .display(hex4_oitava)
    );

    // HEX3 e HEX2: Índice da música (Dezena e Unidade)
    wire [4:0] uni_idx = (s_sel_musica + 1) % 10;
    wire [4:0] dez_idx = ((s_sel_musica + 1) / 10) % 10;

    hexa7seg disp3_inst (
        .hexa(dez_idx),
        .display(hex3_musica_dezena)
    );

    hexa7seg disp2_inst (
        .hexa(uni_idx),
        .display(hex2_musica_unidade)
    );

    // HEX1: A nota conectada diretamente no 'leds' da instancia do fluxo_dados

    // HEX0: Sustenido
    display_sustenido disp0_inst (
        .sustenido(s_sustenido_atual),
        .display(hex0_sustenido)
    );

    // Multiplexador para acender LED vermelho (indicador da base selecionada/nota base do Cifra)
    // No modo livre os LEDs de nota não acendem. Somente no modo Aprendizado.
    wire [6:0] raw_led = (fsm_modo_apr && fd_id_nota != 0) ? (7'b0000001 << (fd_id_nota - 1)) : 7'b0000000;
    
    // Mascara com PWM para alterar itensidade
    assign led_vermelho = raw_led & {7{s_pwm_out}};

endmodule
