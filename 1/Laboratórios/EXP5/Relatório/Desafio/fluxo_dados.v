module fluxo_dados (
    input        clock,
    input        zera_endereco,
    input        conta_endereco,
    input        zera_limite,      
    input        conta_limite,     
    input        zeraR,
    input        reset,
    input        registrarR,
    input        zera_s_timeout,
    input        enable_timeout,
    input  [3:0] botoes,           
    input        modo,
    input        registra_modo,
    input        zera_modo,
    output       igual,
    output       fim_jogo,         // Fim total (ganhou)
    output       enderecoIgualLimite, // Fim da rodada atual
    output       jogada_feita,
    output       db_tem_jogada,
    output       db_enable_timeout,
    output [3:0] db_contagem,
    output [3:0] db_memoria,
    output [3:0] db_limite,
    output       timeout,
    output [3:0] db_jogada,
    output       db_modo,
    output       chavesIgualMemoria 
);
    wire [3:0] s_endereco;
    wire [3:0] s_dado, s_botoes; 
    wire [3:0] s_limite;
    wire [3:0] s_jogo_limite;
    wire       s_tem_jogada;
    wire       s_modo;
    
    assign s_tem_jogada = |botoes; 
    assign db_tem_jogada = s_tem_jogada;
    assign db_enable_timeout = enable_timeout;

    // Registrador de modo
    registrador_1 reg_modo (
        .clock(clock),
        .clear(zera_modo),
        .enable(registra_modo),
        .D(modo),
        .Q(s_modo)
    );

    // Fim de rodada
    assign s_jogo_limite = (s_modo == 1'b0) ? 4'b1111 : 4'b0011;

    comparador_85 compFimRodada (
        .A(s_endereco),
        .B(s_limite),
        .ALBi(1'b0), .AGBi(1'b0), .AEBi(1'b1),
        .AEBo(enderecoIgualLimite),
        .ALBo(), .AGBo()
    );

    comparador_85 compFimJogo (
        .A(s_limite),
        .B(s_jogo_limite),
        .ALBi(1'b0), .AGBi(1'b0), .AEBi(1'b1),
        .AEBo(fim_jogo),
        .ALBo(), .AGBo()
    );
   
    edge_detector detector (
        .clock(clock),
        .reset(reset),
        .sinal(s_tem_jogada),
        .pulso(jogada_feita)
    );

    contador_m #(
        .M(3000),
        .N(13)
    ) contador_timeout (
        .clock(clock),
        .zera_as(reset), 
        .zera_s(zera_s_timeout),
        .conta(enable_timeout),
        .Q(),
        .fim(timeout),
        .meio()
    );

    // Contador da sequência 
    contador_163 contador_addr (
        .clock(clock),
        .clr(~zera_endereco),
        .ld(1'b1),
        .ent(1'b1),
        .enp(conta_endereco),
        .D(4'b0000),
        .Q(s_endereco),
        .rco() 
    );

    // Contador de rodadas
    contador_163 contLmt (
        .clock(clock),
        .clr(~zera_limite),
        .ld(1'b1),
        .ent(1'b1),
        .enp(conta_limite),
        .D(4'b0000),
        .Q(s_limite),
        .rco() 
    );

    comparador_85 comparador (
        .A(s_dado),
        .B(s_botoes),
        .ALBi(1'b0), .AGBi(1'b0), .AEBi(1'b1),
        .AEBo(igual)
    );

    registrador_4 registrador (
        .clock(clock),
        .clear(zeraR),
        .enable(registrarR),
        .D(botoes),
        .Q(s_botoes)
    );

    sync_rom_16x4 memoria (
        .clock(clock),
        .address(s_endereco),
        .data_out(s_dado)
    );

    assign db_contagem = s_endereco;
    assign db_jogada   = s_botoes;
    assign db_memoria  = s_dado;
    assign db_limite   = s_limite;
    assign db_modo     = s_modo;
    assign chavesIgualMemoria = igual;

endmodule
