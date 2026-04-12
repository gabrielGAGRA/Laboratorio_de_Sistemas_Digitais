// ---------------------------------------------------------------------------
// Modulo: unidade_controle
// Descricao: FSM de controle do Piano (Gerencia estados Musicais e de Modo)
// ---------------------------------------------------------------------------
module unidade_controle (
    input clock,
    input reset,
    
    // Entradas
    input mudou_modo,       // Pulso para trocar modo
    input tem_nota_ativa,   
    input acerto_nota,      
    input fim_musica,      
    
    // Saidas de Estado
    output reg [1:0] modo_ativo, // 0 = Livre, 1 = Aprendizado, 2 = Gravacao
    output reg escreve_ram,
    output reg zera_endereco,
    output reg conta_endereco,
    output reg [4:0] estado_hex // Para depuracao
);

    // Estados da UC
    parameter INICIAL           = 4'd0;
    parameter LIVRE             = 4'd1;
    
    // Aprendizado
    parameter INICIA_MUSICA     = 4'd2;
    parameter ESPERA_NOTA       = 4'd3;  
    parameter COMPARA_NOTA      = 4'd4;  
    parameter PROXIMO           = 4'd5;  
    parameter ESPERA_SOLTAR     = 4'd6;  
    parameter FIM_MUSICA_ST     = 4'd7; 

    // Gravacao
    parameter INICIA_GRAVACAO   = 4'd8;
    parameter GRAV_ESPERA_NOTA  = 4'd9;
    parameter GRAV_ARMAZENA     = 4'd10;
    parameter GRAV_PROXIMO      = 4'd11;
    parameter GRAV_SOLTAR       = 4'd12;

    reg [3:0] state, next_state;

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            state <= INICIAL;
        end else begin
            state <= next_state; 
        end
    end

    // Logica de proximo estado e saidas
    always @(*) begin
        // Valores padrao
        next_state = state;
        modo_ativo = 2'd0;
        escreve_ram = 1'b0;
        zera_endereco = 1'b0;
        conta_endereco = 1'b0;
        estado_hex = 5'd0;

        case (state)
            INICIAL: begin
                zera_endereco = 1'b1;
                estado_hex = 5'h0; 
                modo_ativo = 2'd0;
                next_state = LIVRE; 
            end

            LIVRE: begin
                zera_endereco = 1'b1;    
                estado_hex = 5'h0; 
                modo_ativo = 2'd0;
                if (mudou_modo) next_state = INICIA_MUSICA;
            end
            
            // ---------------- APRENDIZADO ----------------
            INICIA_MUSICA: begin
                modo_ativo = 2'd1;
                zera_endereco = 1'b1;    
                estado_hex = 5'h1;
                next_state = ESPERA_NOTA;
            end

            ESPERA_NOTA: begin
                modo_ativo = 2'd1;
                estado_hex = 5'h1; 
                if (mudou_modo) next_state = INICIA_GRAVACAO;
                else if (tem_nota_ativa) next_state = COMPARA_NOTA;
            end
            
            COMPARA_NOTA: begin
                modo_ativo = 2'd1;
                estado_hex = 5'h1;
                if (mudou_modo) next_state = INICIA_GRAVACAO;
                else if (acerto_nota) next_state = PROXIMO;
                else if (!tem_nota_ativa) next_state = ESPERA_NOTA; 
            end

            PROXIMO: begin
                modo_ativo = 2'd1;
                estado_hex = 5'h1; 
                conta_endereco = 1'b1; 
                next_state = ESPERA_SOLTAR;
            end

            ESPERA_SOLTAR: begin
                modo_ativo = 2'd1;
                estado_hex = 5'h1; 
                if (mudou_modo) next_state = INICIA_GRAVACAO;
                else if (!tem_nota_ativa) begin
                    if (fim_musica) next_state = FIM_MUSICA_ST;
                    else next_state = ESPERA_NOTA;
                end
            end

            FIM_MUSICA_ST: begin
                modo_ativo = 2'd1;
                estado_hex = 5'h1;
                if (mudou_modo) next_state = INICIA_GRAVACAO;
            end
            
            // ---------------- GRAVACAO ----------------
            INICIA_GRAVACAO: begin
                modo_ativo = 2'd2;
                zera_endereco = 1'b1;    // Reseta end da RAM
                estado_hex = 5'h2;
                next_state = GRAV_ESPERA_NOTA;
            end

            GRAV_ESPERA_NOTA: begin
                modo_ativo = 2'd2;
                estado_hex = 5'h2;
                if (mudou_modo) next_state = LIVRE;
                else if (tem_nota_ativa) next_state = GRAV_ARMAZENA;
            end

            GRAV_ARMAZENA: begin
                modo_ativo = 2'd2;
                estado_hex = 5'h2;
                escreve_ram = 1'b1; // Salva na RAM atual endereco
                next_state = GRAV_PROXIMO;
            end

            GRAV_PROXIMO: begin
                modo_ativo = 2'd2;
                estado_hex = 5'h2;
                conta_endereco = 1'b1; // vai pro proximo
                next_state = GRAV_SOLTAR;
            end

            GRAV_SOLTAR: begin
                modo_ativo = 2'd2;
                estado_hex = 5'h2;
                if (mudou_modo) next_state = LIVRE;
                else if (!tem_nota_ativa) begin
                    if (fim_musica) next_state = GRAV_ESPERA_NOTA; // Fim do espaco, ignora mais notas
                    else next_state = GRAV_ESPERA_NOTA;
                end
            end

            default: next_state = INICIAL;
        endcase
    end
endmodule
