// ---------------------------------------------------------------------------
// Modulo: unidade_controle
// Descricao: FSM de controle do Piano (Gerencia estados Musicais e de Modo)
// ---------------------------------------------------------------------------
module unidade_controle (
    input clock,
    input reset,
    
    // Entradas
    input btn_modo,         // Botao para trocar modo (pressione via Waveforms)
    input tem_nota_ativa,   // 1 = Usuario esta segurando pelo menos 1 nota
    input acerto_nota,      // 1 = A nota segurada eh a nota da RAM
    input fim_musica,       // 1 = Quando acabarem os 16 enderecos
    
    // Saidas de Estado
    output reg modo_aprendizado,
    output reg zera_endereco,
    output reg conta_endereco,
    output reg [4:0] estado_hex // Para depuracao em display 7 seg
);

    // Mapeamento dos Estados da FSM (RF_MODOS / RF_MUSICA)
    parameter INICIAL           = 3'd0;
    parameter LIVRE             = 3'd1;
    parameter INICIA_MUSICA     = 3'd2;
    parameter ESPERA_NOTA       = 3'd3;  // "Estado de LED" / "Aguarda acerto"
    parameter COMPARA_NOTA      = 3'd4;  // "Estado de comparacao"
    parameter PROXIMO           = 3'd5;  // "Avanca Endereco da ROM"
    parameter ESPERA_SOLTAR     = 3'd6;  // Inibe que pule duas notas por toque
    parameter FIM_MUSICA_ST     = 3'd7;  // "Estado de Fim"

    reg [2:0] state, next_state;

    // Transicao de Estado baseada no botao (usando edge_detector)
    wire mudou_modo;
    edge_detector ed_modo (
        .clock(clock),
        .reset(reset),
        .sinal(btn_modo),
        .pulso(mudou_modo)
    );

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            state <= INICIAL;
        end else begin
            state <= next_state; 
        end
    end

    // Logica de Proximo Estado e Saidas (Moore + Lógica Limpa)
    always @(*) begin
        // Valores padrao
        next_state = state;
        modo_aprendizado = 1'b0;
        zera_endereco = 1'b0;
        conta_endereco = 1'b0;
        estado_hex = 5'd0;

        case (state)
            INICIAL: begin
                zera_endereco = 1'b1;
                estado_hex = 5'h0; // Modo Inicial
                
                next_state = LIVRE; // Vai automatico após resetar RAM
            end

            LIVRE: begin
                modo_aprendizado = 1'b0;
                zera_endereco = 1'b1;    // Mantem RAM resetada pro inicio
                estado_hex = 5'h0; // Modo Livre

                if (mudou_modo) next_state = INICIA_MUSICA;
            end
            
            INICIA_MUSICA: begin
                modo_aprendizado = 1'b1;
                zera_endereco = 1'b1;    // Reseta end da ROM
                estado_hex = 5'h2;
                
                next_state = ESPERA_NOTA;
            end

            ESPERA_NOTA: begin
                modo_aprendizado = 1'b1; 
                estado_hex = 5'h2; // Modo Espera

                if (mudou_modo) next_state = LIVRE;
                else if (tem_nota_ativa) next_state = COMPARA_NOTA;
            end
            
            COMPARA_NOTA: begin
                modo_aprendizado = 1'b1; 
                estado_hex = 5'h2;
                
                if (mudou_modo) next_state = LIVRE;
                else if (acerto_nota) next_state = PROXIMO;
                else if (!tem_nota_ativa) next_state = ESPERA_NOTA; 
                // Se errou continua aqui ouvindo ativamente o toque do Override 
            end

            PROXIMO: begin
                modo_aprendizado = 1'b1; 
                estado_hex = 5'h4; // Modo Proximo
                conta_endereco = 1'b1; // Puxa gatilho do contador

                next_state = ESPERA_SOLTAR;
            end

            ESPERA_SOLTAR: begin
                modo_aprendizado = 1'b1;
                estado_hex = 5'h5; // Estado Aguardando Dedo Sair
                
                if (mudou_modo) next_state = LIVRE;
                else if (!tem_nota_ativa) begin
                    if (fim_musica) next_state = FIM_MUSICA_ST;
                    else next_state = ESPERA_NOTA;
                end
            end

            FIM_MUSICA_ST: begin
                modo_aprendizado = 1'b0; // Apaga leds pra indicar fim
                estado_hex = 5'h2;
                
                if (mudou_modo) next_state = LIVRE;
            end
            
            default: next_state = INICIAL;
        endcase
    end
endmodule