.model small
.stack 200h

.data

WIDTH  equ 10
HEIGHT equ 20

board db 200 dup(0)

piece_x db 4
piece_y db 0

; pieza simple 2x2 (estable)
piece db 0,0, 1,0, 0,1, 1,1

score dw 0
lines dw 0
level db 1
game_over db 0

tick dw 0
speed dw 8

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

; ============================================================
input proc

    mov ah,01h
    int 16h
    jz in_end

    mov ah,00h
    int 16h

    cmp al,'a'
    je in_left
    cmp al,'d'
    je in_right
    cmp al,'s'
    je in_down

    jmp in_end

in_left:
    dec piece_x
    call collision
    jc undo_left
    jmp in_end

undo_left:
    inc piece_x
    jmp in_end

in_right:
    inc piece_x
    call collision
    jc undo_right
    jmp in_end

undo_right:
    dec piece_x
    jmp in_end

in_down:
    inc piece_y
    call collision
    jc lock_piece
    jmp in_end

lock_piece:
    dec piece_y
    call fix_piece
    call clear_lines
    call new_piece

in_end:
    ret

input endp

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
collision proc

    push ax
    push bx
    push cx
    push si

    mov si,0
    mov cx,4

col_loop:

    mov al,piece_x
    add al,piece[si]
    mov bl,al

    mov al,piece_y
    add al,piece[si+1]
    mov bh,al

    cmp bl,0
    jl col_fail
    cmp bl,WIDTH
    jge col_fail

    cmp bh,HEIGHT
    jge col_fail

    xor ax,ax
    mov al,bh
    mov cl,10
    mul cl

    add al,bl
    mov bx,ax

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

    xor ax,ax
    mov al,bh
    mov cl,10
    mul cl

    add al,bl
    mov bx,ax

    mov board[bx],1

    add si,2
    dec cx
    jnz fix_loop

    pop si
    pop cx
    pop bx
    pop ax
    ret

fix_piece endp

; ============================================================
clear_lines proc

    push ax
    push bx
    push cx
    push dx

    mov cx,HEIGHT
    mov bx,0

cl_row:

    push cx

    mov cx,WIDTH
    mov dx,0

cl_cells:

    cmp board[bx],1
    jne cl_notfull

    inc dx
    inc bx
    dec cx
    jnz cl_cells

    cmp dx,WIDTH
    jne cl_notfull

    sub bx,WIDTH
    call remove_row

    inc lines
    add score,100

cl_notfull:
    add bx,WIDTH

    pop cx
    dec cx
    jnz cl_row

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
    push si
    push di

rr_shift:

    cmp bx,0
    je rr_clear

    mov cx,WIDTH

rr_copy:

    mov di,bx

    mov ax,bx
    sub ax,WIDTH
    mov si,ax

    mov al,board[si]
    mov board[di],al

    inc bx
    dec cx
    jnz rr_copy

    sub bx,WIDTH
    jmp rr_shift

rr_clear:

    mov bx,0
    mov cx,WIDTH

rr_clr:

    mov board[bx],0
    inc bx
    dec cx
    jnz rr_clr

    pop di
    pop si
    pop cx
    pop bx
    pop ax
    ret

remove_row endp

; ============================================================
new_piece proc

    mov piece_x,4
    mov piece_y,0

    call collision
    jc np_gameover

    ret

np_gameover:
    mov game_over,1
    ret

new_piece endp

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

db_row:

    push cx
    mov dl,2
    mov cx,WIDTH

db_col:

    mov ah,02h
    mov bh,0
    int 10h

    mov al,board[bx]

    cmp al,1
    jne db_empty

    mov ah,09h
    mov al,219
    mov bl,0Ah
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

    dec cx
    jnz db_col

    inc dh

    pop cx
    dec cx
    jnz db_row

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

dp_loop:

    mov al,piece_y
    add al,piece[si+1]
    add al,3
    mov dh,al

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
    jnz dp_loop

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
    dec cx
    jnz pn2

    pop dx
    pop cx
    pop bx
    pop ax
    ret

print_num endp

; ============================================================
delay proc
    push cx
    mov cx,4000
d_loop:
    dec cx
    jnz d_loop
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

end start
