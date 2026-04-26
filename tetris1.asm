.model small
.stack 200h

.data

; =========================
; CONFIGURACION
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
piece_type db 0
rotation db 0

; =========================
; PIEZAS TETRIS (7 tipos)
; cada pieza tiene 4 bloques (x,y)
; =========================

pieces:

; I
db 0,1, 1,1, 2,1, 3,1
; O
db 0,0, 1,0, 0,1, 1,1
; T
db 1,0, 0,1, 1,1, 2,1
; L
db 0,0, 0,1, 0,2, 1,2
; J
db 1,0, 1,1, 1,2, 0,2
; S
db 1,0, 2,0, 0,1, 1,1
; Z
db 0,0, 1,0, 1,1, 2,1

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

; =========================
start:
    mov ax,@data
    mov ds,ax

    mov ax,0003h
    int 10h

    call init
    call draw_ui

main_loop:

    cmp game_over,1
    je end_game

    call input
    call update
    call render
    call delay

    jmp main_loop

; =========================
end_game:
    mov ah,02h
    mov dh,12
    mov dl,30
    int 10h

    mov dx,offset msg_over
    mov ah,09h
    int 21h

    mov ah,00h
    int 16h

    mov ax,4C00h
    int 21h

; =========================
; INICIALIZAR
; =========================
init proc
    push cx
    push di

    mov cx,200
    mov di,0

init_loop:
    mov board[di],0
    inc di
    loop init_loop

    call new_piece

    pop di
    pop cx
    ret
init endp
; =========================
; INPUT
; =========================
input proc
    mov ah,01h
    int 16h
    jz input_end

    mov ah,00h
    int 16h

    cmp al,'a'
    je move_left

    cmp al,'d'
    je move_right

    cmp al,'s'
    je move_down

    cmp al,'w'
    je rotate_piece

input_end:
    ret

move_left:
    dec piece_x
    call collision
    jc undo_left
    ret
undo_left:
    inc piece_x
    ret

move_right:
    inc piece_x
    call collision
    jc undo_right
    ret
undo_right:
    dec piece_x
    ret

move_down:
    inc piece_y
    call collision
    jc lock_piece
    ret

rotate_piece:
    inc rotation
    and rotation,3
    call collision
    jnc ok_rot
    dec rotation
ok_rot:
    ret

input endp

; =========================
; UPDATE AUTOMATICO (CAIDA)
; =========================
update proc
    inc tick
    mov ax,tick
    cmp ax,speed
    jb upd_end

    mov tick,0

    inc piece_y
    call collision
    jc lock_piece

upd_end:
    ret
update endp

; =========================
; COLISION
; =========================
collision proc
    push ax
    push bx
    push cx
    push si

    mov cx,4
    mov si,0

col_loop:

    ; obtener bloque de pieza
    mov al,piece_type
    mov bl,8
    mul bl          ; tipo * 8
    mov si,ax

    mov bl,0
    add si,bx

    ; X
    mov al,piece_x
    add al,pieces[si]
    mov bl,al

    ; Y
    mov al,piece_y
    add al,pieces[si+1]
    mov bh,al

    ; limites
    cmp bl,0
    jl col_fail

    cmp bl,WIDTH
    jge col_fail

    cmp bh,HEIGHT
    jge col_fail

    ; index = y*10 + x
    mov al,bh
    mov ah,0
    mov cl,10
    mul cl

    mov dl,bl
    xor dh,dh
    add ax,dx

    mov bx,ax
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
    pop cx
    pop bx
    pop ax
    ret
collision endp

; =========================
; FIJAR PIEZA
; =========================
lock_piece proc
    push ax
    push bx
    push cx
    push si

    mov cx,4
    mov si,0

lock_loop:

    mov al,piece_type
    mov bl,8
    mul bl
    mov si,ax

    ; X
    mov al,piece_x
    add al,pieces[si]
    mov bl,al

    ; Y
    mov al,piece_y
    add al,pieces[si+1]
    mov bh,al

    ; index
    mov al,bh
    mov ah,0
    mov cl,10
    mul cl

    mov dl,bl
    xor dh,dh
    add ax,dx

    mov bx,ax
    mov board[bx],1

    add si,2
    loop lock_loop

    call clear_lines
    call new_piece

    pop si
    pop cx
    pop bx
    pop ax
    ret
lock_piece endp

; =========================
; NUEVA PIEZA
; =========================
new_piece proc
    mov piece_x,4
    mov piece_y,0

    inc piece_type
    cmp piece_type,7
    jl ok_type
    mov piece_type,0
ok_type:

    call collision
    jc game_over_set
    ret

game_over_set:
    mov game_over,1
    ret
new_piece endp
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

    mov cx,HEIGHT
    mov bx,0
    mov dh,3

row_loop:
    push cx
    mov cx,WIDTH
    mov dl,2

col_loop:
    mov ah,02h
    int 10h

    cmp board[bx],1
    jne empty_cell

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
; DIBUJAR PIEZA ACTUAL
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

    mov al,piece_type
    mov bl,8
    mul bl
    mov si,ax

    ; Y
    mov al,piece_y
    add al,pieces[si+1]
    add al,3
    mov dh,al

    ; X
    mov al,piece_x
    add al,pieces[si]
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
    loop dp_loop

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
draw_piece endp

; =========================
; LIMPIAR LINEAS COMPLETAS
; =========================
clear_lines proc
    push ax
    push bx
    push cx
    push dx

    mov cx,HEIGHT
    mov bx,0

row_check:
    push cx
    mov cx,WIDTH
    mov dx,0

check_cells:
    cmp board[bx],1
    jne not_full
    inc dx
    inc bx
    loop check_cells

    cmp dx,WIDTH
    jne not_full

    ; FILA COMPLETA -> BORRAR Y BAJAR
    call remove_line

    inc lines
    add score,100

not_full:
    add bx,WIDTH
    pop cx
    loop row_check

    pop dx
    pop cx
    pop bx
    pop ax
    ret
clear_lines endp

; =========================
; ELIMINAR UNA FILA Y BAJAR TODO
; =========================
remove_line proc
    push ax
    push bx
    push cx

    ; bx apunta al final de la fila actual
    ; mover todo hacia abajo

    mov cx,bx

shift_loop:
    cmp cx,0
    jl shift_done

    mov al,board[cx-WIDTH]
    mov board[cx],al

    dec cx
    jmp shift_loop

shift_done:

    ; limpiar fila superior
    mov cx,WIDTH
    mov bx,0

clear_top:
    mov board[bx],0
    inc bx
    loop clear_top

    pop cx
    pop bx
    pop ax
    ret
remove_line endp

; =========================
; UI
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
; MOSTRAR INFO
; =========================
draw_info proc
    push ax
    push dx

    mov ah,02h
    mov dh,0
    mov dl,8
    int 10h
    mov ax,score
    call print_num

    mov ah,02h
    mov dh,1
    mov dl,8
    int 10h
    mov ax,lines
    call print_num

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
; IMPRIMIR NUMEROS
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
; DELAY FINAL
; =========================
delay proc
    push cx
    mov cx,5000
dloop:
    loop dloop
    pop cx
    ret
delay endp