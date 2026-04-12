// ---------------------------------------------------------------------------
// Módulo: fluxo_dados
// ---------------------------------------------------------------------------
// Caminho dos dados do jogo. Interliga memória, contadores,
// comparadores, temporizadores e registradores sob comando da
// unidade de controle.
// ---------------------------------------------------------------------------
module fluxo_dados (
    // -- Sinais globais -------------------------------------------------------
    input        clock,
    input        reset,

    // -- Comandos vindos da unidade de controle -------------------------------
    input        zera_endereco,
    input        conta_endereco,
    input        zera_limite,
    input        conta_limite,
    input        zeraR,
    input        registrarR,
    input        zera_s_timeout,
    input        enable_timeout,
    input        registra_modo,
    input        zera_modo,
    input        conf_leds,        // 1 = exibe cor no RGB; 0 = LED apagado
    input        registra_jogada,  // habilita a escrita na RAM
    input        zera_s_led,
    input        enable_led,

    // -- Entradas do jogador --------------------------------------------------
    input  [3:0] botoes,
    input  [1:0] configuracao,     // [0] modo, [1] timeout habilitado

    // -- Flags de status para a unidade de controle ---------------------------
    output       igual,
    output       fim_jogo,
    output       enderecoIgualLimite,
    output       jogada_feita,
    output       timeout,
    output       timeout_led,
    output       fim_sequencia,
    output       timeout_habilitado,

    // -- Saída RGB para os LEDs da placa --------------------------------------
    output [2:0] rgb,
    output [3:0] leds,

    // -- Depuração ------------------------------------------------------------
    output       db_tem_jogada,
    output       db_enable_timeout,
    output [3:0] db_contagem,
    output [3:0] db_memoria,
    output [3:0] db_limite,
    output [3:0] db_jogada,
    output       db_modo,
    output       db_configuracao,
    output       db_escrita
);

    wire [3:0] s_endereco;
    wire [3:0] s_dado;           // cor esperada (valor lido da RAM)
    wire [3:0] s_botoes;
    wire [3:0] s_limite;
    wire [3:0] s_jogo_limite;
    wire       s_tem_jogada;
    wire       s_modo;           // 0 = completo (16 rodadas), 1 = demonstração (4 rodadas)
    wire       s_timeout_habilitado;
    wire [2:0] s_rgb;

    assign s_tem_jogada      = |botoes;
    assign db_tem_jogada     = s_tem_jogada;
    assign db_enable_timeout = enable_timeout;

    // configuracao[0] = modo, configuracao[1] = timeout habilitado
    registrador_1 reg_modo (
        .clock(clock),
        .clear(zera_modo),
        .enable(registra_modo),
        .D(configuracao[0]),
        .Q(s_modo)
    );

    registrador_1 reg_timeout_hab (
        .clock(clock),
        .clear(zera_modo),
        .enable(registra_modo),
        .D(configuracao[1]),
        .Q(s_timeout_habilitado)
    );

    assign s_jogo_limite = (s_modo == 1'b0) ? 4'b1111   // completo: 16 rodadas
                                            : 4'b0011;  // demonstração: 4 rodadas

    comparador_85 compFimRodada (
        .A(s_endereco), .B(s_limite),
        .ALBi(1'b0), .AGBi(1'b0), .AEBi(1'b1),
        .AEBo(enderecoIgualLimite),
        .ALBo(), .AGBo()
    );

    comparador_85 compFimJogo (
        .A(s_limite), .B(s_jogo_limite),
        .ALBi(1'b0), .AGBi(1'b0), .AEBi(1'b1),
        .AEBo(fim_jogo),
        .ALBo(), .AGBo()
    );

    comparador_85 comparador (
        .A(s_dado), .B(s_botoes),
        .ALBi(1'b0), .AGBi(1'b0), .AEBi(1'b1),
        .AEBo(igual)
    );

    edge_detector detector (
        .clock(clock),
        .reset(reset),
        .sinal(s_tem_jogada),
        .pulso(jogada_feita)
    );

    contador_m #( .M(5000), .N(13) ) contador_timeout (
        .clock(clock),
        .zera_as(reset),
        .zera_s(zera_s_timeout),
        .conta(enable_timeout),
        .Q(),
        .fim(timeout),
        .meio()
    );

    contador_m #( .M(2000), .N(11) ) contador_led (
        .clock(clock),
        .zera_as(reset),
        .zera_s(zera_s_led),
        .conta(enable_led),
        .Q(),
        .fim(timeout_led),
        .meio()
    );

    contador_163 contador_addr (
        .clock(clock),
        .clr(~zera_endereco),
        .ld(1'b1), .ent(1'b1),
        .enp(conta_endereco),
        .D(4'b0000),
        .Q(s_endereco),
        .rco()
    );

    contador_163 contLmt (
        .clock(clock),
        .clr(~zera_limite),
        .ld(1'b1), .ent(1'b1),
        .enp(conta_limite),
        .D(4'b0000),
        .Q(s_limite),
        .rco()
    );

    registrador_4 registrador (
        .clock(clock),
        .clear(zeraR),
        .enable(registrarR),
        .D(botoes),
        .Q(s_botoes)
    );

    // RAM inicializada por arquivo (ram_init.txt)
    sync_ram_16x4_file memoria (
        .clk(clock),
        .we(registra_jogada),
        .data(botoes),
        .addr(s_endereco),
        .q(s_dado)
    );

    cores_rgb converter_cor (
        .codigo(s_dado),
        .leds_rgb(s_rgb)
    );

    assign leds = s_dado;

    mux2x1_n #(
        .BITS(3)
    ) mux_rgb (
        .D0(3'b000),
        .D1(s_rgb),
        .SEL(conf_leds),
        .OUT(rgb)
    );

    assign db_contagem        = s_endereco;
    assign db_jogada          = s_botoes;
    assign db_memoria         = s_dado;
    assign db_limite          = s_limite;
    assign db_modo            = s_modo;
    assign db_configuracao    = s_timeout_habilitado;
    assign db_escrita         = registra_jogada;
    assign fim_sequencia      = enderecoIgualLimite;
    assign timeout_habilitado = s_timeout_habilitado;

endmodule