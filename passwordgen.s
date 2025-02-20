section .data
    prompt_main_menu db "Menu principal:", 10
                db "1. Générer un mot de passe", 10
                db "2. Quitter", 10
                db "Choisissez une option (1-2): ", 0
    prompt_main_menu_len equ $ - prompt_main_menu

    prompt_length db "Entrez la longueur du mot de passe: ", 0
    prompt_length_len equ $ - prompt_length
    
    result_msg db "Mot de passe généré: ", 0
    result_msg_len equ $ - result_msg
    
    newline db 10, 0
    
    lowercase db "abcdefghijklmnopqrstuvwxyz", 0
    uppercase db "ABCDEFGHIJKLMNOPQRSTUVWXYZ", 0
    digits db "0123456789", 0
    
    lowercase_len equ 26
    uppercase_len equ 26
    digits_len equ 10

section .bss
    mode_buffer resb 16
    length_buffer resb 16
    password_buffer resb 256
    password_length resq 1
    rand_seed resq 1

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
    je program_exit
    
    jmp main_loop

generate_password:
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