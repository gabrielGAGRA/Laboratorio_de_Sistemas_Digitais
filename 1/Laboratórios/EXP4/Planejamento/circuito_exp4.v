module circuito_exp4(
    input clock,
    input reset,
    input iniciar,
    input [3:0] chaves,
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
    output db_tem_jogada
);

wire zeraC, zeraR, registraR, contaC, fimC, igual, tem_jogada, rstE;
wire [6:0] hexa0, hexa1, hexa2, hexa3;
wire [3:0] s_contagem, s_memoria, s_estado, s_jogada;

exp4_fluxo_dados fluxo_dados(
    .clock(clock),
    .chaves(chaves),
    .zeraR(zeraR),
    .registrarR(registraR),
    .contaC(contaC),
    .zeraC(zeraC),
    .igual(igual),
    .fimC(fimC),
    .db_contagem(s_contagem),
    .db_jogada(s_jogada),
    .db_memoria(s_memoria),
    .jogada_feita(jogada_feita),
    .db_tem_jogada(tem_jogada)
);

exp4_unidade_controle unidade_controle(
    .clock(clock),
    .reset(reset),
    .iniciar(iniciar),
    .fim(fimC),
    .jogada(jogada_feita),
    .igual(igual),
    .zerac(zeraC),
    .contac(contaC),
    .zeraR(zeraR),
    .registrarR(registraR),
    .pronto(pronto),
    .db_estado(s_estado),
    .errou(errou),
    .acertou(acertou)
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

endmodule
