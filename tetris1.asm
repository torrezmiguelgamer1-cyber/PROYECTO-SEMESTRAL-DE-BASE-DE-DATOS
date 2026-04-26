.model small
.stack 200h

.data

WIDTH  equ 10
HEIGHT equ 20

; =========================
; TABLERO
; =========================
board db 200 dup(0)

; =========================
; PIEZA ACTUAL
; =========================
piece_x db 4
piece_y db 0

piece_type db 0

; =========================
; PIEZAS (COORDENADAS)
; =========================

; O
piece_O db 0,0, 1,0, 0,1, 1,1

; I
piece_I db 0,0, 1,0, 2,0, 3,0

; T
piece_T db 1,0, 0,1, 1,1, 2,1

; L
piece_L db 0,0, 0,1, 1,1, 2,1

; J
piece_J db 2,0, 0,1, 1,1, 2,1

; S
piece_S db 1,0, 2,0, 0,1, 1,1

; Z
piece_Z db 0,0, 1,0, 1,1, 2,1

; buffer actual
current_piece db 8 dup(0)

; =========================
; VARIABLES
; =========================
score dw 0
lines dw 0
level db 1
game_over db 0

tick dw 0
speed dw 8

; =========================
; TEXTOS
; =========================
msg_score db 'SCORE:$'
msg_lines db 'LINES:$'
msg_level db 'LEVEL:$'
msg_over  db 'GAME OVER$'

.code

start:
    mov ax,@data
    mov ds,ax

    mov ax,0003h
    int 10h

    call init_game
    call draw_ui

main_loop:

    cmp game_over,1
    je end_game

    call read_input
    call update_game
    call render_all
    call delay_big

    jmp main_loop

end_game:
    call show_game_over

    mov ah,00h
    int 16h

    mov ax,4C00h
    int 21h
; =========================
init_game proc

    push cx
    push bx

    mov cx,200
    mov bx,0

init_loop:
    mov board[bx],0
    inc bx
    loop init_loop

    mov piece_x,4
    mov piece_y,0
    mov piece_type,0

    mov score,0
    mov lines,0
    mov level,1
    mov game_over,0

    call spawn_piece

    pop bx
    pop cx
    ret
init_game endp
; =========================
spawn_piece proc

    push ax
    push si
    push di
    push cx

    ; cambiar tipo
    mov al,piece_type
    inc al
    cmp al,7
    jb ok_type
    mov al,0
ok_type:
    mov piece_type,al

    mov piece_x,4
    mov piece_y,0

    ; seleccionar pieza
    cmp piece_type,0
    je pO
    cmp piece_type,1
    je pI
    cmp piece_type,2
    je pT
    cmp piece_type,3
    je pL
    cmp piece_type,4
    je pJ
    cmp piece_type,5
    je pS
    jmp pZ

pO: mov si,offset piece_O
    jmp copy
pI: mov si,offset piece_I
    jmp copy
pT: mov si,offset piece_T
    jmp copy
pL: mov si,offset piece_L
    jmp copy
pJ: mov si,offset piece_J
    jmp copy
pS: mov si,offset piece_S
    jmp copy
pZ: mov si,offset piece_Z

copy:
    mov cx,8
    mov di,0

copy_loop:
    mov al,[si]
    mov current_piece[di],al
    inc si
    inc di
    loop copy_loop

    pop cx
    pop di
    pop si
    pop ax
    ret
spawn_piece endp
; =========================
read_input proc

    mov ah,01h
    int 16h
    jz no_key

    mov ah,00h
    int 16h

    ; IZQUIERDA
    cmp al,'a'
    je move_left

    ; DERECHA
    cmp al,'d'
    je move_right

    ; ABAJO (caída rápida)
    cmp al,'s'
    je move_down

    ; ROTAR (lo dejamos preparado)
    cmp al,'w'
    je rotate_piece

no_key:
    ret

; -------------------------
move_left:
    dec piece_x
    call check_collision
    jc undo_left
    ret
undo_left:
    inc piece_x
    ret

; -------------------------
move_right:
    inc piece_x
    call check_collision
    jc undo_right
    ret
undo_right:
    dec piece_x
    ret

; -------------------------
move_down:
    inc piece_y
    call check_collision
    jc lock_piece_input
    ret

lock_piece_input:
    dec piece_y
    call fix_piece
    call clear_lines_full
    call spawn_piece
    ret

; -------------------------
rotate_piece:
    ; lo implementamos en parte 4
    ret

read_input endp
; =========================
update_game proc

    push ax

    inc tick
    mov ax,tick
    cmp ax,speed
    jb update_end

    mov tick,0

    ; bajar pieza automáticamente
    inc piece_y
    call check_collision
    jc auto_lock

    jmp update_end

auto_lock:
    dec piece_y
    call fix_piece
    call clear_lines_full
    call spawn_piece

update_end:
    pop ax
    ret

update_game endp
; =========================
delay_big proc

    push cx

    mov cx,40000   ; ajusta velocidad aquí

delay_loop:
    nop
    loop delay_loop

    pop cx
    ret

delay_big endp
; =========================
check_collision proc

    push ax
    push bx
    push cx
    push dx
    push si

    mov cx,4
    mov si,0

collision_loop:

    ; X = piece_x + offset
    xor ax,ax
    mov al,piece_x
    add al,current_piece[si]
    mov bl,al

    ; Y = piece_y + offset
    xor ax,ax
    mov al,piece_y
    add al,current_piece[si+1]
    mov bh,al

    ; limites X
    cmp bl,0
    jl collision_fail
    cmp bl,WIDTH
    jge collision_fail

    ; limites Y
    cmp bh,HEIGHT
    jge collision_fail

    ; índice = y*10 + x
    xor ax,ax
    mov al,bh
    mov dl,10
    mul dl        ; AX = y*10

    xor dx,dx
    mov dl,bl
    add ax,dx     ; AX = index

    mov bx,ax

    cmp board[bx],1
    je collision_fail

    add si,2
    loop collision_loop

    clc
    jmp collision_exit

collision_fail:
    stc

collision_exit:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

check_collision endp
; =========================
fix_piece proc

    push ax
    push bx
    push cx
    push dx
    push si

    mov cx,4
    mov si,0

fix_loop:

    ; X
    xor ax,ax
    mov al,piece_x
    add al,current_piece[si]
    mov bl,al

    ; Y
    xor ax,ax
    mov al,piece_y
    add al,current_piece[si+1]
    mov bh,al

    ; index = y*10 + x
    xor ax,ax
    mov al,bh
    mov dl,10
    mul dl

    xor dx,dx
    mov dl,bl
    add ax,dx

    mov bx,ax
    mov board[bx],1

    add si,2
    loop fix_loop

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

fix_piece endp
; =========================
clear_lines_full proc

    push ax
    push bx
    push cx
    push dx

    mov cx,HEIGHT
    mov bx,0

row_loop:

    push cx

    mov cx,WIDTH
    mov dx,0

cell_loop:
    cmp board[bx],1
    jne not_full_row
    inc dx
    inc bx
    loop cell_loop

    cmp dx,WIDTH
    jne not_full_row

    ; eliminar fila
    sub bx,WIDTH
    call remove_row

    inc lines
    add score,100

not_full_row:
    add bx,WIDTH
    pop cx
    loop row_loop

    pop dx
    pop cx
    pop bx
    pop ax
    ret

clear_lines_full endp
; =========================
render_all proc
    call draw_board
    call draw_piece
    call draw_info
    ret
render_all endp
; =========================
draw_board proc

    push ax
    push bx
    push cx
    push dx

    mov bx,0          ; índice tablero
    mov dh,3          ; fila pantalla
    mov cx,HEIGHT

row_loop_db:
    push cx

    mov dl,2
    mov cx,WIDTH

col_loop_db:

    ; posicion cursor
    mov ah,02h
    int 10h

    mov al,board[bx]

    cmp al,1
    jne empty_cell

    ; bloque
    mov ah,09h
    mov al,219
    mov bl,0Ah
    mov cx,1
    int 10h
    jmp next_cell

empty_cell:
    mov ah,09h
    mov al,'.'
    mov bl,07h
    mov cx,1
    int 10h

next_cell:
    inc dl
    inc bx
    loop col_loop_db

    inc dh
    pop cx
    loop row_loop_db

    pop dx
    pop cx
    pop bx
    pop ax
    ret

draw_board endp
; =========================
draw_piece proc

    push ax
    push bx
    push cx
    push dx
    push si

    mov cx,4
    mov si,0

dp_loop:

    ; Y
    xor ax,ax
    mov al,piece_y
    add al,current_piece[si+1]
    add al,3
    mov dh,al

    ; X
    xor ax,ax
    mov al,piece_x
    add al,current_piece[si]
    add al,2
    mov dl,al

    mov ah,02h
    int 10h

    mov ah,09h
    mov al,219
    mov bl,0Ch
    mov cx,1
    int 10h

    add si,2
    loop dp_loop

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

draw_piece endp
; =========================
draw_ui proc

    mov ah,02h
    mov dh,0
    mov dl,0
    int 10h
    mov dx,offset msg_score
    mov ah,09h
    int 21h

    mov ah,02h
    mov dh,1
    mov dl,0
    int 10h
    mov dx,offset msg_lines
    mov ah,09h
    int 21h

    mov ah,02h
    mov dh,2
    mov dl,0
    int 10h
    mov dx,offset msg_level
    mov ah,09h
    int 21h

    ret
draw_ui endp
; =========================
draw_info proc

    push ax
    push dx

    ; SCORE
    mov ah,02h
    mov dh,0
    mov dl,8
    int 10h
    mov ax,score
    call print_num

    ; LINES
    mov ah,02h
    mov dh,1
    mov dl,8
    int 10h
    mov ax,lines
    call print_num

    ; LEVEL
    mov ah,02h
    mov dh,2
    mov dl,8
    int 10h
    xor ax,ax
    mov al,level
    call print_num

    pop dx
    pop ax
    ret

draw_info endp
; =========================
print_num proc

    push ax
    push bx
    push cx
    push dx

    mov bx,10
    xor cx,cx

pn1:
    xor dx,dx
    div bx
    push dx
    inc cx
    cmp ax,0
    jne pn1

pn2:
    pop dx
    add dl,'0'
    mov ah,02h
    int 21h
    loop pn2

    pop dx
    pop cx
    pop bx
    pop ax
    ret

print_num endp
; =========================
remove_row proc

    push ax
    push bx
    push cx
    push dx
    push si
    push di

    ; BX = inicio de la fila a eliminar

shift_rows:

    cmp bx,0
    je clear_top

    mov cx,WIDTH

copy_loop:

    ; destino
    mov di,bx

    ; fuente = fila superior
    mov ax,bx
    sub ax,WIDTH
    mov si,ax

    mov al,board[si]
    mov board[di],al

    inc bx
    loop copy_loop

    sub bx,WIDTH
    jmp shift_rows

clear_top:

    mov cx,WIDTH
    mov bx,0

clear_loop:
    mov board[bx],0
    inc bx
    loop clear_loop

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

remove_row endp
; =========================
show_game_over proc

    mov ah,02h
    mov dh,12
    mov dl,30
    int 10h

    mov dx,offset msg_over
    mov ah,09h
    int 21h

    ret

show_game_over endp
end start
