module exp4_fluxo_dados (
    input        clock,
    input        zeraC,
    input        contaC,
    input        zeraR,
    input        reset,
    input        registrarR,
    input        zera_s_timeout,
    input        enable_timeout,
    input  [3:0] chaves,
    input        modo,
    input        registra_modo,
    input        zera_modo,        // Novo: reset do registrador de modo
    output       igual,
    output       fimC,             // Agora sai do MUX
    output       jogada_feita,
    output       db_tem_jogada,
    output       db_enable_timeout,
    output [3:0] db_contagem,
    output [3:0] db_memoria,
    output       timeout,
    output [3:0] db_jogada,
    output       db_modo
);
    wire [3:0] s_endereco;
    wire [3:0] s_dado, s_chaves;
    wire       s_tem_jogada;
    wire       s_modo;
    wire       s_rco;             // RCO do contador (fim 16 jogadas)
    wire       s_fim_4;           // Fim 4 jogadas

    // porta OR para detectar se qualquer chave foi pressionada
    assign s_tem_jogada = |chaves; 
    assign db_tem_jogada = s_tem_jogada;
    assign db_enable_timeout = enable_timeout;

    // Registrador de modo - 1 bit
    registrador_1 reg_modo (
        .clock(clock),
        .clear(zera_modo),        // Reset no início (estado inicial)
        .enable(registra_modo),   // Enable na preparação
        .D(modo),
        .Q(s_modo)
    );

    // Detecção de fim após 4 jogadas (contagem == 3, ou seja, 0011)
    assign s_fim_4 = (s_endereco == 4'b0011);

    // MUX 2x1: seleciona fim baseado no modo
    // modo=0: 16 jogadas (s_rco), modo=1: 4 jogadas (s_fim_4)
    assign fimC = (s_modo == 1'b0) ? s_rco : s_fim_4;

    // detector de borda para gerar pulso de 1 clock
    edge_detector detector (
        .clock(clock),
        .reset(reset),
        .sinal(s_tem_jogada),
        .pulso(jogada_feita)
    );

    contador_m #(
        .M(3000),
        .N(12)
    ) contador_timeout (
        .clock(clock),
        .zera_as(1'b0),
        .zera_s(zera_s_timeout),
        .conta(enable_timeout),
        .Q(),
        .fim(timeout),
        .meio()
    );

    contador_163 contador (
        .clock(clock),
        .clr(~zeraC),
        .ld(1'b1),
        .ent(1'b1),
        .enp(contaC),
        .D(4'b0000),
        .Q(s_endereco),
        .rco(s_rco)               // RCO vai para o MUX
    );

    comparador_85 comparador (
        .A(s_dado),
        .B(s_chaves),
        .ALBi(1'b0), .AGBi(1'b0), .AEBi(1'b1),
        .AEBo(igual)
    );

    registrador_4 registrador (
        .clock(clock),
        .clear(zeraR),
        .enable(registrarR),
        .D(chaves),
        .Q(s_chaves)
    );

    sync_rom_16x4 memoria (
        .clock(clock),
        .address(s_endereco),
        .data_out(s_dado)
    );

    assign db_contagem = s_endereco;
    assign db_jogada   = s_chaves;
    assign db_memoria  = s_dado;
    assign db_modo = s_modo;

endmodule