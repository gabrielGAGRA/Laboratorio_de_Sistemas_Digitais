`timescale 1ns/1ns

module tb_piano_top;

    reg CLOCK_50;
    reg reset_n;
    reg [6:0] gpio_keys;
    reg btn_modo;
    reg btn_musica;
    reg btn_intensidade;

    wire buzzer;
    wire [6:0] led_vermelho;
    wire [6:0] hex0_estado;
    wire [6:0] hex1_oitava;
    wire [6:0] hex3_indice;
    wire [6:0] hex4_indice;
    wire [6:0] hex5_cifra;

    // Instancia o top-level sobrescrevendo os parametros de tempo de debounce para agilizar a simulacao
    piano_top #(
        .DEBOUNCE_NOTAS(2),
        .DEBOUNCE_MODO(2)
    ) dut (
        .CLOCK_50(CLOCK_50),
        .reset_n(reset_n),
        .gpio_keys(gpio_keys),
        .btn_modo(btn_modo),
        .btn_musica(btn_musica),
        .btn_intensidade(btn_intensidade),
        .buzzer(buzzer),
        .led_vermelho(led_vermelho),
        .hex0_estado(hex0_estado),
        .hex1_oitava(hex1_oitava),
        .hex3_indice(hex3_indice),
        .hex4_indice(hex4_indice),
        .hex5_cifra(hex5_cifra)
    );

    // Clock gen 50MHz (periodo 20ns)
    always #10 CLOCK_50 = ~CLOCK_50;

    // Reaproveitado do tb da semana 1 para medição de frequência gerada
    time tempo_borda_anterior = 0;
    real periodo_em_ns;
    real frequencia_atual_hz;

    // Sempre que o buzzer subir, calculamos a freq baseada no tempo decorrido
    always @(posedge buzzer) begin
        if (tempo_borda_anterior != 0) begin
            periodo_em_ns = $time - tempo_borda_anterior;
            frequencia_atual_hz = 1_000_000_000.0 / periodo_em_ns;
        end
        tempo_borda_anterior = $time;
    end

    // Task para conferência
    task check_freq(input real freq_esperada, input [255:0] nome_nota);
        begin
            #4000000; // Aguarda 4ms para estabilizar a medição (frequências menores precisam de mais tempo)
            // Tolerância de 1%
            if (frequencia_atual_hz > freq_esperada * 0.99 && frequencia_atual_hz < freq_esperada * 1.01) begin
                $display("[%0t ns] [PASS] %s detectada: %0.2f Hz", $time, nome_nota, frequencia_atual_hz);
            end else begin
                $display("[%0t ns] [FAIL] %s INCORRETA! Esperado: %0.2f Hz | Lido: %0.2f Hz", 
                         $time, nome_nota, freq_esperada, frequencia_atual_hz);
            end
        end
    endtask

    initial begin
        $display("Iniciando Testbench de Integracao: piano_top...");
        $dumpfile("tb_piano_top.vcd");
        $dumpvars(0, tb_piano_top);

        // Inicializacao
        CLOCK_50 = 0;
        reset_n = 0; // Ativo baixo
        gpio_keys = 0;
        btn_modo = 0;
        btn_musica = 0;
        btn_intensidade = 0;

        // Libera do reset
        #50 reset_n = 1;
        #50;

        // Testa Modo Livre
        $display("Testando Modo Livre - Pressionando C (Do)");
        gpio_keys = 7'b0000001; 
        #200; // Tempo pro debounce contabilizar
        check_freq(261.63, "Do4 (Modo Livre)");
        
        $display("No Modo Livre, as LEDs devem refletir a GPIO.");
        gpio_keys = 0; 
        #200;

        // Muda Modo
        $display("Mudando para Modo Aprendizado...");
        btn_modo = 1; // Pressiona o botao
        #100 btn_modo = 0; // Solta o botao
        #200; 

        // Tinha musica escolhida? Tenta tocar primeira nota de Acerto!
        $display("Testando acerto de nota em Aprendizado (Tentando Do)");
        gpio_keys = 7'b0000001;
        #200;
        check_freq(261.63, "Do4 (Modo Aprendizado)");
        
        // Testa a prioridade no meio do aprendizado
        gpio_keys = 7'b0000101; // Liga o Mi junto
        #200;
        check_freq(329.63, "Mi4 (Override no Aprendizado)");

        gpio_keys = 0;
        #200;

        $display("Muda Musica...");
        btn_musica = 1; #100; btn_musica = 0;
        #200;

        $display("Testando alteracao de intensidade do LED (PWM)...");
        btn_intensidade = 1; #100; btn_intensidade = 0; // ~75%
        #200;
        btn_intensidade = 1; #100; btn_intensidade = 0; // ~50%
        #200;
        btn_intensidade = 1; #100; btn_intensidade = 0; // ~25%
        #200;
        btn_intensidade = 1; #100; btn_intensidade = 0; // 0%
        #200;
        btn_intensidade = 1; #100; btn_intensidade = 0; // Volta para 100%
        #200;

        $display("Teste Finalizado.");
        $finish;
    end

endmodule
