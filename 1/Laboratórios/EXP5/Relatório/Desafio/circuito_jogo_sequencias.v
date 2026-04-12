module circuito_jogo_sequencias(
    input        clock,
    input        reset,
    input        jogar,     // jogar (iniciar)
    input        modo,
    input  [3:0] botoes,
    input        conf_leds,
    output [3:0] leds,
    output       pronto,
    output       ganhou,    // output ganhou
    output       perdeu,    // output perdeu
    output       timeout,
    //db
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
    output [6:0] db_limite_view // ver a rodada nos displays
    output [2:0] rgb,
    wire [2:0] s_rgb;
);

    wire zera_endereco, conta_endereco, zera_limite, conta_limite;
    wire zeraR, registraR, igual, tem_jogada, jogada_feita, enable_timeout, zera_s_timeout, s_pulso_timeout;
    wire registra_modo, zera_modo, s_modo;
    wire enderecoIgualLimite, fim_jogo;
    wire [6:0] hexa0, hexa1, hexa2, hexa3, hexa5;
    wire [3:0] s_contagem, s_memoria, s_estado, s_jogada, s_limite;

    fluxo_dados fluxo_dados(
        .clock(clock),
        .reset(reset),
        .botoes(botoes),
        .modo(modo),
        .zeraR(zeraR),
        .registrarR(registraR),
        .zera_endereco(zera_endereco),
        .conta_endereco(conta_endereco),
        .zera_limite(zera_limite),
        .conta_limite(conta_limite),
        .registra_modo(registra_modo),
        .zera_modo(zera_modo),
        .enable_timeout(enable_timeout),
        .zera_s_timeout(zera_s_timeout),
        .igual(igual),
        .enderecoIgualLimite(enderecoIgualLimite),
        .fim_jogo(fim_jogo),
        .db_contagem(s_contagem),
        .db_jogada(s_jogada),
        .db_memoria(s_memoria),
        .db_limite(s_limite),
        .jogada_feita(jogada_feita),
        .db_tem_jogada(tem_jogada),
        .db_enable_timeout(),
        .timeout(s_pulso_timeout),
        .db_modo(s_modo)
    );

    unidade_controle unidade_controle(
        .clock(clock),
        .reset(reset),
        .iniciar(jogar),              
        .fim_jogo(fim_jogo),
        .enderecoIgualLimite(enderecoIgualLimite),
        .jogada(jogada_feita),
        .igual(igual),
        .zera_endereco(zera_endereco),
        .conta_endereco(conta_endereco),
        .zera_limite(zera_limite),
        .conta_limite(conta_limite),
        .zeraR(zeraR),
        .registrarR(registraR),
        .registra_modo(registra_modo),
        .zera_modo(zera_modo),
        .pronto(pronto),
        .db_estado(s_estado),
        .errou(perdeu),                
        .acertou(ganhou),              
        .zera_s_timeout(zera_s_timeout),
        .timeout(s_pulso_timeout),
        .db_timeout(timeout),
        .enable_timeout(enable_timeout)
    );

    corzinha converter_cor (
        .codigo(s_memoria),
        .rgb(s_rgb)
    );

    hexa7seg HEX0 ( .hexa(s_contagem), .display(hexa0) );
    hexa7seg HEX1 ( .hexa(s_memoria),  .display(hexa1) );
    hexa7seg HEX2 ( .hexa(s_jogada),   .display(hexa2) );
    hexa7seg HEX3 ( .hexa(s_limite),   .display(hexa3) );
    hexa7seg HEX5 ( .hexa(s_estado),   .display(hexa5) );

    assign db_iniciar = jogar;
    assign db_contagem = hexa0; 
    assign db_memoria = hexa1;
    assign db_jogadafeita = hexa2;
    assign db_limite_view = hexa3;
    assign db_estado = hexa5;
    assign db_enderecoIgualLimite = enderecoIgualLimite; 
    assign db_igual = igual;
    assign db_clock = clock;
    assign leds = s_memoria;
    assign db_modo = s_modo;
    assign db_timeout = timeout;

    assign leds = (conf_leds == 1'b0) ? s_memoria : 4'b0000;
    assign rgb  = (conf_leds == 1'b1) ? s_rgb : 3'b000;

endmodule