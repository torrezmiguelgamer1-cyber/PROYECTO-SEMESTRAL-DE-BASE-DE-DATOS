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
; PIEZA ACTUAL (CUADRADO 2x2)
; =========================
piece_x db 4
piece_y db 0

; forma fija (NO tipos raros)
shape db 0,0, 1,0, 0,1, 1,1

; =========================
; VARIABLES
; =========================
score dw 0
lines dw 0
game_over db 0

tick dw 0
speed dw 5

; =========================
; TEXTOS
; =========================
msg_score db 'SCORE:$'
msg_lines db 'LINES:$'
msg_over  db 'GAME OVER$'

.code

; =========================
start:
    mov ax,@data
    mov ds,ax

    mov ax,0003h
    int 10h

    call init

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
init proc
    push cx
    push di

    mov cx,200
    mov di,0

init_loop:
    mov board[di],0
    inc di
    loop init_loop

    mov piece_x,4
    mov piece_y,0

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
    je in_left

    cmp al,'d'
    je in_right

    cmp al,'s'
    je in_down

input_end:
    ret

in_left:
    dec piece_x
    call collision
    jc undo_left
    ret
undo_left:
    inc piece_x
    ret

in_right:
    inc piece_x
    call collision
    jc undo_right
    ret
undo_right:
    dec piece_x
    ret

in_down:
    inc piece_y
    call collision
    jc in_lock
    ret

in_lock:
    dec piece_y
    call fix_piece
    call clear_lines
    call new_piece
    ret

input endp

; =========================
; UPDATE (CAIDA)
; =========================
update proc
    inc tick
    mov ax,tick
    cmp ax,speed
    jb upd_end

    mov tick,0

    inc piece_y
    call collision
    jc upd_lock

upd_end:
    ret

upd_lock:
    dec piece_y
    call fix_piece
    call clear_lines
    call new_piece
    ret

update endp
; =========================
; COLISION CORRECTA
; =========================
collision proc
    push ax
    push bx
    push cx
    push dx
    push si

    mov cx,4
    mov si,0

col_loop_p2:

    ; ---- calcular X ----
    mov al,piece_x
    add al,shape[si]
    mov bl,al          ; BL = X

    ; ---- calcular Y ----
    mov al,piece_y
    add al,shape[si+1]
    mov bh,al          ; BH = Y

    ; ---- limites ----
    cmp bl,0
    jl col_fail_p2

    cmp bl,WIDTH
    jge col_fail_p2

    cmp bh,HEIGHT
    jge col_fail_p2

    ; ---- indice = Y*10 + X ----
    xor ax,ax
    mov al,bh
    mov cl,10
    mul cl             ; AX = Y*10

    xor dx,dx
    mov dl,bl
    add ax,dx          ; AX = index

    mov bx,ax
    cmp board[bx],1
    je col_fail_p2

    add si,2
    loop col_loop_p2

    clc
    jmp col_exit_p2

col_fail_p2:
    stc

col_exit_p2:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
collision endp

; =========================
; FIJAR PIEZA (SIN BUGS)
; =========================
fix_piece proc
    push ax
    push bx
    push cx
    push dx
    push si

    mov cx,4
    mov si,0

fix_loop_p2:

    ; X
    mov al,piece_x
    add al,shape[si]
    mov bl,al

    ; Y
    mov al,piece_y
    add al,shape[si+1]
    mov bh,al

    ; index = Y*10 + X
    xor ax,ax
    mov al,bh
    mov cl,10
    mul cl

    xor dx,dx
    mov dl,bl
    add ax,dx

    mov bx,ax
    mov board[bx],1

    add si,2
    loop fix_loop_p2

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
fix_piece endp

; =========================
; LIMPIAR LINEAS (REAL)
; =========================
clear_lines proc
    push ax
    push bx
    push cx
    push dx

    mov cx,HEIGHT
    mov bx,0

row_loop_p2:

    push cx
    push bx

    mov cx,WIDTH
    mov dx,0           ; contador celdas llenas

check_cells_p2:
    cmp board[bx],1
    jne not_full_p2
    inc dx
    inc bx
    loop check_cells_p2

    cmp dx,WIDTH
    jne not_full_p2

    ; ---- FILA COMPLETA ----
    pop bx
    push bx
    call remove_line

    inc lines
    add score,100

not_full_p2:
    pop bx
    add bx,WIDTH

    pop cx
    loop row_loop_p2

    pop dx
    pop cx
    pop bx
    pop ax
    ret
clear_lines endp

; =========================
; ELIMINAR LINEA Y BAJAR
; =========================
remove_line proc
    push ax
    push bx
    push cx
    push dx

    ; BX = inicio de la fila

    mov dx,bx          ; DX = fila actual

shift_rows_p2:

    cmp dx,0
    jl clear_top_p2

    ; copiar fila superior
    mov cx,WIDTH

copy_cells_p2:

    mov ax,dx
    sub ax,WIDTH
    cmp ax,0
    jl zero_cell_p2

    mov si,ax
    mov al,board[si]
    jmp write_cell_p2

zero_cell_p2:
    mov al,0

write_cell_p2:
    mov board[dx],al

    inc dx
    loop copy_cells_p2

    sub dx,WIDTH
    sub dx,WIDTH
    jmp shift_rows_p2

clear_top_p2:

    mov cx,WIDTH
    mov bx,0

clear_loop_p2:
    mov board[bx],0
    inc bx
    loop clear_loop_p2

    pop dx
    pop cx
    pop bx
    pop ax
    ret
remove_line endp

; =========================
; NUEVA PIEZA
; =========================
new_piece proc
    mov piece_x,4
    mov piece_y,0

    call collision
    jc game_over_set_p2
    ret

game_over_set_p2:
    mov game_over,1
    ret
new_piece endp
; =========================
; RENDER GENERAL
; =========================
render proc
    call draw_board
    call draw_piece
    call draw_ui
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
    mov dh,3              ; fila pantalla

row_loop_p3:
    push cx
    mov cx,WIDTH
    mov dl,2              ; columna pantalla

col_loop_p3:

    ; posicionar cursor
    mov ah,02h
    int 10h

    ; leer celda tablero
    cmp board[bx],1
    jne empty_cell_p3

    ; bloque lleno
    mov ah,09h
    mov al,219            ; █
    mov bl,0Ch            ; rojo
    mov cx,1
    int 10h
    jmp next_cell_p3

empty_cell_p3:
    mov ah,09h
    mov al,'.'
    mov bl,07h
    mov cx,1
    int 10h

next_cell_p3:
    inc dl
    inc bx
    loop col_loop_p3

    inc dh
    pop cx
    loop row_loop_p3

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

dp_loop_p3:

    ; Y en pantalla
    mov al,piece_y
    add al,shape[si+1]
    add al,3
    mov dh,al

    ; X en pantalla
    mov al,piece_x
    add al,shape[si]
    add al,2
    mov dl,al

    mov ah,02h
    int 10h

    ; dibujar bloque
    mov ah,09h
    mov al,219
    mov bl,0Ah            ; verde
    mov cx,1
    int 10h

    add si,2
    loop dp_loop_p3

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
draw_piece endp

; =========================
; UI (TEXTOS FIJOS)
; =========================
draw_ui proc
    ; SCORE
    mov ah,02h
    mov dh,0
    mov dl,0
    int 10h
    mov dx,offset msg_score
    mov ah,09h
    int 21h

    ; LINES
    mov ah,02h
    mov dh,1
    mov dl,0
    int 10h
    mov dx,offset msg_lines
    mov ah,09h
    int 21h

    ret
draw_ui endp

; =========================
; MOSTRAR VALORES
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

pn1_p3:
    xor dx,dx
    div bx
    push dx
    inc cx
    cmp ax,0
    jne pn1_p3

pn2_p3:
    pop dx
    add dl,'0'
    mov ah,02h
    int 21h
    loop pn2_p3

    pop dx
    pop cx
    pop bx
    pop ax
    ret
print_num endp

; =========================
; DELAY (ESTABLE)
; =========================
delay proc
    push cx

    mov cx,4000

delay_loop_p3:
    loop delay_loop_p3

    pop cx
    ret
delay endp
