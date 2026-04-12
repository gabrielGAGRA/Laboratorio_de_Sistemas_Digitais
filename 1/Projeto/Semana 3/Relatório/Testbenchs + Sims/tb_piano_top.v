`timescale 1ns/1ns

module tb_piano_top;

    reg CLOCK_50;
    reg reset_n;
    reg [6:0] gpio_keys;
    reg btn_modo;
    reg btn_musica;
    reg btn_intensidade;
    reg btn_oitava_up;
    reg btn_oitava_down;
    reg btn_sustenido;

    wire buzzer;
    wire [6:0] led_vermelho;
    wire led_sustenido;
    wire led_oitava_up;
    wire led_oitava_down;
    wire [6:0] hex5_modo;
    wire [6:0] hex4_oitava;
    wire [6:0] hex3_musica_dezena;
    wire [6:0] hex2_musica_unidade;
    wire [6:0] hex1_nota;
    wire [6:0] hex0_sustenido;

    // Instancia o top-level com tempos curtos de debounce para agilizar
    piano_top #(
        .DEBOUNCE_TECLA(2),
        .DEBOUNCE_CONTROLE(2)
    ) dut (
        .CLOCK_50(CLOCK_50),
        .reset_n(reset_n),
        .gpio_keys(gpio_keys),
        .btn_modo(btn_modo),
        .btn_musica(btn_musica),
        .btn_intensidade(btn_intensidade),
        .btn_oitava_up(btn_oitava_up),
        .btn_oitava_down(btn_oitava_down),
        .btn_sustenido(btn_sustenido),
        .buzzer(buzzer),
        .led_vermelho(led_vermelho),
        .led_sustenido(led_sustenido),
        .led_oitava_up(led_oitava_up),
        .led_oitava_down(led_oitava_down),
        .hex5_modo(hex5_modo),
        .hex4_oitava(hex4_oitava),
        .hex3_musica_dezena(hex3_musica_dezena),
        .hex2_musica_unidade(hex2_musica_unidade),
        .hex1_nota(hex1_nota),
        .hex0_sustenido(hex0_sustenido)
    );

    // Clock
    always #10 CLOCK_50 = ~CLOCK_50; // 50MHz

    // Tarefa utilitaria para checar os valores dos LEDs e reportar o Acerto/Erro do modulo
    task validar_leds(input [6:0] exp_led_vermelho, input exp_led_up, input exp_led_down, input [800:0] contexto);
        begin
            #10;
            if (led_vermelho === exp_led_vermelho && led_oitava_up === exp_led_up && led_oitava_down === exp_led_down) begin
                $display("[PASS] %s | led_vermelho=%b, up=%b, down=%b", contexto, led_vermelho, led_oitava_up, led_oitava_down);
            end else begin
                $display("[FAIL] %s", contexto);
                $display("       Esperado: led_vermelho=%b, up=%b, down=%b", exp_led_vermelho, exp_led_up, exp_led_down);
                $display("       Lido    : led_vermelho=%b, up=%b, down=%b", led_vermelho, led_oitava_up, led_oitava_down);
            end
        end
    endtask

    initial begin
        $display("==================================================");
        $display(" Iniciando Simulacao Completa: Modo Aprendizado ");
        $display("==================================================");
        CLOCK_50 = 0;
        reset_n = 0; // Ativo baixo
        gpio_keys = 0;
        
        // Logica Pull-up (Desacionados = 1)
        btn_modo = 1;
        btn_musica = 1;
        btn_intensidade = 1;
        btn_oitava_up = 1;
        btn_oitava_down = 1;
        btn_sustenido = 1;

        #100 reset_n = 1; // Libera Reset
        #200;

        $display("\n--- MUDANDO PARA MODO APRENDIZADO ---");
        btn_modo = 0; #100; btn_modo = 1; 
        #2000; // Tempo pro debounce + leitura da memoria (ROM) estabilizar

        // Musica 0: do_re_mi.txt. Primeira nota: Do5 (001), oitava inicial do sistema eh 4 (100)
        // Como oitava pedida > oitava atual, led_oitava_up deve acender.
        validar_leds(
            7'b0000001, // Espera led_vermelho[0] aceso indicando DO
            1'b1,       // Espera led UP aceso (Precisa ir da oitava 4 para 5)
            1'b0,       // led down apagado
            "Validando Primeira Nota (Dó) - Analise de Oitava"
        );

        $display("\n--- TESTANDO: TOCAR NOTA COM OITAVA ERRADA ---");
        gpio_keys = 7'b0000001; // Toca Do
        #1000;
        validar_leds(7'b0000001, 1'b1, 1'b0, "Apertou a nota certa, mas na Oitava Errada -> Nao deve avancar a FSM");
        gpio_keys = 0; // Solta Do
        #1000;

        $display("\n--- CORRIGINDO OITAVA ---");
        btn_oitava_up = 0; #100; btn_oitava_up = 1;
        #500; // Espera FSM de oitava atualizar
        validar_leds(7'b0000001, 1'b0, 1'b0, "Apos subir oitava -> led_up apaga, led_vermelho continua pedindo DO");


        $display("\n--- TESTANDO: TOCAR A NOTA CORRETA (Dó5) ---");
        gpio_keys = 7'b0000001; // Toca Do
        #500; // Espera estagio COMPARA_NOTA e PROXIMO executarem
        
        $display("     [LOG] Nota pressionada. FSM deve avancar endereco.");
        gpio_keys = 0; // Solta nota para sair de ESPERA_SOLTAR
        #1000; // Espera buscar a proxima nota na ROM

        // A proxima nota eh RE 5 (ID 2 => acende led_vermelho[1]). A oitava ja eh 5, entao corretas
        validar_leds(7'b0000010, 1'b0, 1'b0, "Passou para proxima nota -> RE. LEDs refletem nova nota e oitava valida.");


        $display("\n--- TESTANDO: ERRAR A NOTA DE PROPOSITO (Tocar Mi no lugar de Re) ---");
        gpio_keys = 7'b0000100; // Toca Mi (ID 3)
        #500;
        validar_leds(7'b0000010, 1'b0, 1'b0, "Toquei Mi porem pediu Re -> a FSM ignora e continua pedindo RE");
        gpio_keys = 0; // Solta
        #1000;


        $display("\n--- TESTANDO: TOCAR A NOTA CORRETA (Ré5) ---");
        gpio_keys = 7'b0000010; // Toca Re (ID 2)
        #500;
        gpio_keys = 0; // Solta nota
        #1000;

        // Proxima da partitura do_re_mi: Mi 5 (ID 3 => acende led_vermelho[2])
        validar_leds(7'b0000100, 1'b0, 1'b0, "Acertou o Re -> Passou para a proxima: MI");


        $display("\n==================================================");
        $display(" Teste Completo e Aprovado!");
        $display("==================================================");
        $finish;
    end

endmodule
