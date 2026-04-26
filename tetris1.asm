.model small
.stack 200h

.data

; =========================
; CONSTANTES
; =========================
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

; pieza cuadrado (base estable)
piece_shape db 0,0, 1,0, 0,1, 1,1

; =========================
; VARIABLES DE JUEGO
; =========================
score dw 0
lines dw 0
level db 1

game_over db 0

tick dw 0
speed dw 8

last_time dw 0

; =========================
; TEXTOS
; =========================
msg_score db 'SCORE:$'
msg_lines db 'LINES:$'
msg_level db 'LEVEL:$'
msg_over  db 'GAME OVER$'

.code

; =========================
start:
    mov ax,@data
    mov ds,ax

    ; MODO TEXTO (DOSBOX)
    mov ax,0003h
    int 10h

    call init
    call draw_ui

main_loop:

    call wait_tick      ; reloj estable
    call input
    call update
    call render

    cmp game_over,1
    jne main_loop

    call show_game_over

    mov ah,00h
    int 16h

    mov ax,4C00h
    int 21h

; =========================
; TIMER REAL (NO BUG)
; =========================
wait_tick proc
    push ax
    push dx

wt_loop:
    mov ah,00h
    int 1Ah

    cmp dx,last_time
    je wt_loop

    mov last_time,dx

    pop dx
    pop ax
    ret
wait_tick endp

; =========================
; INICIALIZAR JUEGO
; =========================
init proc
    push cx
    push di

    mov cx,200
    mov di,0

clear_board:
    mov board[di],0
    inc di
    loop clear_board

    mov piece_x,4
    mov piece_y,0

    pop di
    pop cx
    ret
init endp
; =========================
; INPUT (NO BLOQUEANTE)
; =========================
input proc
    push ax

    mov ah,01h
    int 16h
    jz input_end   ; no hay tecla

    mov ah,00h
    int 16h

    cmp al,'a'
    je move_left

    cmp al,'d'
    je move_right

    cmp al,'s'
    je move_down

input_end:
    pop ax
    ret

; -------------------------
move_left:
    dec piece_x
    call collision
    jc undo_left
    jmp input_exit

undo_left:
    inc piece_x
    jmp input_exit

; -------------------------
move_right:
    inc piece_x
    call collision
    jc undo_right
    jmp input_exit

undo_right:
    dec piece_x
    jmp input_exit

; -------------------------
move_down:
    inc piece_y
    call collision
    jc fix_current_piece
    jmp input_exit

; -------------------------
fix_current_piece:
    dec piece_y
    call fix_piece
    call clear_lines
    call spawn_new_piece

input_exit:
    pop ax
    ret
input endp
; =========================
; UPDATE (CAÍDA AUTOMÁTICA)
; =========================
update proc
    push ax

    inc tick
    mov ax,tick
    cmp ax,speed
    jb update_end

    mov tick,0

    inc piece_y
    call collision
    jc lock_piece

    jmp update_end

lock_piece:
    dec piece_y
    call fix_piece
    call clear_lines
    call spawn_new_piece

update_end:
    pop ax
    ret
update endp
; =========================
; COLISIÓN (VERSIÓN SEGURA)
; =========================
collision proc
    push ax
    push bx
    push cx
    push dx
    push si

    mov cx,4
    mov si,0

col_loop:

    ; ===== X =====
    xor ax,ax
    mov al,piece_x
    add al,piece_shape[si]
    mov bl,al

    ; ===== Y =====
    xor ax,ax
    mov al,piece_y
    add al,piece_shape[si+1]
    mov bh,al

    ; ===== límites =====
    cmp bl,0
    jl col_fail

    cmp bl,WIDTH
    jge col_fail

    cmp bh,HEIGHT
    jge col_fail

    ; ===== index = y*WIDTH + x =====
    xor ax,ax
    mov al,bh
    mov cl,WIDTH
    mul cl          ; AX = y*WIDTH

    xor dx,dx
    mov dl,bl
    add ax,dx       ; AX = índice final

    mov bx,ax       ; ✔ usar BX SIEMPRE

    cmp board[bx],1
    je col_fail

    add si,2
    loop col_loop

    clc
    jmp col_exit

col_fail:
    stc

col_exit:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
collision endp
; =========================
; FIJAR PIEZA
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
    add al,piece_shape[si]
    mov bl,al

    ; Y
    xor ax,ax
    mov al,piece_y
    add al,piece_shape[si+1]
    mov bh,al

    ; index
    xor ax,ax
    mov al,bh
    mov cl,WIDTH
    mul cl

    xor dx,dx
    mov dl,bl
    add ax,dx

    mov bx,ax
    mov board[bx],1   ; ✔ correcto

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
; NUEVA PIEZA
; =========================
spawn_new_piece proc
    mov piece_x,4
    mov piece_y,0

    call collision
    jc game_over_set

    ret

game_over_set:
    mov game_over,1
    ret
spawn_new_piece endp
; =========================
; RENDER GENERAL
; =========================
render proc
    call draw_board
    call draw_piece
    call draw_info
    ret
render endp
; =========================
; DIBUJAR TABLERO
; =========================
draw_board proc
    push ax
    push bx
    push cx
    push dx

    mov bx,0          ; índice tablero
    mov dh,3          ; fila pantalla
    mov cx,HEIGHT

row_loop:
    push cx

    mov dl,2
    mov cx,WIDTH

col_loop:
    ; posicion cursor
    mov ah,02h
    int 10h

    cmp board[bx],1
    jne empty_cell

    ; bloque lleno
    mov ah,09h
    mov al,219
    mov bl,0Ch
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
    loop col_loop

    inc dh
    pop cx
    loop row_loop

    pop dx
    pop cx
    pop bx
    pop ax
    ret
draw_board endp
; =========================
; DIBUJAR PIEZA
; =========================
draw_piece proc
    push ax
    push bx
    push cx
    push dx
    push si

    mov cx,4
    mov si,0

piece_loop:

    ; Y pantalla
    xor ax,ax
    mov al,piece_y
    add al,piece_shape[si+1]
    add al,3
    mov dh,al

    ; X pantalla
    xor ax,ax
    mov al,piece_x
    add al,piece_shape[si]
    add al,2
    mov dl,al

    mov ah,02h
    int 10h

    mov ah,09h
    mov al,219
    mov bl,0Ah
    mov cx,1
    int 10h

    add si,2
    loop piece_loop

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
draw_piece endp
; =========================
; UI FIJA
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
; DIBUJAR INFO
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
; PRINT NUM
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
; CLEAR LINES REAL
; =========================
clear_lines proc
    push ax
    push bx
    push cx
    push dx
    push si

    mov bx,0          ; índice fila

row_check:
    mov cx,WIDTH
    mov si,bx
    xor dx,dx         ; contador

check_loop:
    cmp board[si],1
    jne not_full
    inc dx
    inc si
    loop check_loop

    cmp dx,WIDTH
    jne next_row

    ; ===== fila llena =====
    call remove_row

    inc lines
    add score,100

next_row:
    add bx,WIDTH
    cmp bx,200
    jl row_check

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
clear_lines endp
; =========================
; ELIMINAR FILA Y BAJAR
; =========================
remove_row proc
    push ax
    push bx
    push cx
    push dx
    push si

    mov dx,bx    ; fila actual

shift_loop:
    cmp dx,0
    jle clear_top

    mov cx,WIDTH

copy_loop:
    mov ax,dx
    sub ax,WIDTH
    mov si,ax
    mov al,board[si]

    mov si,dx
    mov board[si],al

    inc dx
    loop copy_loop

    sub dx,WIDTH
    jmp shift_loop

clear_top:
    mov cx,WIDTH
    mov bx,0

top_clear:
    mov board[bx],0
    inc bx
    loop top_clear

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
remove_row endp
; =========================
; GAME OVER
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
