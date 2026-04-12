module fluxo_dados (
    input        clock,
    input        zeraC,
    input        contaC,
    input        zeraR,
    input        registrarR,
    input  [3:0] chaves,
    output       igual,
    output       fimC,
    output       jogada_feita,      // Pulso do edge_detector
    output       db_tem_jogada,     // Saída da porta OR
    output [3:0] db_contagem,
    output [3:0] db_memoria,
    output [3:0] db_jogada
);
    wire [3:0] s_endereco;
    wire [3:0] s_dado, s_chaves;
    wire       s_tem_jogada;

    // Porta OR para detectar se QUALQUER chave foi pressionada
    assign s_tem_jogada = |chaves; 
    assign db_tem_jogada = s_tem_jogada;

    // Detector de Borda para gerar pulso de 1 clock [cite: 124, 295]
    edge_detector detector (
        .clock(clock),
        .reset(zeraR), // Resetando junto com o registrador
        .sinal(s_tem_jogada),
        .pulso(jogada_feita)
    );

    contador_163 contador (
        .clock(clock),
        .clr(~zeraC),
        .ld(1'b1),
        .ent(1'b1),
        .enp(contaC),
        .D(4'b0000),
        .Q(s_endereco),
        .rco(fimC)
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

endmodule