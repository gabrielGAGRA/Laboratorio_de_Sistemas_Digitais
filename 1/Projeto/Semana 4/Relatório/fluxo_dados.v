// ---------------------------------------------------------------------------
// Modulo: fluxo_dados
// Descricao: Caminho de dados unificado para Modo Livre e Aprendizado.
// ---------------------------------------------------------------------------
module fluxo_dados #(
    parameter DEBOUNCE_TECLA = 100_000, // Aqui a latencia é importante. Medimos quase 1ms, usaremos 2ms.
    parameter DEBOUNCE_CONTROLE  = 400_000 // Medimos 4ms de debounce, usaremos 8ms por segurança 
) (
    input        clock,
    input        reset,

    // -- Entradas Físicas  --
    input  [6:0] botoes,          // 7 notas
    input        btn_modo,        // Troca de modo
    input        btn_musica,      // Troca de musica
    input        btn_intensidade, // Botao ciclico da intensidade do LED
    input        btn_oitava_up,
    input        btn_oitava_down,
    input        btn_sustenido,

    // -- Unidade de Controle --
    input  [1:0] modo_ativo, // 0=Livre, 1=Apr, 2=Gravacao
    input        escreve_ram,
    input        conta_endereco,
    input        zera_endereco,

    // -- Saídas Físicas --
    output       buzzer,
    output [6:0] leds,

    // -- Status --
    output       mudou_modo,       
    output       tem_nota_ativa,  
    output       acerto_nota,      
    output       fim_musica,       
    output [9:0] s_endereco_ram,  
    output [2:0] s_id_para_led,    
    output [3:0] out_sel_musica,   
    output [6:0] db_botoes,        
    output       pwm_out,
    output [2:0] oitava_atual,
    output       sustenido_atual,
    output       led_oitava_up,
    output       led_oitava_down
);

    wire [6:0] s_botoes_db;
    wire s_btn_modo_db, s_btn_musica_db, s_btn_intensidade_db;
    wire s_btn_oitava_up_db, s_btn_oitava_down_db, s_btn_sustenido_db;
    
    // Debouncers (TECLA)
    debounce #(.WIDTH(7), .TEMPO_FILTRO(DEBOUNCE_TECLA)) db_notas (
        .clock(clock), .reset(reset), .in(botoes), .out(s_botoes_db)
    );
    debounce #(.WIDTH(1), .TEMPO_FILTRO(DEBOUNCE_TECLA)) db_sustenido (
        .clock(clock), .reset(reset), .in(btn_sustenido), .out(s_btn_sustenido_db)
    );

    // Debouncers (CONTROLE)
    debounce #(.WIDTH(1), .TEMPO_FILTRO(DEBOUNCE_CONTROLE)) db_modo (
        .clock(clock), .reset(reset), .in(btn_modo), .out(s_btn_modo_db)
    );
    debounce #(.WIDTH(1), .TEMPO_FILTRO(DEBOUNCE_CONTROLE)) db_musica (
        .clock(clock), .reset(reset), .in(btn_musica), .out(s_btn_musica_db)
    );
    debounce #(.WIDTH(1), .TEMPO_FILTRO(DEBOUNCE_CONTROLE)) db_intensidade (
        .clock(clock), .reset(reset), .in(btn_intensidade), .out(s_btn_intensidade_db)
    );
    debounce #(.WIDTH(1), .TEMPO_FILTRO(DEBOUNCE_CONTROLE)) db_oitava_up (
        .clock(clock), .reset(reset), .in(btn_oitava_up), .out(s_btn_oitava_up_db)
    );
    debounce #(.WIDTH(1), .TEMPO_FILTRO(DEBOUNCE_CONTROLE)) db_oitava_down (
        .clock(clock), .reset(reset), .in(btn_oitava_down), .out(s_btn_oitava_down_db)
    );

    // Edge Detectors
    edge_detector ed_modo (.clock(clock), .reset(reset), .sinal(s_btn_modo_db), .pulso(mudou_modo));
    
    wire s_btn_musica_pulse;
    edge_detector ed_musica (.clock(clock), .reset(reset), .sinal(s_btn_musica_db), .pulso(s_btn_musica_pulse));
    
    wire s_btn_intensidade_pulse;
    edge_detector ed_intensidade (.clock(clock), .reset(reset), .sinal(s_btn_intensidade_db), .pulso(s_btn_intensidade_pulse));
    
    wire s_btn_oitava_up_pulse;
    edge_detector ed_oit_up (.clock(clock), .reset(reset), .sinal(s_btn_oitava_up_db), .pulso(s_btn_oitava_up_pulse));
    
    wire s_btn_oitava_down_pulse;
    edge_detector ed_oit_down (.clock(clock), .reset(reset), .sinal(s_btn_oitava_down_db), .pulso(s_btn_oitava_down_pulse));

    // Seletor de musica
    wire [3:0] s_sel_musica;
    contador_m #(.M(16), .N(4)) contador_musica (
        .clock(clock), .zera_as(1'b0), .zera_s(reset), .conta(s_btn_musica_pulse),
        .Q(s_sel_musica), .fim(), .meio()
    );

    assign out_sel_musica = s_sel_musica;
    assign db_botoes = s_botoes_db;

    // Gerenciador de oitava livre
    wire [2:0] s_oitava_livre;
    guarda_oitava oitava_inst (
        .clock(clock), .reset(reset),
        .btn_up_pulse(s_btn_oitava_up_pulse), .btn_down_pulse(s_btn_oitava_down_pulse),
        .oitava_atual(s_oitava_livre)
    );

    wire [2:0] s_nota_tocada;
    wire       s_tem_nota;
    wire [17:0] s_n_ticks;
    
    wire [6:0] s_dado_ram;
    wire [2:0] s_nota_esperada = s_dado_ram[2:0]; 
    wire s_sustenido_esperado = s_dado_ram[3];
    wire [2:0] s_oitava_esperada = s_dado_ram[6:4];

    wire [2:0] s_oitava_atual_uso = (modo_ativo == 2'd1) ? s_oitava_esperada : s_oitava_livre;
    wire s_sustenido_atual_uso = ((modo_ativo == 2'd1)) ? s_sustenido_esperado : s_btn_sustenido_db;

    assign oitava_atual = s_oitava_atual_uso;
    assign sustenido_atual = s_sustenido_atual_uso;
    assign led_oitava_up = ((modo_ativo == 2'd1)) ? s_led_up : 1'b0;
    assign led_oitava_down = ((modo_ativo == 2'd1)) ? s_led_down : 1'b0;

    // 1. Logica de Áudio
    logica_notas_prioridade logic_inst (
        .clock(clock), .reset(reset),
        .botoes(s_botoes_db), .nota_id(s_nota_tocada), .tem_nota(s_tem_nota)
    );

    frequency_lut lut_inst (
        .nota_id(s_nota_tocada), 
        .sustenido(s_sustenido_atual_uso),
        .oitava(s_oitava_atual_uso),
        .n_ticks(s_n_ticks)
    );

    gerador_audio audio_inst (
        .clock(clock), .reset(reset),
        .fim_contagem(s_n_ticks), .habilitar(s_tem_nota),
        .buzzer(buzzer)
    );

    // 2. Logica de Memória e Endereçamento
    wire cont_fim;
    contador_m #(.M(1024), .N(10)) contador_addr (
        .clock(clock), .zera_as(1'b0), .zera_s(zera_endereco), .conta(conta_endereco),
        .Q(s_endereco_ram), .fim(cont_fim), .meio()
    );

    wire [6:0] d_ram0, d_ram1, d_ram2, d_ram3, d_ram4, d_ram5, d_ram6, d_ram7;
    wire [6:0] d_ram8, d_ram9, d_ram10, d_ram11, d_ram12, d_ram13, d_ram14;

    sync_rom #(.DATA_WIDTH(7), .ADDR_WIDTH(10), .INIT_FILE("Musicas/do_re_mi.txt")) mem0 (.clock(clock), .address(s_endereco_ram), .data_out(d_ram0));
    sync_rom #(.DATA_WIDTH(7), .ADDR_WIDTH(10), .INIT_FILE("Musicas/zelda.txt"))    mem1 (.clock(clock), .address(s_endereco_ram), .data_out(d_ram1));
    sync_rom #(.DATA_WIDTH(7), .ADDR_WIDTH(10), .INIT_FILE("Musicas/Spiderman.txt")) mem2 (.clock(clock), .address(s_endereco_ram), .data_out(d_ram2));
    sync_rom #(.DATA_WIDTH(7), .ADDR_WIDTH(10), .INIT_FILE("Musicas/au_clair_de_la_lune.txt")) mem3 (.clock(clock), .address(s_endereco_ram), .data_out(d_ram3));
    sync_rom #(.DATA_WIDTH(7), .ADDR_WIDTH(10), .INIT_FILE("Musicas/bad_romance.txt")) mem4 (.clock(clock), .address(s_endereco_ram), .data_out(d_ram4));
    sync_rom #(.DATA_WIDTH(7), .ADDR_WIDTH(10), .INIT_FILE("Musicas/do_i_wanna_know.txt")) mem5 (.clock(clock), .address(s_endereco_ram), .data_out(d_ram5));
    sync_rom #(.DATA_WIDTH(7), .ADDR_WIDTH(10), .INIT_FILE("Musicas/golden.txt")) mem6 (.clock(clock), .address(s_endereco_ram), .data_out(d_ram6));
    sync_rom #(.DATA_WIDTH(7), .ADDR_WIDTH(10), .INIT_FILE("Musicas/golden_wind.txt")) mem7 (.clock(clock), .address(s_endereco_ram), .data_out(d_ram7));
    sync_rom #(.DATA_WIDTH(7), .ADDR_WIDTH(10), .INIT_FILE("Musicas/harry_potter.txt")) mem8 (.clock(clock), .address(s_endereco_ram), .data_out(d_ram8));
    sync_rom #(.DATA_WIDTH(7), .ADDR_WIDTH(10), .INIT_FILE("Musicas/minecraft.txt")) mem9 (.clock(clock), .address(s_endereco_ram), .data_out(d_ram9));
    sync_rom #(.DATA_WIDTH(7), .ADDR_WIDTH(10), .INIT_FILE("Musicas/minecraft2.txt")) mem10 (.clock(clock), .address(s_endereco_ram), .data_out(d_ram10));
    sync_rom #(.DATA_WIDTH(7), .ADDR_WIDTH(10), .INIT_FILE("Musicas/miranha.txt")) mem11 (.clock(clock), .address(s_endereco_ram), .data_out(d_ram11));
    sync_rom #(.DATA_WIDTH(7), .ADDR_WIDTH(10), .INIT_FILE("Musicas/sans.txt")) mem12 (.clock(clock), .address(s_endereco_ram), .data_out(d_ram12));
    sync_rom #(.DATA_WIDTH(7), .ADDR_WIDTH(10), .INIT_FILE("Musicas/take_on_me.txt")) mem13 (.clock(clock), .address(s_endereco_ram), .data_out(d_ram13));
    sync_rom #(.DATA_WIDTH(7), .ADDR_WIDTH(10), .INIT_FILE("Musicas/Interestelar.txt")) mem14 (.clock(clock), .address(s_endereco_ram), .data_out(d_ram14));


    wire [6:0] d_ram15;
    wire [6:0] nota_paragravar = {s_oitava_livre, s_btn_sustenido_db, s_nota_tocada};
    
    sync_ram #(.DATA_WIDTH(7), .ADDR_WIDTH(10)) mem_gravacao (
        .clock(clock), 
        .we(escreve_ram), 
        .address(s_endereco_ram), 
        .data_in(nota_paragravar), 
        .data_out(d_ram15)
    );

    mux_musicas seletor_musicas_inst (
        .sel(s_sel_musica),
        .d0(d_ram0), .d1(d_ram1), .d2(d_ram2), .d3(d_ram3),
        .d4(d_ram4), .d5(d_ram5), .d6(d_ram6), .d7(d_ram7),
        .d8(d_ram8), .d9(d_ram9), .d10(d_ram10), .d11(d_ram11),
        .d12(d_ram12), .d13(d_ram13), .d14(d_ram14), .d15(d_ram15),
        .out(s_dado_ram)
    );


    assign s_id_para_led = (modo_ativo == 2'd1) ? s_nota_esperada : s_nota_tocada;

    // 3. Logica Visual e Comparação
    decodificador_cifra decoder_cifra_inst (
        .nota_id(s_id_para_led),
        .display(leds)
    );

    wire s_led_up, s_led_down;
    led_oitava indicador_erro_oitava (
        .oitava_certa(s_oitava_esperada),
        .oitava_atual(s_oitava_livre),
        .led_up(s_led_up), .led_down(s_led_down)
    );

    wire s_match_cru = (s_nota_tocada == s_nota_esperada) && (s_btn_sustenido_db == s_sustenido_esperado) && (s_oitava_livre == s_oitava_esperada) && s_tem_nota && (modo_ativo == 2'd1);

    assign tem_nota_ativa = s_tem_nota;
    assign acerto_nota = s_match_cru;

    // 4. Modulação de LED (PWM)
    reg [2:0] estado_intensidade;
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            estado_intensidade <= 3'd0;
        end else if (s_btn_intensidade_pulse) begin
            if (estado_intensidade == 3'd4) estado_intensidade <= 3'd0;
            else estado_intensidade <= estado_intensidade + 1'b1;
        end
    end

    reg [3:0] s_duty_cycle;
    always @(*) begin
        case (estado_intensidade)
            3'd0: s_duty_cycle = 4'hF; 
            3'd1: s_duty_cycle = 4'hC; 
            3'd2: s_duty_cycle = 4'h8; 
            3'd3: s_duty_cycle = 4'h4; 
            3'd4: s_duty_cycle = 4'h0; 
            default: s_duty_cycle = 4'hF;
        endcase
    end

    gerador_pwm pwm_inst (
        .clock(clock), .reset(reset), .duty_cycle(s_duty_cycle), .pwm_out(pwm_out)
    );

endmodule
