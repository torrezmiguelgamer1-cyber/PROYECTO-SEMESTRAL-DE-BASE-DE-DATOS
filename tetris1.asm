; ============================================================
; TETRIS PRO REAL - PARTE 1
; Motor principal + estructura base sólida
; ============================================================

.model small
.stack 200h

; =========================
; CONSTANTES
; =========================
WIDTH  equ 10
HEIGHT equ 20

; =========================
; DATA
; =========================
.data

; TABLERO (10x20)
board db 200 dup(0)

; PIEZA ACTUAL
piece_x db 4
piece_y db 0
piece_type db 0
piece_rot db 0

; SIGUIENTE PIEZA
next_type db 1

; SCORE
score dw 0
lines dw 0
level db 1

game_over db 0

; TIMING
tick dw 0
speed dw 15

; =========================
; TEXTOS
; =========================
msg_score db 'SCORE:$'
msg_lines db 'LINES:$'
msg_level db 'LEVEL:$'
msg_next  db 'NEXT:$'
msg_over  db 'GAME OVER$'

; =========================
; PIEZAS (SIN MATRICES RARAS)
; Formato: dx,dy x4 bloques x4 rotaciones
; =========================

pieces:

; I
db 0,0,1,0,2,0,3,0
db 1,0,1,1,1,2,1,3
db 0,1,1,1,2,1,3,1
db 2,0,2,1,2,2,2,3

; O
db 0,0,1,0,0,1,1,1
db 0,0,1,0,0,1,1,1
db 0,0,1,0,0,1,1,1
db 0,0,1,0,0,1,1,1

; T
db 1,0,0,1,1,1,2,1
db 1,0,1,1,2,1,1,2
db 0,1,1,1,2,1,1,2
db 1,0,0,1,1,1,1,2

; L
db 0,0,0,1,1,1,2,1
db 1,0,2,0,1,1,1,2
db 0,1,1,1,2,1,2,2
db 1,0,1,1,0,2,1,2

; J
db 2,0,0,1,1,1,2,1
db 1,0,1,1,1,2,2,2
db 0,1,1,1,2,1,0,2
db 0,0,1,0,1,1,1,2

; S
db 1,0,2,0,0,1,1,1
db 1,0,1,1,2,1,2,2
db 1,1,2,1,0,2,1,2
db 0,0,0,1,1,1,1,2

; Z
db 0,0,1,0,1,1,2,1
db 2,0,1,1,2,1,1,2
db 0,1,1,1,1,2,2,2
db 1,0,0,1,1,1,0,2

; =========================
.code

start:

    mov ax,@data
    mov ds,ax

    mov ax,0003h
    int 10h

    call init_game

main_loop:

    cmp game_over,1
    je end_game

    call input
    call update
    call render
    call delay

    jmp main_loop

; =========================
init_game proc

    push cx
    push di

    mov cx,200
    mov di,0

init_loop:
    mov board[di],0
    inc di
    loop init_loop

    mov score,0
    mov lines,0
    mov level,1

    call new_piece

    pop di
    pop cx
    ret

init_game endp

; =========================
input proc

    mov ah,01h
    int 16h
    jz input_end

    mov ah,00h
    int 16h

    cmp al,'a'
    je in_left
    cmp al,'d'
    je in_right
    cmp al,'s'
    je in_down
    cmp al,'w'
    je in_rotate

input_end:
    ret

in_left:
    dec piece_x
    call collision
    jc undo_l
    ret
undo_l:
    inc piece_x
    ret

in_right:
    inc piece_x
    call collision
    jc undo_r
    ret
undo_r:
    dec piece_x
    ret

in_down:
    inc piece_y
    call collision
    jc lock_piece
    ret

in_rotate:
    inc piece_rot
    cmp piece_rot,4
    jb rot_ok
    mov piece_rot,0
rot_ok:
    call collision
    jc undo_rot
    ret
undo_rot:
    dec piece_rot
    ret

input endp
; ============================================================
get_piece_offset proc
; OUT: SI apunta a la rotación actual

    push ax
    push bx

    mov al,piece_type
    xor ah,ah
    mov bl,32
    mul bl        ; AX = tipo * 32

    mov si,ax

    mov al,piece_rot
    xor ah,ah
    mov bl,8
    mul bl        ; AX = rot * 8

    add si,ax

    add si,offset pieces

    pop bx
    pop ax
    ret

get_piece_offset endp
; ============================================================
collision proc

    push ax
    push bx
    push cx
    push dx
    push si

    call get_piece_offset

    mov cx,4
    mov di,0

col_check_loop:

    ; X = piece_x + dx
    mov al,piece_x
    add al,[si+di]
    mov bl,al

    ; Y = piece_y + dy
    mov al,piece_y
    add al,[si+di+1]
    mov bh,al

    ; LIMITE X
    cmp bl,0
    jl col_fail
    cmp bl,WIDTH
    jge col_fail

    ; LIMITE Y
    cmp bh,HEIGHT
    jge col_fail

    ; INDEX = y*10 + x
    xor ax,ax
    mov al,bh
    mov dl,10
    mul dl

    add al,bl
    mov bx,ax

    cmp board[bx],1
    je col_fail

    add di,2
    loop col_check_loop

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
; ============================================================
fix_piece proc

    push ax
    push bx
    push cx
    push dx
    push si

    call get_piece_offset

    mov cx,4
    mov di,0

fix_loop_main:

    mov al,piece_x
    add al,[si+di]
    mov bl,al

    mov al,piece_y
    add al,[si+di+1]
    mov bh,al

    ; index
    xor ax,ax
    mov al,bh
    mov dl,10
    mul dl

    add al,bl
    mov bx,ax

    mov board[bx],1

    add di,2
    loop fix_loop_main

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

fix_piece endp
; ============================================================
new_piece proc

    mov piece_x,4
    mov piece_y,0
    mov piece_rot,0

    ; pseudo random (simple pero estable)
    mov ah,00h
    int 1Ah
    mov al,dl
    and al,07
    cmp al,6
    jbe ok_rand
    mov al,0
ok_rand:
    mov piece_type,al

    call collision
    jc np_gameover

    ret

np_gameover:
    mov game_over,1
    ret

new_piece endp
; ============================================================
update proc

    inc tick
    mov ax,tick
    cmp ax,speed
    jb upd_exit

    mov tick,0

    inc piece_y
    call collision
    jc upd_lock

upd_exit:
    ret

upd_lock:
    dec piece_y
    call fix_piece
    call clear_lines
    call new_piece
    ret

update endp
; ============================================================
render proc

    call draw_board
    call draw_piece
    call draw_ui_data

    ret

render endp
; ============================================================
draw_board proc

    push ax
    push bx
    push cx
    push dx

    mov bx,0
    mov dh,3
    mov cx,20

db_row_loop:

    push cx
    mov cx,10
    mov dl,2

db_col_loop:

    mov ah,02h
    int 10h

    cmp board[bx],1
    jne db_empty

    ; BLOQUE LLENO
    mov ah,09h
    mov al,219
    mov bl,0Ch
    mov cx,1
    int 10h
    jmp db_next

db_empty:
    mov ah,09h
    mov al,'.'
    mov bl,07h
    mov cx,1
    int 10h

db_next:
    inc dl
    inc bx
    loop db_col_loop

    inc dh
    pop cx
    loop db_row_loop

    pop dx
    pop cx
    pop bx
    pop ax
    ret

draw_board endp
; ============================================================
draw_piece proc

    push ax
    push bx
    push cx
    push dx
    push si

    call get_piece_offset

    mov cx,4
    mov di,0

dp_loop_main:

    mov al,piece_y
    add al,[si+di+1]
    add al,3
    mov dh,al

    mov al,piece_x
    add al,[si+di]
    add al,2
    mov dl,al

    mov ah,02h
    int 10h

    mov ah,09h
    mov al,219
    mov bl,0Ah
    mov cx,1
    int 10h

    add di,2
    loop dp_loop_main

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

draw_piece endp
; ============================================================
clear_lines proc

    push ax
    push bx
    push cx
    push dx

    mov dh,0          ; fila

cl_row_loop:

    cmp dh,20
    jge cl_done

    ; calcular inicio fila
    xor ax,ax
    mov al,dh
    mov bl,10
    mul bl
    mov bx,ax

    mov cx,10
    mov dl,0          ; contador

cl_check_cells:

    cmp board[bx],1
    jne cl_not_full

    inc dl
    inc bx
    loop cl_check_cells

    cmp dl,10
    jne cl_not_full

    ; ==== FILA COMPLETA ====
    call remove_line

    inc lines
    add score,100

    jmp cl_row_loop

cl_not_full:
    inc dh
    jmp cl_row_loop

cl_done:
    pop dx
    pop cx
    pop bx
    pop ax
    ret

clear_lines endp
; ============================================================
remove_line proc

    push ax
    push bx
    push cx
    push dx
    push si
    push di

    ; dh = fila a eliminar

rl_shift_rows:

    cmp dh,0
    je rl_clear_top

    ; destino = fila actual
    xor ax,ax
    mov al,dh
    mov bl,10
    mul bl
    mov si,ax

    ; fuente = fila-1
    mov al,dh
    dec al
    mov bl,10
    mul bl
    mov di,ax

    mov cx,10

rl_copy_loop:

    mov al,board[di]
    mov board[si],al

    inc si
    inc di
    loop rl_copy_loop

    dec dh
    jmp rl_shift_rows

rl_clear_top:

    mov cx,10
    mov bx,0

rl_clear_loop:

    mov board[bx],0
    inc bx
    loop rl_clear_loop

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

remove_line endp
; ============================================================
draw_ui_data proc

    push ax
    push dx

    ; SCORE
    mov ah,02h
    mov dh,0
    mov dl,0
    int 10h
    mov dx,offset msg_score
    mov ah,09h
    int 21h

    mov ah,02h
    mov dh,0
    mov dl,8
    int 10h
    mov ax,score
    call print_num

    ; LINES
    mov ah,02h
    mov dh,1
    mov dl,0
    int 10h
    mov dx,offset msg_lines
    mov ah,09h
    int 21h

    mov ah,02h
    mov dh,1
    mov dl,8
    int 10h
    mov ax,lines
    call print_num

    pop dx
    pop ax
    ret

draw_ui_data endp
; ============================================================
print_num proc

    push ax
    push bx
    push cx
    push dx

    mov bx,10
    xor cx,cx

pn_loop1:
    xor dx,dx
    div bx
    push dx
    inc cx
    cmp ax,0
    jne pn_loop1

pn_loop2:
    pop dx
    add dl,'0'
    mov ah,02h
    int 21h
    loop pn_loop2

    pop dx
    pop cx
    pop bx
    pop ax
    ret

print_num endp
; ============================================================
delay proc

    push ax
    push dx

    mov ah,00h
    int 1Ah
    mov bx,dx

delay_wait:

    mov ah,00h
    int 1Ah
    cmp dx,bx
    je delay_wait

    pop dx
    pop ax
    ret

delay endp
