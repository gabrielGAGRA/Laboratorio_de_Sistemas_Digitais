import os
import re

def encode_note(note_str):
    note_str = note_str.strip()
    if not note_str:
        return None
    
    note_char = note_str[0].upper()
    sharp = '1' if '#' in note_str else '0'
    
    # Extract octave digits
    octave_str = "".join(filter(str.isdigit, note_str))
    
    if not octave_str:
        return '0000000' # Silence / Invalid
        
    octave = int(octave_str)
    
    note_map = {
        'C': '001',
        'D': '010',
        'E': '011',
        'F': '100',
        'G': '101',
        'A': '110',
        'B': '111',
    }
    
    if note_char not in note_map:
        return '0000000'
        
    # Convert octave to 3-bit binary
    octave_bin = format(octave, '03b')[-3:]
    
    return f"{octave_bin}{note_map[note_char]}{sharp}"

def main():
    # SETUP: Defina aqui o nome do arquivo de saida (onde a musica codificada sera salva)
    output_filename = "Homem_Aranha_1900.txt"
    
    # Caminhos
    current_dir = os.path.dirname(os.path.abspath(__file__))
    input_file = os.path.join(current_dir, "musica.txt")
    output_file = os.path.join(current_dir, output_filename)
    
    if not os.path.exists(input_file):
        print(f"Erro: Arquivo {input_file} nao encontrado.")
        return

    with open(input_file, 'r') as f:
        content = f.read()

    # Separa por virgulas e/ou quebras de linha
    tokens = content.replace('\n', ',').split(',')

    encoded_lines = []
    for t in tokens:
        enc = encode_note(t)
        if enc:
            encoded_lines.append(enc)

    # Preenche com 0000000 ate atingir 1024 linhas
    while len(encoded_lines) < 1024:
        encoded_lines.append("0000000")

    # Garante que tenha exatamente 1024 linhas
    encoded_lines = encoded_lines[:1024]

    with open(output_file, 'w') as f:
        f.write('\n'.join(encoded_lines) + '\n')

    print(f"Sucesso! Arquivo '{output_filename}' atualizado com {len(encoded_lines)} linhas de codigo binario.")

if __name__ == "__main__":
    main()
