// ---------------------------------------------------------------------------
// Módulo: jogo_desafio_memoria  (módulo de topo)
// ---------------------------------------------------------------------------
// Integra o fluxo de dados e a unidade de controle do jogo,
// além de instanciar os decodificadores hexa-7 segmentos para
// depuração na placa FPGA.
//
// Funcionamento ATUAL do jogo:
//   O jogador observa uma sequência de cores exibida nos LEDs RGB.
//   Em seguida, reproduz a sequência usando os botões. A cada acerto
//   completo, a sequência cresce com um elemento escolhido pelo jogador.
//   O jogo termina em acerto total, erro ou timeout (se habilitado).
//
// Configuração (chaves da placa):
//   configuracao[0] – modo: 0 = completo (16 rodadas), 1 = demonstração (4 rodadas)
//   configuracao[1] – timeout: 0 = desabilitado, 1 = habilitado
// ---------------------------------------------------------------------------
module jogo_desafio_memoria (
    // -- Entradas da placa ----------------------------------------------------
    input        clock,
    input        reset,
    input        jogar,
    input  [1:0] configuracao,
    input  [3:0] botoes,

    // -- Saídas principais ----------------------------------------------------
    output [2:0] leds_rgb,
    output       ganhou,
    output       perdeu,
    output       pronto,
    output       timeout,
    output [3:0] leds,

    // -- Sinais de depuração (displays 7-seg e LEDs da placa) -----------------
    output       db_igual,
    output [6:0] db_contagem,
    output [6:0] db_memoria,
    output [6:0] db_estado,
    output [6:0] db_jogadafeita,
    output       db_clock,
    output       db_iniciar,
    output       db_enderecoIgualLimite,
    output       db_timeout,
    output       db_modo,
    output       db_configuracao,
    output       db_escrita,
    output [6:0] db_limite_rodada
);

    // UC → FD
    wire zera_endereco, conta_endereco, zera_limite, conta_limite;
    wire zeraR, registraR, enable_timeout, zera_s_timeout;
    wire registra_modo, zera_modo;
    wire conf_leds, registra_jogada, zera_s_led, enable_led;

    // FD → UC
    wire igual, jogada_feita, tem_jogada;
    wire enderecoIgualLimite, fim_jogo;
    wire s_pulso_timeout, timeout_led, fim_sequencia;
    wire s_timeout_habilitado, s_modo;

    wire [6:0] hexa0, hexa1, hexa2, hexa3, hexa5;
    wire [3:0] s_contagem, s_memoria, s_jogada, s_limite;
	 wire [4:0] s_estado;

    fluxo_dados fluxo_dados (
        .clock(clock),
        .reset(reset),
        .zera_endereco(zera_endereco),
        .conta_endereco(conta_endereco),
        .zera_limite(zera_limite),
        .conta_limite(conta_limite),
        .zeraR(zeraR),
        .registrarR(registraR),
        .zera_s_timeout(zera_s_timeout),
        .enable_timeout(enable_timeout),
        .botoes(botoes),
        .configuracao(configuracao),
        .registra_modo(registra_modo),
        .zera_modo(zera_modo),
        .conf_leds(conf_leds),
        .registra_jogada(registra_jogada),
        .zera_s_led(zera_s_led),
        .enable_led(enable_led),
        .igual(igual),
        .fim_jogo(fim_jogo),
        .enderecoIgualLimite(enderecoIgualLimite),
        .jogada_feita(jogada_feita),
        .db_tem_jogada(tem_jogada),
        .db_enable_timeout(),
        .db_contagem(s_contagem),
        .db_memoria(s_memoria),
        .db_limite(s_limite),
        .timeout(s_pulso_timeout),
        .db_jogada(s_jogada),
        .db_modo(s_modo),
        .db_configuracao(db_configuracao),
        .db_escrita(db_escrita),
        .rgb(leds_rgb),
        .leds(leds),
        .timeout_habilitado(s_timeout_habilitado),
        .timeout_led(timeout_led),
        .fim_sequencia(fim_sequencia)
    );

    unidade_controle unidade_controle (
        .clock(clock),
        .reset(reset),
        .iniciar(jogar),
        .fim_jogo(fim_jogo),
        .enderecoIgualLimite(enderecoIgualLimite),
        .jogada(jogada_feita),
        .igual(igual),
        .timeout(s_pulso_timeout),
        .timeout_habilitado(s_timeout_habilitado),
        .timeout_led(timeout_led),
        .fim_sequencia(fim_sequencia),
        .zera_endereco(zera_endereco),
        .conta_endereco(conta_endereco),
        .zera_limite(zera_limite),
        .conta_limite(conta_limite),
        .zeraR(zeraR),
        .registrarR(registraR),
        .registra_modo(registra_modo),
        .zera_modo(zera_modo),
        .acertou(ganhou),
        .errou(perdeu),
        .pronto(pronto),
        .db_estado(s_estado),
        .db_timeout(timeout),
        .zera_s_timeout(zera_s_timeout),
        .enable_timeout(enable_timeout),
        .conf_leds(conf_leds),
        .registra_jogada(registra_jogada),
        .zera_s_led(zera_s_led),
        .enable_led(enable_led)
    );

    hexa7seg HEX0 ( .hexa({1'b0, s_contagem}), .display(hexa0) );
    hexa7seg HEX1 ( .hexa({1'b0, s_memoria}),  .display(hexa1) );
    hexa7seg HEX2 ( .hexa({1'b0, s_jogada}),   .display(hexa2) );
    hexa7seg HEX3 ( .hexa({1'b0, s_limite}),   .display(hexa3) );
    hexa7seg HEX5 ( .hexa(s_estado),           .display(hexa5) );

    assign db_iniciar              = jogar;
    assign db_contagem             = hexa0;
    assign db_memoria              = hexa1;
    assign db_jogadafeita          = hexa2;
    assign db_limite_rodada        = hexa3;
    assign db_estado               = hexa5;
    assign db_enderecoIgualLimite  = enderecoIgualLimite;
    assign db_igual                = igual;
    assign db_clock                = clock;
    assign db_modo                 = s_modo;
    assign db_timeout              = timeout;

endmodule