// ---------------------------------------------------------------------------
// Modulo: unidade_controle
// Descricao: FSM de controle do Piano (Alterna entre Modo Livre e Aprendizado)
// ---------------------------------------------------------------------------
module unidade_controle (
    input clock,
    input reset,
    
    // Entradas
    input btn_modo,    // Botao para trocar modo (pressione via Waveforms)
    input pulso_acerto,// O pulso de 1 clock vindo do Fluxo quando a nota estiver correta
    input fim_musica,  // Quando acabarem os 16 enderecos
    
    // Saidas de Estado
    output reg modo_aprendizado,
    output reg zera_endereco,
    output reg conta_endereco,
    output reg [4:0] estado_hex // Para depuracao em display 7 seg (0 = Livre, 1 = Musica)
);

    parameter LIVRE = 1'b0, APRENDIZADO = 1'b1;
    reg state, next_state;

    // Transicao de Estado baseada no botao
    reg btn_modo_ant;
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            state <= LIVRE;
            btn_modo_ant <= 1'b0;
        end else begin
            btn_modo_ant <= btn_modo;
            // Se detectar borda de subida do botao
            if (btn_modo && !btn_modo_ant) 
                state <= ~state; // Troca entre 0 e 1 (Livre <-> Aprendizado)
            else
                state <= next_state; 
        end
    end

    // Logica de Proximo Estado e Saidas
    always @(*) begin
        next_state = state;
        modo_aprendizado = 1'b0;
        zera_endereco = 1'b0;
        conta_endereco = 1'b0;
        estado_hex = 4'd0;

        case (state)
            LIVRE: begin
                modo_aprendizado = 1'b0;
                zera_endereco = 1'b1;    // Mantem RAM resetada pro inicio
                estado_hex = 4'd0;       // Display mostrará "0"
            end
            
            APRENDIZADO: begin
                modo_aprendizado = 1'b1;
                // Só avança o contador da memória quando houver um acerto
                conta_endereco = pulso_acerto; 
                
                // Opcao de loop continuo: Se acabou, e apertou a última nota, ele zera pra comecar de novo
                if (fim_musica && pulso_acerto)
                    zera_endereco = 1'b1;
                    
                estado_hex = 4'd1;       // Display mostrará "1"
            end
        endcase
    end
endmodule