`timescale 1ns/1ns

module tb_gerador_pwm;

    reg clock;
    reg reset;
    reg [3:0] duty_cycle;
    wire pwm_out;

    gerador_pwm dut (
        .clock(clock),
        .reset(reset),
        .duty_cycle(duty_cycle),
        .pwm_out(pwm_out)
    );

    // Clock 50MHz (periodo 20ns)
    always #10 clock = ~clock;

    initial begin
        $display("Iniciando Testbench do Gerador PWM...");
        $dumpfile("tb_gerador_pwm.vcd");
        $dumpvars(0, tb_gerador_pwm);

        clock = 0;
        reset = 1;
        duty_cycle = 4'h0;

        #50 reset = 0;

        // Teste de 0%
        $display("[%0t ns] Testando duty cycle 0%%", $time);
        duty_cycle = 4'h0;
        #100000;

        // Teste de 25% (4'h4)
        $display("[%0t ns] Testando duty cycle ~25%%", $time);
        duty_cycle = 4'h4;
        #100000;

        // Teste de 50% (4'h8)
        $display("[%0t ns] Testando duty cycle ~50%%", $time);
        duty_cycle = 4'h8;
        #100000;

        // Teste de 75% (4'hC)
        $display("[%0t ns] Testando duty cycle ~75%%", $time);
        duty_cycle = 4'hC;
        #100000;

        // Teste de 100% (4'hF)
        $display("[%0t ns] Testando duty cycle 100%%", $time);
        duty_cycle = 4'hF;
        #100000;

        $display("[%0t ns] Teste Finalizado.", $time);
        $finish;
    end

endmodule
