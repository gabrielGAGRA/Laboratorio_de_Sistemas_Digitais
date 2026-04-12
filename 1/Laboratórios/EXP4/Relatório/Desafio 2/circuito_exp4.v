module circuito_exp4(
    input clock,
    input reset,
    input iniciar,
    input [3:0] chaves,
    input modo,
    output acertou,
    output errou,
    output pronto,
    output [3:0] leds,
    output db_igual,
    output [6:0] db_contagem,
    output [6:0] db_memoria,
    output [6:0] db_estado,
    output [6:0] db_jogadafeita,
    output db_clock,
    output db_iniciar,
	output db_zerac,
	output db_contac,
	output db_fimc,
	output db_zerar,
	output db_registrar,
    output db_timeout,
    output db_tem_jogada,
    output db_enable_timeout,
    output db_zera_s_timeout,
    output db_modo,
    output chaveada
);

wire zeraC, zeraR, registraR, contaC, fimC, igual, tem_jogada, jogada_feita, timeout, enable_timeout, zera_s_timeout;
wire registra_modo, fim_4_jogadas, s_modo;
wire [6:0] hexa0, hexa1, hexa2, hexa3;
wire [3:0] s_contagem, s_memoria, s_estado, s_jogada;

exp4_fluxo_dados fluxo_dados(
    .clock(clock),
    .reset(reset),
    .chaves(chaves),
    .modo(modo),
    .zeraR(zeraR),
    .registrarR(registraR),
    .contaC(contaC),
    .zeraC(zeraC),
    .registra_modo(registra_modo),
    .igual(igual),
    .fimC(fimC),
    .fim_4_jogadas(fim_4_jogadas),
    .db_contagem(s_contagem),
    .db_jogada(s_jogada),
    .db_memoria(s_memoria),
    .jogada_feita(jogada_feita),
    .db_tem_jogada(tem_jogada),
    .db_enable_timeout(enable_timeout),
    .timeout(timeout),
    .zera_s_timeout(zera_s_timeout),
    .db_modo(s_modo),
    .chaveada(chaveada)
);

exp4_unidade_controle unidade_controle(
    .clock(clock),
    .reset(reset),
    .iniciar(iniciar),
    .fim(fimC),
    .fim_4_jogadas(fim_4_jogadas),
    .modo(s_modo),
    .jogada(jogada_feita),
    .igual(igual),
    .zerac(zeraC),
    .contac(contaC),
    .zeraR(zeraR),
    .registrarR(registraR),
    .registra_modo(registra_modo),
    .pronto(pronto),
    .db_estado(s_estado),
    .errou(errou),
    .acertou(acertou),
    .zera_s_timeout(zera_s_timeout),
    .timeout(timeout)
);

hexa7seg HEX0 (
    .hexa(s_contagem),
    .display(hexa0)
);

hexa7seg HEX1 (
    .hexa(s_memoria),
    .display(hexa1)
);

hexa7seg HEX2 (
    .hexa(s_jogada),
    .display(hexa2)
);

hexa7seg HEX3 (
    .hexa(s_estado),
    .display(hexa3)
);

assign db_iniciar = iniciar;
assign db_contagem = hexa0;
assign db_memoria = hexa1;
assign db_jogadafeita = hexa2;
assign db_estado = hexa3;
assign db_zerac = zeraC;
assign db_contac = contaC;
assign db_fimc = fimC;
assign db_zerar = zeraR;
assign db_registrar = registraR;
assign db_igual = igual;
assign db_tem_jogada = tem_jogada;
assign db_clock = clock;
assign leds = s_memoria;
assign db_enable_timeout = enable_timeout;
assign db_timeout = timeout;
assign db_zera_s_timeout = zera_s_timeout;
assign db_modo = s_modo;

endmodule