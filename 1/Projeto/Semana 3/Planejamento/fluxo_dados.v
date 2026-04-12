// ---------------------------------------------------------------------------
// Modulo: fluxo_dados
// Descricao: Caminho de dados unificado para Modo Livre e Aprendizado.
// ---------------------------------------------------------------------------
module fluxo_dados #(
    parameter DEBOUNCE_NOTAS = 100_000, // 2ms pros botoes pequenos de tecla
    parameter DEBOUNCE_MODO  = 500_000 //10ms pros botos grandes de modo
) (
    input        clock,
    input        reset,

    // -- Entradas Físicas  --
    input  [6:0] botoes,       // 7 notas
    input        btn_modo,     // Troca de modo
    input        btn_musica,   // Troca de musica
    input        btn_intensidade, // Botao ciclico da intensidade do LED
    input  [1:0] sw_oitava,    // Switches de aumentar/reduzir oitava

    // -- Unidade de Controle --
    input        modo_aprendizado, // 1 = Aprendizado, 0 = Livre
    input        conta_endereco,
    input        zera_endereco,

    // -- Saídas Físicas --
    output       buzzer,
    output [6:0] leds,

    // -- Status para a Unidade de Controle e Top-Level --
    output       mudou_modo,       // Pulso de troca de modo
    output       tem_nota_ativa,  
    output       acerto_nota,      
    output       fim_musica,       
    output [10:0] s_endereco_ram,  
    output [2:0] s_id_para_led,    // ID da nota atual
    output [1:0] out_sel_musica,   // Seletor pro display
    output [6:0] db_botoes,        // Botoes debounced para os LEDs
    output       pwm_out           // Sinal PWM para LED
);

    wire [6:0] s_botoes_db;
    wire s_btn_modo_db, s_btn_musica_db, s_btn_intensidade_db;
    
    // Debouncers
    debounce #(.WIDTH(7), .TEMPO_FILTRO(DEBOUNCE_NOTAS)) db_notas (
        .clock(clock), .reset(reset), .in(botoes), .out(s_botoes_db)
    );
    debounce #(.WIDTH(1), .TEMPO_FILTRO(DEBOUNCE_MODO)) db_modo (
        .clock(clock), .reset(reset), .in(btn_modo), .out(s_btn_modo_db)
    );
    debounce #(.WIDTH(1), .TEMPO_FILTRO(DEBOUNCE_MODO)) db_musica (
        .clock(clock), .reset(reset), .in(btn_musica), .out(s_btn_musica_db)
    );
    debounce #(.WIDTH(1), .TEMPO_FILTRO(DEBOUNCE_MODO)) db_intensidade (
        .clock(clock), .reset(reset), .in(btn_intensidade), .out(s_btn_intensidade_db)
    );

    // Edge Detectors
    edge_detector ed_modo (
        .clock(clock), .reset(reset), .sinal(s_btn_modo_db), .pulso(mudou_modo)
    );
    wire s_btn_musica_pulse;
    edge_detector ed_musica (
        .clock(clock), .reset(reset), .sinal(s_btn_musica_db), .pulso(s_btn_musica_pulse)
    );
    wire s_btn_intensidade_pulse;
    edge_detector ed_intensidade (
        .clock(clock), .reset(reset), .sinal(s_btn_intensidade_db), .pulso(s_btn_intensidade_pulse)
    );

    // Registrador seletor de musica
    wire [1:0] s_sel_musica;
    contador_m #(.M(4), .N(2)) contador_musica (
        .clock(clock),
        .zera_as(1'b0),
        .zera_s(reset),
        .conta(s_btn_musica_pulse),
        .Q(s_sel_musica),
        .fim(),
        .meio()
    );

    assign out_sel_musica = s_sel_musica;
    assign db_botoes = s_botoes_db;

    wire [2:0] s_nota_tocada;
    wire       s_tem_nota;
    wire [17:0] s_n_ticks;
    
    wire [3:0] s_dado_ram;
    wire [2:0] s_nota_esperada = s_dado_ram[2:0];

    // 1. Logica de Áudio
    logica_notas_prioridade logic_inst (
        .clock(clock), .reset(reset),
        .botoes(s_botoes_db), .nota_id(s_nota_tocada), .tem_nota(s_tem_nota)
    );

    frequency_lut lut_inst (
        .nota_id(s_nota_tocada), 
        .n_ticks(s_n_ticks)
    );

    gerador_audio audio_inst (
        .clock(clock), .reset(reset),
        .fim_contagem(s_n_ticks), .habilitar(s_tem_nota),
        .buzzer(buzzer)
    );

    // 2. Logica de Memória e Endereçamento
    wire cont_fim;
    contador_m #(
        .M(2048), // Tamanho da musica maximo
        .N(11)
    ) contador_addr (
        .clock(clock),
        .zera_as(1'b0),
        .zera_s(zera_endereco),
        .conta(conta_endereco),
        .Q(s_endereco_ram),
        .fim(cont_fim),
        .meio()
    );

    wire [3:0] s_dado_ram1, s_dado_ram2;

    sync_rom #(
        .DATA_WIDTH(4),
        .ADDR_WIDTH(11),
        .INIT_FILE("do_re_mi.txt")
    ) memoria1 (
        .clock(clock),
        .address(s_endereco_ram),
        .data_out(s_dado_ram1)
    );

    sync_rom #(
        .DATA_WIDTH(4),
        .ADDR_WIDTH(11),
        .INIT_FILE("au_clair_de_la_lune.txt")
    ) memoria2 (
        .clock(clock),
        .address(s_endereco_ram),
        .data_out(s_dado_ram2)
    );

    // Mux de musicas
    assign s_dado_ram = (s_sel_musica == 2'd0) ? s_dado_ram1 : s_dado_ram2;

    // Multiplexador de LEDs: No Modo Aprendizado, mostra a nota vinda da memoria. No Modo Livre, mostra a nota vinda do teclado (botoes).
    assign s_id_para_led = (modo_aprendizado) ? s_nota_esperada : s_nota_tocada;

    // 3. Logica Visual e Comparação
    decodificador_cifra decoder_cifra_inst (
        .nota_id(s_id_para_led),
        .display(leds)
    );

    // O sinal de match fica em nível alto enquanto a nota certa for segurada
    wire s_match_cru = (s_nota_tocada == s_nota_esperada) && s_tem_nota && modo_aprendizado;

    // Exportação dos níveis lógicos para a máquina de estado
    assign tem_nota_ativa = s_tem_nota;
    assign acerto_nota = s_match_cru;

    // 4. Modulação de LED (PWM)
    // Contador ciclico de Estado de Intensidade (0 a 4)
    reg [2:0] estado_intensidade;
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            estado_intensidade <= 3'd0; // Começa em 100%
        end else if (s_btn_intensidade_pulse) begin
            if (estado_intensidade == 3'd4)
                estado_intensidade <= 3'd0;
            else
                estado_intensidade <= estado_intensidade + 1'b1;
        end
    end

    // Mapeamento do Duty Cycle
    reg [3:0] s_duty_cycle;
    always @(*) begin
        case (estado_intensidade)
            3'd0: s_duty_cycle = 4'hF; // 100%
            3'd1: s_duty_cycle = 4'hC; // ~75%
            3'd2: s_duty_cycle = 4'h8; // ~50%
            3'd3: s_duty_cycle = 4'h4; // ~25%
            3'd4: s_duty_cycle = 4'h0; // 0%
            default: s_duty_cycle = 4'hF; // Fallback para 100%
        endcase
    end

    gerador_pwm pwm_inst (
        .clock(clock),
        .reset(reset),
        .duty_cycle(s_duty_cycle),
        .pwm_out(pwm_out)
    );

endmodule