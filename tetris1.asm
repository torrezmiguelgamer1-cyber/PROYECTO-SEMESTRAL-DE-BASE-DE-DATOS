; ============================================================
; TETRIS EXTENSO ESTILO CLÁSICO (SIN MATRICES COMPLEJAS)
; ============================================================

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
; PIEZA ACTUAL (4 BLOQUES)
; =========================
piece db 8 dup(0)

piece_x db 4
piece_y db 0

; tipo simple (vamos a cambiar manualmente)
piece_type db 0

; =========================
; VARIABLES
; =========================
score dw 0
lines dw 0
level db 1
game_over db 0

tick dw 0
speed dw 6

; =========================
; TEXTOS
; =========================
msg_score db 'SCORE:$'
msg_lines db 'LINES:$'
msg_level db 'LEVEL:$'
msg_over  db 'GAME OVER$'

.code

; ============================================================
start:

    mov ax,@data
    mov ds,ax

    mov ax,0003h
    int 10h

    call init
    call new_piece

main_loop:

    cmp game_over,1
    je end_game

    call input
    call update
    call render
    call delay

    jmp main_loop
; ============================================================
init proc

    push cx
    push di

    mov cx,200
    mov di,0

clear_loop:
    mov board[di],0
    inc di
    loop clear_loop

    mov score,0
    mov lines,0
    mov level,1
    mov game_over,0

    pop di
    pop cx
    ret

init endp
; ============================================================
new_piece proc

    ; random simple
    mov ah,00h
    int 1Ah

    mov al,dl
    and al,3
    mov piece_type,al

    mov piece_x,4
    mov piece_y,0

    call load_piece_simple
    call collision

    jc game_over_set
    ret

game_over_set:
    mov game_over,1
    ret

new_piece endp
; ============================================================
load_piece_simple proc

    mov al,piece_type

    cmp al,0
    je piece_square

    cmp al,1
    je piece_line

    cmp al,2
    je piece_L

    jmp piece_T

; ===== CUADRADO =====
piece_square:
    mov piece[0],0
    mov piece[1],0
    mov piece[2],1
    mov piece[3],0
    mov piece[4],0
    mov piece[5],1
    mov piece[6],1
    mov piece[7],1
    ret

; ===== LINEA =====
piece_line:
    mov piece[0],0
    mov piece[1],0
    mov piece[2],1
    mov piece[3],0
    mov piece[4],2
    mov piece[5],0
    mov piece[6],3
    mov piece[7],0
    ret

; ===== L =====
piece_L:
    mov piece[0],0
    mov piece[1],0
    mov piece[2],0
    mov piece[3],1
    mov piece[4],0
    mov piece[5],2
    mov piece[6],1
    mov piece[7],2
    ret

; ===== T =====
piece_T:
    mov piece[0],0
    mov piece[1],0
    mov piece[2],1
    mov piece[3],0
    mov piece[4],2
    mov piece[5],0
    mov piece[6],1
    mov piece[7],1
    ret

load_piece_simple endp
; ============================================================
collision proc

    push ax
    push bx
    push cx
    push dx
    push si

    mov si,0
    mov cx,4

col_loop:

    ; ---- calcular X ----
    mov al,piece_x
    add al,piece[si]
    mov bl,al

    ; ---- calcular Y ----
    mov al,piece_y
    add al,piece[si+1]
    mov bh,al

    ; ---- limite izquierdo ----
    cmp bl,0
    jl col_fail

    ; ---- limite derecho ----
    cmp bl,WIDTH
    jge col_fail

    ; ---- limite abajo ----
    cmp bh,HEIGHT
    jge col_fail

    ; ---- indice = y*10 + x ----
    mov al,bh
    mov ah,0
    mov dl,10
    mul dl        ; AX = y*10

    mov dl,bl
    xor dh,dh
    add ax,dx

    mov bx,ax

    ; ---- colision tablero ----
    cmp board[bx],1
    je col_fail

    add si,2
    dec cx
    jnz col_loop

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
move_left proc

    dec piece_x
    call collision
    jc undo_left
    ret

undo_left:
    inc piece_x
    ret

move_left endp
; ============================================================
move_right proc

    inc piece_x
    call collision
    jc undo_right
    ret

undo_right:
    dec piece_x
    ret

move_right endp
; ============================================================
move_down proc

    inc piece_y
    call collision
    jc lock_piece
    ret

move_down endp
; ============================================================
fix_piece proc

    push ax
    push bx
    push cx
    push dx
    push si

    mov si,0
    mov cx,4

fix_loop:

    mov al,piece_x
    add al,piece[si]
    mov bl,al

    mov al,piece_y
    add al,piece[si+1]
    mov bh,al

    ; index = y*10 + x
    mov al,bh
    mov ah,0
    mov dl,10
    mul dl

    mov dl,bl
    xor dh,dh
    add ax,dx

    mov bx,ax
    mov board[bx],1

    add si,2
    dec cx
    jnz fix_loop

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

fix_piece endp
; ============================================================
lock_piece proc

    dec piece_y

    call fix_piece
    call clear_lines
    call new_piece

    ret

lock_piece endp
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
input proc

    mov ah,01h
    int 16h
    jz input_exit

    mov ah,00h
    int 16h

    cmp al,'a'
    je key_left

    cmp al,'d'
    je key_right

    cmp al,'s'
    je key_down

input_exit:
    ret

key_left:
    call move_left
    ret

key_right:
    call move_right
    ret

key_down:
    call move_down
    ret

input endp
; ============================================================
render proc

    call draw_board
    call draw_piece
    call draw_ui

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

    mov cx,HEIGHT

row_loop:

    push cx

    mov dl,2
    mov cx,WIDTH

col_loop:

    mov ah,02h
    mov bh,0
    int 10h

    mov al,board[bx]

    cmp al,1
    jne empty_cell

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

    dec cx
    jnz col_loop

    inc dh

    pop cx
    dec cx
    jnz row_loop

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

    mov si,0
    mov cx,4

piece_loop:

    ; Y
    mov al,piece_y
    add al,piece[si+1]
    add al,3
    mov dh,al

    ; X
    mov al,piece_x
    add al,piece[si]
    add al,2
    mov dl,al

    mov ah,02h
    mov bh,0
    int 10h

    mov ah,09h
    mov al,219
    mov bl,0Ch
    mov cx,1
    int 10h

    add si,2
    dec cx
    jnz piece_loop

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

draw_piece endp
; ============================================================
draw_ui proc

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

    ; LEVEL
    mov ah,02h
    mov dh,2
    mov dl,0
    int 10h
    mov dx,offset msg_level
    mov ah,09h
    int 21h

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

draw_ui endp
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
    dec cx
    jnz pn_loop2

    pop dx
    pop cx
    pop bx
    pop ax
    ret

print_num endp
; ============================================================
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

cell_check:

    cmp board[bx],1
    jne not_full

    inc dx
    inc bx
    dec cx
    jnz cell_check

    cmp dx,WIDTH
    jne not_full

    ; fila llena
    sub bx,WIDTH
    call remove_row

    inc lines
    add score,100

not_full:
    add bx,WIDTH

    pop cx
    dec cx
    jnz row_check

    pop dx
    pop cx
    pop bx
    pop ax
    ret

clear_lines endp
; ============================================================
remove_row proc

    push ax
    push bx
    push cx
    push dx
    push si
    push di

shift_loop:

    cmp bx,0
    je clear_top

    mov cx,WIDTH

copy_cells:

    mov di,bx

    mov ax,bx
    sub ax,WIDTH
    mov si,ax

    mov al,board[si]
    mov board[di],al

    inc bx
    dec cx
    jnz copy_cells

    sub bx,WIDTH
    jmp shift_loop

clear_top:

    mov bx,0
    mov cx,WIDTH

clear_cells:
    mov board[bx],0
    inc bx
    dec cx
    jnz clear_cells

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

remove_row endp
; ============================================================
delay proc

    push cx

    mov cx,3000

delay_loop:
    dec cx
    jnz delay_loop

    pop cx
    ret

delay endp
; ============================================================
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
