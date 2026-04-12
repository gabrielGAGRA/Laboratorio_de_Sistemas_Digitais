// ---------------------------------------------------------------------------
// Modulo: fluxo_dados
// Descricao: Caminho de dados unificado para Modo Livre e Aprendizado.
// ---------------------------------------------------------------------------
module fluxo_dados (
    input        clock,
    input        reset,

    // -- Entradas Físicas (Hardware) --
    input  [6:0] botoes,       // 7 notas
    input  [1:0] sw_oitava,    // Switches de transposição
    input  [3:0] sw_volume,    // Switches de PWM
    input  [1:0] sel_musica,   // Seletor de musica

    // -- Comandos da Unidade de Controle (FSM) --
    input        modo_aprendizado, // 1 = Aprendizado, 0 = Livre
    input        conta_endereco,
    input        zera_endereco,

    // -- Saídas Físicas (Hardware) --
    output       buzzer,
    output [6:0] leds,

    // -- Status para a Unidade de Controle (FSM) ou Top-Level --
    output       tem_nota_ativa,   // Vai para 1 quando há alguma tecla pressionada
    output       acerto_nota,      // Vai para 1 quando a nota batida for igual a nota lida na RAM
    output       fim_musica,       // Vai para 1 quando o endereço chega no limite
    output [7:0] s_endereco_ram,   // Exportado para visualizacao (HEX)
    output [2:0] s_id_para_led     // ID da nota atual para visualizacao (HEX cifrado)
);

    wire [2:0] s_nota_tocada;
    wire       s_tem_nota;
    wire [17:0] s_n_ticks;
    
    wire [3:0] s_dado_ram;
    wire [2:0] s_nota_esperada = s_dado_ram[2:0]; // Ignora o MSB, usa só 1 a 7

    // 1. Logica de Áudio (Tempo Real)
    logica_notas_prioridade logic_inst (
        .clock(clock), .reset(reset),
        .botoes(botoes), .nota_id(s_nota_tocada), .tem_nota(s_tem_nota)
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
        .M(2048), // Tamanho da musica / ROM maximo
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
    assign s_dado_ram = (sel_musica == 2'd0) ? s_dado_ram1 : s_dado_ram2;

    // Multiplexador de LEDs.
    // No Modo Aprendizado: Mostra a nota vinda da memoria.
    // No Modo Livre: Mostra a nota vinda do teclado (botoes).
    assign s_id_para_led = (modo_aprendizado) ? s_nota_esperada : s_nota_tocada;

    // 3. Logica Visual e Comparação
    decodificador_cifra decoder_cifra_inst (
        .nota_id(s_id_para_led),
        .display(leds)
    );

    // O sinal de match fica em nível alto enquanto a nota certa for segurada
    wire s_match_cru = (s_nota_tocada == s_nota_esperada) && s_tem_nota && modo_aprendizado;

    // Exportação direta dos níveis lógicos para a máquina de estado (FSM)
    assign tem_nota_ativa = s_tem_nota;
    assign acerto_nota = s_match_cru;

endmodule