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

    // -- Comandos da Unidade de Controle (FSM) --
    input        modo_aprendizado, // 1 = Aprendizado, 0 = Livre
    input        conta_endereco,
    input        zera_endereco,

    // -- Saídas Físicas (Hardware) --
    output       buzzer,
    output [6:0] leds,

    // -- Status para a Unidade de Controle (FSM) --
    output       pulso_acerto,     // Vai para 1 quando a nota certa é pressionada
    output       fim_musica        // Vai para 1 quando o endereço chega no limite
);

    wire [2:0] s_nota_tocada;
    wire       s_tem_nota;
    wire [17:0] s_n_ticks;
    
    wire [3:0] s_endereco_ram;
    wire [3:0] s_dado_ram;
    wire [2:0] s_nota_esperada = s_dado_ram[2:0]; // Ignora o MSB, usa só 1 a 7

    // 1. Logica de Áudio (Tempo Real)
    note_priority_logic logic_inst (
        .clock(clock), .reset(reset),
        .botoes(botoes), .nota_id(s_nota_tocada), .tem_nota(s_tem_nota)
    );

    frequency_lut lut_inst (
        .nota_id(s_nota_tocada), 
        //.oitava(sw_oitava), 
        .n_ticks(s_n_ticks)
    );

    gerador_audio audio_inst (
        .clock(clock), .reset(reset),
        .fim_contagem(s_n_ticks), .habilitar(s_tem_nota),
        .buzzer(buzzer)
    );

    // 2. Logica de Memória e Endereçamento [cite: 21, 121]
    contador_163 contador_addr (
        .clock(clock),
        .clr(~zera_endereco),
        .ld(1'b1), .ent(1'b1),
        .enp(conta_endereco),
        .D(4'b0000),
        .Q(s_endereco_ram),
        .rco(fim_musica) // Assumindo que a música tem 16 notas (0 a 15)
    );

    sync_rom_16x4 memoria (
        .clock(clock),
        .address(s_endereco_ram),
        .data_out(s_dado_ram)
    );

    // NOVO: Multiplexador de LEDs.
    // No Modo Aprendizado: Mostra a nota vinda da memoria.
    // No Modo Livre: Mostra a nota vinda do teclado (botoes).
    wire [2:0] s_id_para_led = (modo_aprendizado) ? s_nota_esperada : s_nota_tocada;

    // 3. Logica Visual e Comparação
    decodificador_leds decoder_led (
        .nota_id(s_id_para_led),
        .leds(leds)
    );

    // O sinal de "match" fica em nível alto enquanto a nota certa for segurada
    wire s_match_cru = (s_nota_tocada == s_nota_esperada) && s_tem_nota && modo_aprendizado;

    // Converte o "match" em um pulso de 1 clock  para a FSM avançar a RAM
    edge_detector detector_acerto (
        .clock(clock),
        .reset(reset),
        .sinal(s_match_cru),
        .pulso(pulso_acerto)
    );

endmodule