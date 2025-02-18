section .data
    ; Messages
    prompt_mode db "Mode de génération:", 10
                db "1. Mode personnalisé (longueur et nombre de chiffres)", 10
                db "2. Mot de passe fort (>=12 caractères, mélange de tous les types)", 10
                db "3. Mot de passe moyen (8-10 caractères, lettres et chiffres)", 10
                db "4. Mot de passe faible (6 caractères, principalement lettres)", 10
                db "Choisissez le mode (1-4): ", 0
    prompt_mode_len equ $ - prompt_mode
    
    prompt_length db "Entrez la longueur du mot de passe: ", 0
    prompt_length_len equ $ - prompt_length
    
    prompt_digits db "Entrez le nombre de chiffres souhaité: ", 0
    prompt_digits_len equ $ - prompt_digits
    
    prompt_save db "Sauvegarder dans un fichier? (1=Oui, 0=Non): ", 0
    prompt_save_len equ $ - prompt_save
    
    result_msg db "Mot de passe généré: ", 0
    result_msg_len equ $ - result_msg
    
    clipboard_success db "Mot de passe copié dans le presse-papier!", 10, 0
    clipboard_success_len equ $ - clipboard_success
    
    save_success db "Mot de passe sauvegardé dans le fichier: ", 0
    save_success_len equ $ - save_success
    
    save_error db "Erreur lors de la sauvegarde du fichier.", 10, 0
    save_error_len equ $ - save_error
    
    dir_error db "Erreur lors de la création du dossier 'passlist'.", 10, 0
    dir_error_len equ $ - dir_error
    
    dir_name db "passlist", 0
    file_path db "passlist/password.data", 0
    file_path_buffer times 100 db 0
    
    ; Ajout pour la gestion des fichiers séquentiels
    file_prefix db "passlist/password", 0
    file_suffix db ".data", 0
    file_counter dd 1            ; Compteur de fichiers commençant à 1
    max_attempts dd 1000         ; Nombre maximum de tentatives
    
    ; Tampon pour construire et tester les noms de fichiers
    test_file_path times 256 db 0
    
    newline db 10, 0
    
    ; Caractères possibles pour le mot de passe
    lowercase db "abcdefghijklmnopqrstuvwxyz", 0
    uppercase db "ABCDEFGHIJKLMNOPQRSTUVWXYZ", 0
    digits db "0123456789", 0
    special db "!@#$%^&*()-_=+[]{}|;:,.<>?/", 0
    
    ; Longueurs des ensembles de caractères
    lowercase_len equ 26
    uppercase_len equ 26
    digits_len equ 10
    special_len equ 30
    
    ; Paramètres prédéfinis pour les modes
    ; [longueur, nombre de chiffres, %minuscules, %majuscules, %spéciaux]
    mode_strong dq 14, 4, 30, 30, 40   ; Fort: 14 caractères, 4 chiffres, distribution variée
    mode_medium dq 10, 3, 50, 40, 10   ; Moyen: 10 caractères, 3 chiffres, moins de spéciaux
    mode_weak dq 6, 1, 80, 19, 1       ; Faible: 6 caractères, 1 chiffre, principalement minuscules
    
    ; Commande pour xclip (copier dans le presse-papier sous Linux)
    xclip_cmd db "echo -n '", 0
    xclip_end db "' | xclip -selection clipboard", 0
    
    ; Tampon pour construire la commande du presse-papier
    clipboard_cmd_buffer times 512 db 0
    
    ; Données supplémentaires pour les fonctions
    shell_path db "/bin/sh", 0
    shell_c_arg db "-c", 0
    passwd_prefix db "password_", 0
    data_ext db ".data", 0

section .bss
    mode_buffer resb 16
    length_buffer resb 16
    digits_buffer resb 16
    save_buffer resb 16
    password_buffer resb 256
    password_length resq 1
    digits_count resq 1
    lowercase_weight resq 1
    uppercase_weight resq 1
    special_weight resq 1
    rand_seed resq 1
    selected_mode resq 1
    save_to_file resq 1
    file_descriptor resq 1
    date_buffer resb 32
    timestamp resq 1
    counter_buffer resb 16

section .text
global _start

_start:
    ; Initialiser le générateur de nombres aléatoires
    call init_random
    
    ; Demander le mode de génération
    mov rax, 1                  ; syscall write
    mov rdi, 1                  ; stdout
    mov rsi, prompt_mode        ; message
    mov rdx, prompt_mode_len    ; longueur
    syscall
    
    ; Lire le mode choisi
    mov rax, 0                  ; syscall read
    mov rdi, 0                  ; stdin
    mov rsi, mode_buffer        ; buffer
    mov rdx, 16                 ; taille maximale
    syscall
    
    ; Convertir la chaîne en nombre
    mov rdi, mode_buffer
    call atoi
    mov [selected_mode], rax
    
    ; Traiter selon le mode choisi
    cmp rax, 1
    je custom_mode
    cmp rax, 2
    je strong_mode
    cmp rax, 3
    je medium_mode
    cmp rax, 4
    je weak_mode
    
    ; Par défaut, utiliser le mode personnalisé
    jmp custom_mode

custom_mode:
    ; Demander la longueur du mot de passe
    mov rax, 1                  ; syscall write
    mov rdi, 1                  ; stdout
    mov rsi, prompt_length      ; message
    mov rdx, prompt_length_len  ; longueur
    syscall
    
    ; Lire la longueur
    mov rax, 0                  ; syscall read
    mov rdi, 0                  ; stdin
    mov rsi, length_buffer      ; buffer
    mov rdx, 16                 ; taille maximale
    syscall
    
    ; Convertir la chaîne en nombre
    mov rdi, length_buffer
    call atoi
    mov [password_length], rax
    
    ; Demander le nombre de chiffres
    mov rax, 1                  ; syscall write
    mov rdi, 1                  ; stdout
    mov rsi, prompt_digits      ; message
    mov rdx, prompt_digits_len  ; longueur
    syscall
    
    ; Lire le nombre de chiffres
    mov rax, 0                  ; syscall read
    mov rdi, 0                  ; stdin
    mov rsi, digits_buffer      ; buffer
    mov rdx, 16                 ; taille maximale
    syscall
    
    ; Convertir la chaîne en nombre
    mov rdi, digits_buffer
    call atoi
    mov [digits_count], rax
    
    ; Distribution équitable par défaut pour le mode personnalisé
    mov qword [lowercase_weight], 33
    mov qword [uppercase_weight], 33
    mov qword [special_weight], 34
    
    jmp validate_params

strong_mode:
    ; Paramètres pour mot de passe fort
    mov rax, [mode_strong]
    mov [password_length], rax
    mov rax, [mode_strong+8]
    mov [digits_count], rax
    mov rax, [mode_strong+16]
    mov [lowercase_weight], rax
    mov rax, [mode_strong+24]
    mov [uppercase_weight], rax
    mov rax, [mode_strong+32]
    mov [special_weight], rax
    jmp validate_params

medium_mode:
    ; Paramètres pour mot de passe moyen
    mov rax, [mode_medium]
    mov [password_length], rax
    mov rax, [mode_medium+8]
    mov [digits_count], rax
    mov rax, [mode_medium+16]
    mov [lowercase_weight], rax
    mov rax, [mode_medium+24]
    mov [uppercase_weight], rax
    mov rax, [mode_medium+32]
    mov [special_weight], rax
    jmp validate_params

weak_mode:
    ; Paramètres pour mot de passe faible
    mov rax, [mode_weak]
    mov [password_length], rax
    mov rax, [mode_weak+8]
    mov [digits_count], rax
    mov rax, [mode_weak+16]
    mov [lowercase_weight], rax
    mov rax, [mode_weak+24]
    mov [uppercase_weight], rax
    mov rax, [mode_weak+32]
    mov [special_weight], rax
    jmp validate_params

validate_params:
    ; Vérifier que le nombre de chiffres n'est pas supérieur à la longueur totale
    mov rax, [digits_count]
    cmp rax, [password_length]
    jle ask_save
    
    ; Si nombre de chiffres > longueur totale, on ajuste
    mov rax, [password_length]
    mov [digits_count], rax

ask_save:
    ; Demander si l'utilisateur veut sauvegarder le mot de passe
    mov rax, 1                  ; syscall write
    mov rdi, 1                  ; stdout
    mov rsi, prompt_save        ; message
    mov rdx, prompt_save_len    ; longueur
    syscall
    
    ; Lire la réponse
    mov rax, 0                  ; syscall read
    mov rdi, 0                  ; stdin
    mov rsi, save_buffer        ; buffer
    mov rdx, 16                 ; taille maximale
    syscall
    
    ; Convertir la chaîne en nombre
    mov rdi, save_buffer
    call atoi
    mov [save_to_file], rax
    
generate_password:
    ; Générer le mot de passe
    call generate_random_password
    
    ; Afficher le message de résultat
    mov rax, 1                  ; syscall write
    mov rdi, 1                  ; stdout
    mov rsi, result_msg         ; message
    mov rdx, result_msg_len     ; longueur
    syscall
    
    ; Afficher le mot de passe généré
    mov rax, 1                  ; syscall write
    mov rdi, 1                  ; stdout
    mov rsi, password_buffer    ; mot de passe
    mov rdx, [password_length]  ; longueur
    syscall
    
    ; Nouvelle ligne
    mov rax, 1                  ; syscall write
    mov rdi, 1                  ; stdout
    mov rsi, newline            ; caractère nouvelle ligne
    mov rdx, 1                  ; longueur
    syscall
    
    ; Copier le mot de passe dans le presse-papier
    call copy_to_clipboard
    
    ; Si l'utilisateur veut sauvegarder, écrire dans un fichier
    cmp qword [save_to_file], 1
    jne program_exit
    call save_to_file_function
    
program_exit:
    ; Fin du programme
    mov rax, 60                 ; syscall exit
    xor rdi, rdi                ; code de retour 0
    syscall

; Fonction pour initialiser le générateur de nombres aléatoires
init_random:
    push rbx
    push rcx
    
    ; Utiliser le temps système comme graine
    mov rax, 201               ; syscall time
    xor rdi, rdi               ; NULL
    syscall
    
    ; Utiliser le temps comme graine
    mov [rand_seed], rax
    mov [timestamp], rax
    
    pop rcx
    pop rbx
    ret

; Fonction pour générer un nombre aléatoire
; Retourne un nombre aléatoire dans rax
random:
    push rbx
    push rcx
    push rdx
    
    ; Utiliser un algorithme linéaire congruent
    mov rax, [rand_seed]
    mov rbx, 1103515245
    mul rbx
    add rax, 12345
    mov [rand_seed], rax
    
    ; Normaliser dans la plage souhaitée
    mov rcx, rax
    shr rcx, 16    ; Prendre les bits de poids fort
    and rcx, 0x7FFFFFFF
    
    mov rax, rcx
    
    pop rdx
    pop rcx
    pop rbx
    ret

; Fonction pour générer un nombre aléatoire dans une plage 0..(max-1)
; Paramètre: rax = max
; Retourne: rax = nombre aléatoire
random_range:
    push rbx
    push rdx
    
    mov rbx, rax    ; Sauvegarder max dans rbx
    call random     ; Obtenir un nombre aléatoire dans rax
    xor rdx, rdx    ; Préparer la division
    div rbx         ; rax / rbx
    mov rax, rdx    ; Utiliser le reste comme résultat (0..(max-1))
    
    pop rdx
    pop rbx
    ret

; Fonction pour convertir une chaîne ASCII en entier
; Paramètre: rdi = adresse de la chaîne
; Retourne: rax = valeur entière
atoi:
    push rbx
    push rcx
    push rdx
    push rsi
    
    mov rsi, rdi    ; Adresse de la chaîne
    xor rax, rax    ; Réinitialiser le résultat
    xor rcx, rcx    ; Compteur de caractères
    
atoi_loop:
    movzx rbx, byte [rsi + rcx]  ; Lire un caractère
    cmp rbx, 0                   ; Fin de chaîne ?
    je atoi_done
    cmp rbx, 10                  ; Saut de ligne ?
    je atoi_done
    cmp rbx, '0'                 ; Vérifier que c'est un chiffre
    jl atoi_next
    cmp rbx, '9'
    jg atoi_next
    
    ; Multiplier le résultat actuel par 10
    mov rdx, rax
    shl rax, 3         ; rax * 8
    add rax, rdx       ; + rax * 1 = rax * 9
    add rax, rdx       ; + rax * 1 = rax * 10
    
    ; Ajouter le nouveau chiffre
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

; Fonction pour choisir un type de caractère selon les poids définis
; Retourne dans rax: 1=minuscule, 2=majuscule, 3=spécial
choose_char_type:
    push rbx
    push rcx
    push rdx
    
    ; Calculer la somme totale des poids
    mov rcx, [lowercase_weight]
    add rcx, [uppercase_weight]
    add rcx, [special_weight]
    
    ; Générer un nombre entre 0 et (somme_poids - 1)
    mov rax, rcx
    call random_range
    
    ; Déterminer le type de caractère selon le nombre généré
    cmp rax, [lowercase_weight]
    jl choose_lowercase
    
    sub rax, [lowercase_weight]
    cmp rax, [uppercase_weight]
    jl choose_uppercase
    
    ; Si on arrive ici, c'est un caractère spécial
    mov rax, 3
    jmp choose_done
    
choose_lowercase:
    mov rax, 1
    jmp choose_done
    
choose_uppercase:
    mov rax, 2
    
choose_done:
    pop rdx
    pop rcx
    pop rbx
    ret

; Fonction pour générer un mot de passe aléatoire
generate_random_password:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    
    ; Effacer le tampon du mot de passe
    mov rdi, password_buffer
    mov rcx, [password_length]
    xor rax, rax
    cld
    rep stosb
    
    ; Remettre le pointeur au début
    mov rdi, password_buffer
    
    ; D'abord, ajouter le nombre requis de chiffres
    mov rcx, [digits_count]
    test rcx, rcx
    jz skip_digits
    
add_digits_loop:
    ; Choisir une position aléatoire dans le mot de passe
    mov rax, [password_length]
    call random_range
    
    ; Vérifier si cette position est déjà occupée
    cmp byte [password_buffer + rax], 0
    jne add_digits_loop
    
    ; Choisir un chiffre aléatoire
    mov rax, digits_len
    call random_range
    movzx rbx, byte [digits + rax]
    
    ; Placer le chiffre à la position choisie
    mov byte [password_buffer + rax], bl
    
    dec rcx
    jnz add_digits_loop
    
skip_digits:
    ; Ensuite, remplir les positions restantes avec des caractères variés
    xor rcx, rcx
    
fill_remaining:
    cmp rcx, [password_length]
    jge password_complete
    
    ; Vérifier si cette position est déjà occupée
    cmp byte [password_buffer + rcx], 0
    jne next_position
    
    ; Choisir aléatoirement le type de caractère selon les poids
    call choose_char_type
    
    cmp rax, 1
    je add_lowercase
    cmp rax, 2
    je add_uppercase
    jmp add_special
    
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
    
add_special:
    mov rax, special_len
    call random_range
    movzx rbx, byte [special + rax]
    
add_char:
    mov byte [password_buffer + rcx], bl
    
next_position:
    inc rcx
    jmp fill_remaining
    
password_complete:
    ; Ajouter un octet nul à la fin du mot de passe
    mov rcx, [password_length]
    mov byte [password_buffer + rcx], 0
    
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

; Fonction pour copier le mot de passe dans le presse-papier (utilise xclip sous Linux)
copy_to_clipboard:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    
    ; Préparer la commande: echo -n 'motdepasse' | xclip -selection clipboard
    
    ; Copier la première partie de la commande
    mov rsi, xclip_cmd
    mov rdi, clipboard_cmd_buffer
    call strcpy
    
    ; Ajouter le mot de passe
    mov rsi, password_buffer
    mov rdi, clipboard_cmd_buffer
    call strcat
    
    ; Ajouter la fin de la commande
    mov rsi, xclip_end
    mov rdi, clipboard_cmd_buffer
    call strcat
    
    ; Exécuter la commande avec system call (fork + execve)
    mov rdi, clipboard_cmd_buffer
    call system
    
    ; Afficher message de succès
    mov rax, 1                  ; syscall write
    mov rdi, 1                  ; stdout
    mov rsi, clipboard_success  ; message
    mov rdx, clipboard_success_len  ; longueur
    syscall
    
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

; Fonction pour sauvegarder le mot de passe dans un fichier
save_to_file_function:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    
    ; Créer le dossier 'passlist' s'il n'existe pas
    mov rax, 83                  ; syscall mkdir
    mov rdi, dir_name            ; nom du dossier
    mov rsi, 0755                ; permissions (rwxr-xr-x)
    syscall
    
    ; Ignorer l'erreur si le dossier existe déjà
    cmp rax, -17                 ; EEXIST
    je find_available_filename
    test rax, rax                ; Vérifier si autre erreur
    js mkdir_error               ; Si erreur, afficher message
    
find_available_filename:
    ; Initialiser le compteur à 1
    mov dword [file_counter], 1
    
try_next_filename:
    ; Vérifier si on a dépassé le nombre maximum de tentatives
    mov ecx, [file_counter]
    cmp ecx, [max_attempts]
    jg file_error
    
    ; Construire le nom de fichier: passlist/passwordX.data
    ; Copier le préfixe du chemin
    mov rsi, file_prefix
    mov rdi, test_file_path
    call strcpy
    
    ; Convertir le compteur en chaîne
    mov eax, [file_counter]
    mov rdi, counter_buffer
    call itoa
    
    ; Ajouter le numéro au nom du fichier
    mov rsi, counter_buffer
    call strcat
    
    ; Ajouter l'extension
    mov rsi, file_suffix
    call strcat
    
    ; Vérifier si le fichier existe déjà en essayant de l'ouvrir
    mov rax, 2                   ; syscall open
    mov rdi, test_file_path      ; nom du fichier
    mov rsi, 0                   ; flags (O_RDONLY)
    xor rdx, rdx                 ; mode (non utilisé avec O_RDONLY)
    syscall
    
    ; Si rax >= 0, le fichier existe
    test rax, rax
    js file_not_exists           ; Si erreur (probablement ENOENT), le fichier n'existe pas
    
    ; Le fichier existe, fermer le descripteur
    mov rdi, rax
    mov rax, 3                   ; syscall close
    syscall
    
    ; Incrémenter le compteur et essayer le prochain nom
    inc dword [file_counter]
    jmp try_next_filename
    
file_not_exists:
    ; Le fichier n'existe pas, on peut l'utiliser
    ; Copier le nom du fichier dans file_path_buffer pour l'utiliser plus tard
    mov rsi, test_file_path
    mov rdi, file_path_buffer
    call strcpy
    
    ; Créer le fichier
    mov rax, 85                  ; syscall creat
    mov rdi, file_path_buffer    ; nom du fichier
    mov rsi, 0644                ; permissions (rw-r--r--)
    syscall
    
    ; Vérifier erreur
    test rax, rax
    js file_error
    
    ; Sauvegarder le descripteur de fichier
    mov [file_descriptor], rax
    
    ; Écrire le mot de passe dans le fichier
    mov rax, 1                   ; syscall write
    mov rdi, [file_descriptor]   ; descripteur de fichier
    mov rsi, password_buffer     ; buffer
    mov rdx, [password_length]   ; longueur
    syscall
    
    ; Fermer le fichier
    mov rax, 3                   ; syscall close
    mov rdi, [file_descriptor]   ; descripteur de fichier
    syscall
    
    ; Afficher message de succès
    mov rax, 1                   ; syscall write
    mov rdi, 1                   ; stdout
    mov rsi, save_success        ; message
    mov rdx, save_success_len    ; longueur
    syscall
    
    ; Afficher le nom du fichier
    mov rax, 1                   ; syscall write
    mov rdi, 1                   ; stdout
    mov rsi, file_path_buffer    ; nom du fichier
    call strlen                  ; calculer la longueur
    mov rdx, rax                 ; longueur
    syscall
    
    ; Nouvelle ligne
    mov rax, 1                   ; syscall write
    mov rdi, 1                   ; stdout
    mov rsi, newline             ; caractère nouvelle ligne
    mov rdx, 1                   ; longueur
    syscall
    
    jmp save_done
    
mkdir_error:
    mov rax, 1                   ; syscall write
    mov rdi, 1                   ; stdout
    mov rsi, dir_error           ; message
    mov rdx, dir_error_len       ; longueur
    syscall
    jmp save_done
    
file_error:
    mov rax, 1                   ; syscall write
    mov rdi, 1                   ; stdout
    mov rsi, save_error          ; message
    mov rdx, save_error_len      ; longueur
    syscall
    
save_done:
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

; Fonction pour copier une chaîne
; rsi = source, rdi = destination
; Retourne: rdi = fin de la chaîne destination
strcpy:
    push rax
    
strcpy_loop:
    mov al, [rsi]
    mov [rdi], al
    inc rsi
    inc rdi
    test al, al
    jnz strcpy_loop
    dec rdi     ; Pointer sur le caractère nul
    
    pop rax
    ret

; Fonction pour concaténer une chaîne
; rsi = source, rdi = destination (doit pointer vers une chaîne terminée par un zéro)
; Retourne: rdi = fin de la chaîne concaténée
strcat:
    push rax
    
    ; Trouver la fin de la chaîne destination
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
    dec rdi     ; Pointer sur le caractère nul
    
    pop rax
    ret

; Fonction pour calculer la longueur d'une chaîne
; rsi = chaîne
; Retourne: rax = longueur (sans le caractère nul)
strlen:
    push rcx
    push rdi
    
    mov rdi, rsi
    xor rcx, rcx
    not rcx        ; rcx = -1
    xor al, al     ; recherche du caractère nul
    cld            ; direction vers l'avant
    repne scasb    ; rechercher al dans la chaîne
    not rcx        ; inversion des bits
    dec rcx        ; soustraire 1 (le caractère nul)
    mov rax, rcx   ; retourner la longueur
    
    pop rdi
    pop rcx
    ret

; Fonction pour convertir un entier en chaîne ASCII
; rax = entier à convertir, rdi = tampon destination
; Retourne: rdi = fin de la chaîne
itoa:
    push rbx
    push rcx
    push rdx
    push rsi
    
    mov rbx, 10        ; Base 10
    mov rcx, rdi       ; Sauvegarder le début du tampon
    
    ; Cas spécial pour 0
    test rax, rax
    jnz itoa_convert
    mov byte [rdi], '0'
    inc rdi
    jmp itoa_end
    
itoa_convert:
    ; Initialiser la pile pour stocker les chiffres
    xor rsi, rsi       ; Compteur de chiffres
    
itoa_loop:
    xor rdx, rdx
    div rbx            ; rdx = reste, rax = quotient
    add dl, '0'        ; Convertir en ASCII
    push rdx           ; Empiler le chiffre
    inc rsi            ; Incrémenter le compteur
    test rax, rax      ; Vérifier si on a terminé
    jnz itoa_loop
    
    ; Dépiler les chiffres en ordre inverse
itoa_reverse:
    pop rdx
    mov [rdi], dl      ; Stocker le chiffre
    inc rdi
    dec rsi
    jnz itoa_reverse
    
itoa_end:
    mov byte [rdi], 0  ; Terminer la chaîne
    
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret

; Fonction pour exécuter une commande système
; rdi = chaîne de commande
system:
    push rdi
    
    ; Appel à system() via execve("/bin/sh", ["/bin/sh", "-c", commande, NULL], NULL)
    ; Préparer les arguments
    sub rsp, 32        ; Espace pour les arguments (3 pointeurs + NULL)
    
    ; Mettre /bin/sh comme premier argument
    mov qword [rsp], shell_path
    
    ; Mettre -c comme deuxième argument
    mov qword [rsp+8], shell_c_arg
    
    ; Mettre la commande comme troisième argument
    mov qword [rsp+16], rdi