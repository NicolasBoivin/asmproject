section .data
    prompt_main_menu db "Menu principal:", 10
                db "1. Générer un mot de passe standard", 10
                db "2. Générer un mot de passe prononçable", 10
                db "3. Générer un mot de passe sans caractères ambigus", 10
                db "4. Générer une phrase de passe", 10
                db "5. Évaluer la force d'un mot de passe", 10
                db "6. Quitter", 10
                db "Choisissez une option (1-6): ", 0
    prompt_main_menu_len equ $ - prompt_main_menu

    prompt_mode db "Mode de génération:", 10
                db "1. Simple (lettres et chiffres)", 10
                db "2. Avancé (avec caractères spéciaux)", 10
                db "Choisissez le mode (1-2): ", 0
    prompt_mode_len equ $ - prompt_mode
    
    prompt_length db "Entrez la longueur du mot de passe: ", 0
    prompt_length_len equ $ - prompt_length
    
    prompt_save db "Sauvegarder dans un fichier? (1=Oui, 0=Non): ", 0
    prompt_save_len equ $ - prompt_save
    
    prompt_words db "Entrez le nombre de mots pour la phrase de passe: ", 0
    prompt_words_len equ $ - prompt_words
    
    prompt_enter_password db "Entrez un mot de passe à évaluer: ", 0
    prompt_enter_password_len equ $ - prompt_enter_password
    
    result_msg db "Mot de passe généré: ", 0
    result_msg_len equ $ - result_msg
    
    save_success db "Mot de passe sauvegardé dans le fichier: ", 0
    save_success_len equ $ - save_success
    
    save_error db "Erreur lors de la sauvegarde du fichier.", 10, 0
    save_error_len equ $ - save_error
    
    dir_error db "Erreur lors de la création du dossier 'passlist'.", 10, 0
    dir_error_len equ $ - dir_error
    
    strength_weak db "Force du mot de passe: FAIBLE", 0
    strength_weak_len equ $ - strength_weak
    
    strength_medium db "Force du mot de passe: MOYENNE", 0
    strength_medium_len equ $ - strength_medium
    
    strength_strong db "Force du mot de passe: FORTE", 0
    strength_strong_len equ $ - strength_strong
    
    strength_very_strong db "Force du mot de passe: TRÈS FORTE", 0
    strength_very_strong_len equ $ - strength_very_strong
    
    dir_name db "passlist", 0
    file_path db "passlist/password.data", 0
    file_path_buffer times 100 db 0
    
    file_prefix db "passlist/password", 0
    file_suffix db ".data", 0
    file_counter dd 1
    max_attempts dd 1000
    
    test_file_path times 256 db 0
    
    newline db 10, 0
    
    lowercase db "abcdefghijklmnopqrstuvwxyz", 0
    uppercase db "ABCDEFGHIJKLMNOPQRSTUVWXYZ", 0
    digits db "0123456789", 0
    special db "!@#$%^&*()-_=+[]{}|;:,.<>?/", 0
    
    vowels db "aeiouy", 0
    consonants db "bcdfghjklmnpqrstvwxz", 0
    
    unambiguous_chars db "abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789#$%&*+-=?@", 0
    
    dict_words db "maison", 0, "voiture", 0, "table", 0, "chaise", 0, "arbre", 0
               db "montagne", 0, "soleil", 0, "lune", 0, "livre", 0, "stylo", 0
               db "ordinateur", 0, "téléphone", 0, "jardin", 0, "musique", 0, "fenêtre", 0
               db "porte", 0, "chemin", 0, "rivière", 0, "océan", 0, "forêt", 0
    dict_count equ 20
    
    lowercase_len equ 26
    uppercase_len equ 26
    digits_len equ 10
    special_len equ 30
    vowels_len equ 6
    consonants_len equ 20
    unambiguous_len equ 66

section .bss
    mode_buffer resb 16
    length_buffer resb 16
    save_buffer resb 16
    words_buffer resb 16
    password_buffer resb 256
    passphrase_buffer resb 512
    password_length resq 1
    words_count resq 1
    rand_seed resq 1
    selected_mode resq 1
    save_to_file resq 1
    file_descriptor resq 1
    counter_buffer resb 16
    password_strength resq 1
    strength_result resb 64
    strength_result_len resq 1

section .text
global _start

_start:
    call init_random
    
main_loop:
    mov rax, 1
    mov rdi, 1
    mov rsi, prompt_main_menu
    mov rdx, prompt_main_menu_len
    syscall
    
    mov rax, 0
    mov rdi, 0
    mov rsi, mode_buffer
    mov rdx, 16
    syscall
    
    mov rdi, mode_buffer
    call atoi
    
    cmp rax, 1
    je generate_standard_password
    cmp rax, 2
    je generate_pronounceable_password
    cmp rax, 3
    je generate_unambiguous_password
    cmp rax, 4
    je generate_passphrase
    cmp rax, 5
    je evaluate_password_strength
    cmp rax, 6
    je program_exit
    
    jmp main_loop

generate_standard_password:
    mov rax, 1
    mov rdi, 1
    mov rsi, prompt_mode
    mov rdx, prompt_mode_len
    syscall
    
    mov rax, 0
    mov rdi, 0
    mov rsi, mode_buffer
    mov rdx, 16
    syscall
    
    mov rdi, mode_buffer
    call atoi
    mov [selected_mode], rax
    
    mov rax, 1
    mov rdi, 1
    mov rsi, prompt_length
    mov rdx, prompt_length_len
    syscall
    
    mov rax, 0
    mov rdi, 0
    mov rsi, length_buffer
    mov rdx, 16
    syscall
    
    mov rdi, length_buffer
    call atoi
    mov [password_length], rax
    
    call generate_random_password
    
    mov rax, 1
    mov rdi, 1
    mov rsi, result_msg
    mov rdx, result_msg_len
    syscall
    
    mov rax, 1
    mov rdi, 1
    mov rsi, password_buffer
    mov rdx, [password_length]
    syscall
    
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    
    jmp ask_to_save

generate_pronounceable_password:
    mov rax, 1
    mov rdi, 1
    mov rsi, prompt_length
    mov rdx, prompt_length_len
    syscall
    
    mov rax, 0
    mov rdi, 0
    mov rsi, length_buffer
    mov rdx, 16
    syscall
    
    mov rdi, length_buffer
    call atoi
    mov [password_length], rax
    
    call generate_pronounceable
    
    mov rax, 1
    mov rdi, 1
    mov rsi, result_msg
    mov rdx, result_msg_len
    syscall
    
    mov rax, 1
    mov rdi, 1
    mov rsi, password_buffer
    mov rdx, [password_length]
    syscall
    
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    
    jmp ask_to_save

generate_unambiguous_password:
    mov rax, 1
    mov rdi, 1
    mov rsi, prompt_length
    mov rdx, prompt_length_len
    syscall
    
    mov rax, 0
    mov rdi, 0
    mov rsi, length_buffer
    mov rdx, 16
    syscall
    
    mov rdi, length_buffer
    call atoi
    mov [password_length], rax
    
    call generate_unambiguous_password_func
    
    mov rax, 1
    mov rdi, 1
    mov rsi, result_msg
    mov rdx, result_msg_len
    syscall
    
    mov rax, 1
    mov rdi, 1
    mov rsi, password_buffer
    mov rdx, [password_length]
    syscall
    
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    
    jmp ask_to_save

generate_passphrase:
    mov rax, 1
    mov rdi, 1
    mov rsi, prompt_words
    mov rdx, prompt_words_len
    syscall
    
    mov rax, 0
    mov rdi, 0
    mov rsi, words_buffer
    mov rdx, 16
    syscall
    
    mov rdi, words_buffer
    call atoi
    mov [words_count], rax
    
    call generate_passphrase_func
    
    mov rax, 1
    mov rdi, 1
    mov rsi, result_msg
    mov rdx, result_msg_len
    syscall
    
    mov rax, 1
    mov rdi, 1
    mov rsi, passphrase_buffer
    mov rdi, passphrase_buffer
    call strlen
    mov rdx, rax
    mov rsi, passphrase_buffer
    mov rdi, 1
    syscall
    
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    
    mov rsi, passphrase_buffer
    mov rdi, password_buffer
    call strcpy
    mov rdi, passphrase_buffer
    call strlen
    mov [password_length], rax
    
    jmp ask_to_save

evaluate_password_strength:
    mov rax, 1
    mov rdi, 1
    mov rsi, prompt_enter_password
    mov rdx, prompt_enter_password_len
    syscall
    
    mov rax, 0
    mov rdi, 0
    mov rsi, password_buffer
    mov rdx, 256
    syscall
    
    mov rdi, password_buffer
    call get_password_length
    mov [password_length], rax
    
    call calculate_strength
    
    mov rax, 1
    mov rdi, 1
    mov rsi, strength_result
    mov rdx, [strength_result_len]
    syscall
    
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    
    jmp main_loop

ask_to_save:
    mov rax, 1
    mov rdi, 1
    mov rsi, prompt_save
    mov rdx, prompt_save_len
    syscall
    
    mov rax, 0
    mov rdi, 0
    mov rsi, save_buffer
    mov rdx, 16
    syscall
    
    mov rdi, save_buffer
    call atoi
    mov [save_to_file], rax
    
    cmp qword [save_to_file], 1
    jne main_loop
    call save_to_file_function
    
    jmp main_loop

program_exit:
    mov rax, 60
    xor rdi, rdi
    syscall

init_random:
    push rbx
    push rcx
    
    mov rax, 201
    xor rdi, rdi
    syscall
    
    mov [rand_seed], rax
    
    pop rcx
    pop rbx
    ret

random:
    push rbx
    push rcx
    push rdx
    
    mov rax, [rand_seed]
    mov rbx, 1103515245
    mul rbx
    add rax, 12345
    mov [rand_seed], rax
    
    mov rcx, rax
    shr rcx, 16
    and rcx, 0x7FFFFFFF
    
    mov rax, rcx
    
    pop rdx
    pop rcx
    pop rbx
    ret

random_range:
    push rbx
    push rdx
    
    mov rbx, rax
    call random
    xor rdx, rdx
    div rbx
    mov rax, rdx
    
    pop rdx
    pop rbx
    ret

atoi:
    push rbx
    push rcx
    push rdx
    push rsi
    
    mov rsi, rdi
    xor rax, rax
    xor rcx, rcx
    
atoi_loop:
    movzx rbx, byte [rsi + rcx]
    cmp rbx, 0
    je atoi_done
    cmp rbx, 10
    je atoi_done
    cmp rbx, '0'
    jl atoi_next
    cmp rbx, '9'
    jg atoi_next
    
    mov rdx, rax
    shl rax, 3
    add rax, rdx
    add rax, rdx
    
    sub rbx, '0'
    add rax, rbx
    
atoi_next:
    inc rcx
    jmp atoi_loop
    
atoi_done:
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret

strlen:
    push rcx
    push rdi
    
    mov rdi, rsi
    xor rcx, rcx
    not rcx
    xor al, al
    cld
    repne scasb
    not rcx
    dec rcx
    mov rax, rcx
    
    pop rdi
    pop rcx
    ret

strcpy:
    push rax
    push rsi
    push rdi
    push rdx
    
    mov rdx, rdi
    
strcpy_loop:
    mov al, [rsi]
    mov [rdi], al
    inc rsi
    inc rdi
    test al, al
    jnz strcpy_loop
    
    mov rdi, rdx
    
    pop rdx
    pop rdi
    pop rsi
    pop rax
    ret

strcat:
    push rax
    push rsi
    push rdi
    push rdx
    
    mov rdx, rdi
    
strcat_find_end:
    mov al, [rdi]
    test al, al
    jz strcat_copy
    inc rdi
    jmp strcat_find_end
    
strcat_copy:
    mov al, [rsi]
    mov [rdi], al
    inc rsi
    inc rdi
    test al, al
    jnz strcat_copy
    
    mov rdi, rdx
    
    pop rdx
    pop rdi
    pop rsi
    pop rax
    ret

itoa:
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    
    mov rbx, 10
    mov rcx, rdi
    
    test rax, rax
    jnz itoa_convert
    mov byte [rdi], '0'
    inc rdi
    jmp itoa_end
    
itoa_convert:
    xor rsi, rsi
    
itoa_loop:
    xor rdx, rdx
    div rbx
    add dl, '0'
    push rdx
    inc rsi
    test rax, rax
    jnz itoa_loop
    
itoa_reverse:
    pop rdx
    mov [rdi], dl
    inc rdi
    dec rsi
    jnz itoa_reverse
    
itoa_end:
    mov byte [rdi], 0
    
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret

generate_random_password:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    
    mov rdi, password_buffer
    mov rcx, [password_length]
    xor rax, rax
    cld
    rep stosb
    
    mov rdi, password_buffer
    
    xor rcx, rcx
    
fill_password:
    cmp rcx, [password_length]
    jge password_complete
    
    cmp qword [selected_mode], 1
    je simple_mode
    
    ; Mode avancé (avec caractères spéciaux)
    mov rax, 4   ; 4 types de caractères (minuscules, majuscules, chiffres, spéciaux)
    call random_range
    
    cmp rax, 0
    je add_lowercase
    cmp rax, 1
    je add_uppercase
    cmp rax, 2
    je add_digit
    jmp add_special
    
simple_mode:
    ; Mode simple (sans caractères spéciaux)
    mov rax, 3   ; 3 types de caractères (minuscules, majuscules, chiffres)
    call random_range
    
    cmp rax, 0
    je add_lowercase
    cmp rax, 1
    je add_uppercase
    jmp add_digit
    
add_lowercase:
    mov rax, lowercase_len
    call random_range
    movzx rbx, byte [lowercase + rax]
    jmp add_char
    
add_uppercase:
    mov rax, uppercase_len
    call random_range
    movzx rbx, byte [uppercase + rax]
    jmp add_char
    
add_digit:
    mov rax, digits_len
    call random_range
    movzx rbx, byte [digits + rax]
    jmp add_char
    
add_special:
    mov rax, special_len
    call random_range
    movzx rbx, byte [special + rax]
    
add_char:
    mov byte [password_buffer + rcx], bl
    
    inc rcx
    jmp fill_password
    
password_complete:
    mov rcx, [password_length]
    mov byte [password_buffer + rcx], 0
    
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

generate_pronounceable:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push r8
    
    mov rdi, password_buffer
    mov rcx, [password_length]
    xor rax, rax
    cld
    rep stosb
    
    mov rdi, password_buffer
    
    xor rcx, rcx
    mov r8, 0  ; Alternance voyelle/consonne (0 = consonne, 1 = voyelle)
    
pronounce_loop:
    cmp rcx, [password_length]
    jge pronounce_complete
    
    test r8, r8
    jz add_consonant_p
    
    mov rax, vowels_len
    call random_range
    movzx rbx, byte [vowels + rax]
    mov byte [password_buffer + rcx], bl
    xor r8, 1
    jmp next_char_p
    
add_consonant_p:
    mov rax, consonants_len
    call random_range
    movzx rbx, byte [consonants + rax]
    mov byte [password_buffer + rcx], bl
    xor r8, 1
    
next_char_p:
    inc rcx
    jmp pronounce_loop
    
pronounce_complete:
    mov rcx, [password_length]
    mov byte [password_buffer + rcx], 0
    
    ; Ajouter quelques chiffres pour augmenter la sécurité
    cmp qword [password_length], 6
    jl no_digits_needed
    
    mov rcx, 2
    
add_pronounce_digits:
    mov rax, [password_length]
    call random_range
    
    push rax
    mov rax, digits_len
    call random_range
    movzx rbx, byte [digits + rax]
    pop rax
    
    mov byte [password_buffer + rax], bl
    
    dec rcx
    jnz add_pronounce_digits
    
no_digits_needed:
    pop r8
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

generate_unambiguous_password_func:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    
    mov rdi, password_buffer
    mov rcx, [password_length]
    xor rax, rax
    cld
    rep stosb
    
    mov rdi, password_buffer
    
    xor rcx, rcx
    
fill_unambiguous:
    cmp rcx, [password_length]
    jge unambiguous_complete
    
    mov rax, unambiguous_len
    call random_range
    movzx rbx, byte [unambiguous_chars + rax]
    
    mov byte [password_buffer + rcx], bl
    
    inc rcx
    jmp fill_unambiguous
    
unambiguous_complete:
    mov rcx, [password_length]
    mov byte [password_buffer + rcx], 0
    
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

generate_passphrase_func:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push r8
    push r9
    
    mov rdi, passphrase_buffer
    mov rcx, 512
    xor rax, rax
    cld
    rep stosb
    
    mov rdi, passphrase_buffer
    
    mov rcx, [words_count]
    test rcx, rcx
    jz phrase_complete
    
    dec rcx
    call add_random_word
    
phrase_loop:
    test rcx, rcx
    jz phrase_complete
    
    mov rax, special_len
    call random_range
    movzx rbx, byte [special + rax]
    mov [rdi], bl
    inc rdi
    
    call add_random_word
    
    dec rcx
    jmp phrase_loop
    
phrase_complete:
    mov byte [rdi], 0
    
    pop r9
    pop r8
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

add_random_word:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    
    mov rax, dict_count
    call random_range
    
    mov rcx, rax
    mov rsi, dict_words
    
find_word_loop:
    test rcx, rcx
    jz found_word
    
find_next_word:
    cmp byte [rsi], 0
    je word_boundary
    inc rsi
    jmp find_next_word
    
word_boundary:
    inc rsi
    dec rcx
    jmp find_word_loop
    
found_word:
copy_word_loop:
    mov al, [rsi]
    test al, al
    jz copy_word_done
    mov [rdi], al
    inc rsi
    inc rdi
    jmp copy_word_loop
    
copy_word_done:
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

get_password_length:
    push rbx
    push rcx
    
    xor rcx, rcx
get_length_loop:
    movzx rbx, byte [rdi + rcx]
    cmp rbx, 0
    je get_length_done
    cmp rbx, 10
    je get_length_newline
    inc rcx
    jmp get_length_loop
    
get_length_newline:
    mov byte [rdi + rcx], 0
    
get_length_done:
    mov rax, rcx
    
    pop rcx
    pop rbx
    ret

calculate_strength:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push r8
    push r9
    push r10
    push r11
    
    xor r8, r8   ; Compteur de minuscules
    xor r9, r9   ; Compteur de majuscules
    xor r10, r10 ; Compteur de chiffres
    xor r11, r11 ; Compteur de caractères spéciaux
    
    xor rcx, rcx
strength_loop:
    cmp rcx, [password_length]
    jge strength_calc
    
    movzx rax, byte [password_buffer + rcx]
    
    cmp rax, 'a'
    jl not_lowercase_s
    cmp rax, 'z'
    jg not_lowercase_s
    inc r8
    jmp next_char_s
    
not_lowercase_s:
    cmp rax, 'A'
    jl not_uppercase_s
    cmp rax, 'Z'
    jg not_uppercase_s
    inc r9
    jmp next_char_s
    
not_uppercase_s:
    cmp rax, '0'
    jl not_digit_s
    cmp rax, '9'
    jg not_digit_s
    inc r10
    jmp next_char_s
    
not_digit_s:
    inc r11
    
next_char_s:
    inc rcx
    jmp strength_loop
    
strength_calc:
    ; Score de base: longueur * 4
    mov rax, [password_length]
    shl rax, 2
    
    ; Bonus pour les minuscules
    test r8, r8
    jz no_lower_points
    add rax, 10
no_lower_points:
    
    ; Bonus pour les majuscules
    test r9, r9
    jz no_upper_points
    add rax, 10
no_upper_points:
    
    ; Bonus pour les chiffres
    test r10, r10
    jz no_digit_points
    add rax, 10
no_digit_points:
    
    ; Bonus pour les caractères spéciaux
    test r11, r11
    jz no_special_points
    add rax, 15
no_special_points:
    
    ; Bonus pour le mélange de tous les types
    test r8, r8
    jz no_mix_bonus
    test r9, r9
    jz no_mix_bonus
    test r10, r10
    jz no_mix_bonus
    add rax, 15
no_mix_bonus:
    
    mov [password_strength], rax
    
    ; Définir le message de force selon le score
    cmp rax, 40
    jl strength_weak_label
    cmp rax, 60
    jl strength_medium_label
    cmp rax, 80
    jl strength_strong_label
    
    mov rsi, strength_very_strong
    mov rdx, strength_very_strong_len
    jmp set_strength_result
    
strength_weak_label:
    mov rsi, strength_weak
    mov rdx, strength_weak_len
    jmp set_strength_result
    
strength_medium_label:
    mov rsi, strength_medium
    mov rdx, strength_medium_len
    jmp set_strength_result
    
strength_strong_label:
    mov rsi, strength_strong
    mov rdx, strength_strong_len
    
set_strength_result:
    mov rdi, strength_result
    mov rcx, rdx
    cld
    rep movsb
    mov [strength_result_len], rdx
    
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

save_to_file_function:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    
    ; Créer le dossier passlist
    mov rax, 83    ; mkdir
    mov rdi, dir_name
    mov rsi, 0755  ; permissions
    syscall
    
    ; Ignorer l'erreur si le dossier existe déjà
    cmp rax, -17   ; EEXIST (erreur "existe déjà")
    je find_available_filename
    test rax, rax
    js mkdir_error
    
find_available_filename:
    mov dword [file_counter], 1
    
try_next_filename:
    mov ecx, [file_counter]
    cmp ecx, [max_attempts]
    jg file_error
    
    mov rsi, file_prefix
    mov rdi, test_file_path
    call strcpy
    
    mov eax, [file_counter]
    mov rdi, counter_buffer
    call itoa
    
    mov rsi, counter_buffer
    mov rdi, test_file_path
    call strcat
    
    mov rsi, file_suffix
    mov rdi, test_file_path
    call strcat
    
    mov rax, 2     ; open
    mov rdi, test_file_path
    mov rsi, 0     ; O_RDONLY
    xor rdx, rdx   ; mode (non utilisé)
    syscall
    
    test rax, rax
    js file_not_exists
    
    mov rdi, rax   ; descripteur de fichier
    mov rax, 3     ; close
    syscall
    
    inc dword [file_counter]
    jmp try_next_filename
    
file_not_exists:
    mov rsi, test_file_path
    mov rdi, file_path_buffer
    call strcpy
    
    mov rax, 85    ; creat
    mov rdi, file_path_buffer
    mov rsi, 0644  ; permissions
    syscall
    
    test rax, rax
    js file_error
    
    mov [file_descriptor], rax
    
    mov rax, 1     ; write
    mov rdi, [file_descriptor]
    mov rsi, password_buffer
    mov rdx, [password_length]
    syscall
    
    mov rax, 3     ; close
    mov rdi, [file_descriptor]
    syscall
    
    mov rax, 1
    mov rdi, 1
    mov rsi, save_success
    mov rdx, save_success_len
    syscall
    
    mov rax, 1
    mov rdi, 1
    mov rsi, file_path_buffer
    mov rdi, file_path_buffer
    call strlen
    mov rdx, rax
    mov rsi, file_path_buffer
    mov rdi, 1
    syscall
    
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    
    jmp save_done
    
mkdir_error:
    mov rax, 1
    mov rdi, 1
    mov rsi, dir_error
    mov rdx, dir_error_len
    syscall
    jmp save_done
    
file_error:
    mov rax, 1
    mov rdi, 1
    mov rsi, save_error
    mov rdx, save_error_len
    syscall
    
save_done:
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret