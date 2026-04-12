`timescale 1ns/1ns

module teste_audio_piano_tb;

    // Sinais de estímulo (entradas)
    reg        CLOCK_50;
    reg        reset_n;
    reg  [6:0] gpio_keys;

    // Sinais de observação (saídas)
    wire       buzzer;

    // Instanciação do módulo Top-Level
    teste_audio_piano dut (
        .CLOCK_50(CLOCK_50),
        .reset_n(reset_n),
        .gpio_keys(gpio_keys),
        .buzzer(buzzer)
    );

    // Gerador de Clock (50MHz -> Periodo = 20ns)
    always #10 CLOCK_50 = ~CLOCK_50;

    // --- Lógica de Medição de Frequência Dinâmica ---
    time tempo_borda_anterior = 0;
    real periodo_em_ns;
    real frequencia_atual_hz;

    // Sempre que o buzzer subir, calculamos a freq baseado no tempo decorrido
    always @(posedge buzzer) begin
        if (tempo_borda_anterior != 0) begin
            periodo_em_ns = $time - tempo_borda_anterior;
            frequencia_atual_hz = 1_000_000_000.0 / periodo_em_ns;
        end
        tempo_borda_anterior = $time;
    end

    // Task para automatizar a conferência (Asserts)
    task check_freq(input real freq_esperada, input [127:0] nome_nota);
        begin
            #2000000; // Aguarda 2ms para estabilizar a medição da nota
            // Tolerância de 1% para compensar arredondamentos de divisão inteira no hardware
            if (frequencia_atual_hz > freq_esperada * 0.99 && frequencia_atual_hz < freq_esperada * 1.01) begin
                $display("[PASS] %s detectada: %0.2f Hz", nome_nota, frequencia_atual_hz);
            end else begin
                $display("[FAIL] %s INCORRETA! Esperado: %0.2f Hz | Lido: %0.2f Hz", 
                         nome_nota, freq_esperada, frequencia_atual_hz);
            end
        end
    endtask

    // Bloco Principal de Teste
    initial begin
        // Configuração para extração de ondas (Iverilog/GTKWave)
        $dumpfile("teste_audio_piano.vcd");
        $dumpvars(0, teste_audio_piano_tb);

        // Inicialização
        CLOCK_50  = 0;
        reset_n   = 0;
        gpio_keys = 7'b0000000;

        $display("--- Iniciando Teste de Frequencia Dinamica ---");

        #100 reset_n = 1; #100;

        // Teste 1: Nota Dó (ID 1)
        $display("[%0t ns] Testando Do5...", $time);
        gpio_keys[0] = 1'b1;
        check_freq(523.25, "Do5");

        // Teste 2: Override Mi (ID 3)
        $display("[%0t ns] Testando Mi5 (Override)...", $time);
        gpio_keys[2] = 1'b1;
        check_freq(659.25, "Mi5 Override");

        // Teste 3: Fallback (Soltando Mi, volta pro Do)
        $display("[%0t ns] Soltando Mi5, voltando para Do5...", $time);
        gpio_keys[2] = 1'b0;
        check_freq(523.25, "Do5 Fallback");
        
        $display("--- Fim dos Testes Automatizados ---");
        $finish; 
    end

endmodule