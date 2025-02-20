section .data
    prompt_main_menu db "Menu principal:", 10
                db "1. Générer un mot de passe", 10
                db "2. Évaluer la force d'un mot de passe", 10
                db "3. Quitter", 10
                db "Choisissez une option (1-3): ", 0
    prompt_main_menu_len equ $ - prompt_main_menu

    prompt_length db "Entrez la longueur du mot de passe: ", 0
    prompt_length_len equ $ - prompt_length
    
    prompt_mode db "Mode de génération:", 10
                db "1. Simple (lettres et chiffres)", 10
                db "2. Avancé (avec caractères spéciaux)", 10
                db "Choisissez le mode (1-2): ", 0
    prompt_mode_len equ $ - prompt_mode
    
    prompt_enter_password db "Entrez un mot de passe à évaluer: ", 0
    prompt_enter_password_len equ $ - prompt_enter_password
    
    result_msg db "Mot de passe généré: ", 0
    result_msg_len equ $ - result_msg
    
    strength_weak db "Force du mot de passe: FAIBLE", 0
    strength_weak_len equ $ - strength_weak
    
    strength_medium db "Force du mot de passe: MOYENNE", 0
    strength_medium_len equ $ - strength_medium
    
    strength_strong db "Force du mot de passe: FORTE", 0
    strength_strong_len equ $ - strength_strong
    
    newline db 10, 0
    
    lowercase db "abcdefghijklmnopqrstuvwxyz", 0
    uppercase db "ABCDEFGHIJKLMNOPQRSTUVWXYZ", 0
    digits db "0123456789", 0
    special db "!@#$%^&*()-_=+[]{}|;:,.<>?/", 0
    
    lowercase_len equ 26
    uppercase_len equ 26
    digits_len equ 10
    special_len equ 30

section .bss
    mode_buffer resb 16
    length_buffer resb 16
    password_buffer resb 256
    password_length resq 1
    rand_seed resq 1
    selected_mode resq 1
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
    je generate_password
    cmp rax, 2
    je evaluate_password_strength
    cmp rax, 3
    je program_exit
    
    jmp main_loop

generate_password:
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
    
    jmp main_loop

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
    
    mov [password_strength], rax
    
    ; Définir le message de force selon le score
    cmp rax, 40
    jl strength_weak_label
    cmp rax, 60
    jl strength_medium_label
    
    mov rsi, strength_strong
    mov rdx, strength_strong_len
    jmp set_strength_result
    
strength_weak_label:
    mov rsi, strength_weak
    mov rdx, strength_weak_len
    jmp set_strength_result
    
strength_medium_label:
    mov rsi, strength_medium
    mov rdx, strength_medium_len
    
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