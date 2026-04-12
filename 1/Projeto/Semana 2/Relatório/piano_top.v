// ---------------------------------------------------------------------------
// Modulo: piano_top
// Descricao: Top-Level do MVP do Piano Adaptativo. Interliga Fluxo de Dados e Controle.
// ---------------------------------------------------------------------------
module piano_top #(
    parameter DEBOUNCE_NOTAS = 500_000, // 10ms a 50MHz
    parameter DEBOUNCE_MODO  = 250_000 // 5ms a 50MHz
) (
    input        CLOCK_50,
    input        reset_n,       // Ativo baixo
    input  [6:0] gpio_keys,     // 7 notas
    input        btn_modo,      // Troca os modos
    input        btn_musica,    // Troca as musicas
    
    // Pinos futuros
    // input  [1:0] sw_oitava, 
    // input  [3:0] sw_volume, 

    // Saídas Físicas
    output       buzzer,        // Sai no pino pro buzzer (Onda quadrada)
    output [6:0] led_vermelho,  // Feedback de notas na placa (LEDR)
    
    // RF_STATUS_HEX
    output [6:0] hex0_estado,   // Modo atual (0, 1, 2)
    output [6:0] hex1_oitava,   // Oitava atual (1, 2, 3)
    output [6:0] hex3_indice,   // Índice da música (Unidade)
    output [6:0] hex4_indice,   // Índice da música (Dezena)
    output [6:0] hex5_cifra     // Cifra da nota atual (A - G)
);

    wire reset = ~reset_n; // Inverte para ativo alto para os modulos internos

    // Fios Debounced
    wire [6:0] s_gpio_keys_db;
    wire       s_btn_modo_db;

    // Debouncers unificados (NF_DEBOUNCING_NIVEL)
    // Instancia generica para as teclas do piano (7 bits)
    debounce #(.WIDTH(7), .TEMPO_FILTRO(DEBOUNCE_NOTAS)) db_notas (
        .clock(CLOCK_50),
        .reset(reset),
        .in(gpio_keys),
        .out(s_gpio_keys_db)
    );

    // Instancia generica para o botao de modo (1 bit)
    debounce #(.WIDTH(1), .TEMPO_FILTRO(DEBOUNCE_MODO)) db_modo (
        .clock(CLOCK_50),
        .reset(reset),
        .in(btn_modo),
        .out(s_btn_modo_db)
    );

    // Instancia generica para o botao de musica (1 bit)
    debounce #(.WIDTH(1), .TEMPO_FILTRO(DEBOUNCE_MODO)) db_musica (
        .clock(CLOCK_50),
        .reset(reset),
        .in(btn_musica),
        .out(s_btn_musica_db)
    );

    // Edge detector para o botao de musica
    wire s_btn_musica_pulse;
    edge_detector ed_musica (
        .clock(CLOCK_50),
        .reset(reset),
        .sinal(s_btn_musica_db),
        .pulso(s_btn_musica_pulse)
    );

    // Seletor de musica
    reg [1:0] s_sel_musica;
    always @(posedge CLOCK_50 or posedge reset) begin
        if (reset) begin
            s_sel_musica <= 2'd0;
        end else if (s_btn_musica_pulse) begin
            s_sel_musica <= s_sel_musica + 1; // Avanca a musica
        end
    end

    // Sinais de interligação FSM <-> Fluxo de Dados
    wire fsm_modo_apr, fsm_zera_end, fsm_conta_end;
    wire fd_tem_nota_ativa, fd_acerto_nota, fd_fim_musica;
    wire [4:0] dbg_estado;
    wire [10:0] fd_endereco_ram;
    wire [2:0] fd_id_nota;

    // FSM (RF_MODOS)
    unidade_controle fsm_inst (
        .clock(CLOCK_50),
        .reset(reset),
        .btn_modo(s_btn_modo_db),
        .tem_nota_ativa(fd_tem_nota_ativa),
        .acerto_nota(fd_acerto_nota),
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
        .botoes(s_gpio_keys_db),
        .sw_oitava(2'd0), 
        .sw_volume(4'd8), // Nao usado, PWM é 50%
        .sel_musica(s_sel_musica),
        .modo_aprendizado(fsm_modo_apr),
        .conta_endereco(fsm_conta_end),
        .zera_endereco(fsm_zera_end),
        .buzzer(buzzer),
        .leds(hex5_cifra),
        .tem_nota_ativa(fd_tem_nota_ativa),
        .acerto_nota(fd_acerto_nota),
        .fim_musica(fd_fim_musica),
        .s_endereco_ram(fd_endereco_ram),
        .s_id_para_led(fd_id_nota)
    );

    // ==========================================
    // DECODIFICADORES PARA DISPLAYS (RF_STATUS_HEX)
    // ==========================================

    // HEX0: Modo atual (0=Inicio, 1=Livre, 2=Aprendizado)
    hexa7seg disp0_inst (
        .hexa(dbg_estado),
        .display(hex0_estado)
    );

    // HEX1: Oitava atual (fixamos exibir o valor 5 no display baseando na Oitava 5 central do Verilog)
    hexa7seg disp1_inst (
        .hexa(5'h2), // Valor fixado em 5 para reprensentar Dó5
        .display(hex1_oitava)
    );

    // HEX3 e HEX4: Índice da música
    wire [4:0] uni_idx = (s_sel_musica + 1) % 10;
    wire [4:0] dez_idx = ((s_sel_musica + 1) / 10) % 10;

    hexa7seg disp3_inst (
        .hexa(uni_idx),
        .display(hex3_indice)
    );

    hexa7seg disp4_inst (
        .hexa(dez_idx),
        .display(hex4_indice)
    );

    // HEX5 é acionado diretamente pela saída leds cifra do fluxo_dados. 
    
    // Multiplexador para acender LED pela nota pressionada (Livre) ou pela nota aguardada da RAM (Aprendizado)
    assign led_vermelho = (fsm_modo_apr && fd_id_nota != 0) ? (7'b0000001 << (fd_id_nota - 1)) : gpio_keys;

endmodule
