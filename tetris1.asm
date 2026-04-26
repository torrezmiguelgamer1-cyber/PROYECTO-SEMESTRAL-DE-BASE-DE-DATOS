.model small
.stack 64

.data

; ==============================
; MENSAJES
; ==============================
msg_puntaje db 'PUNTAJE: 0000$'

; ==============================
; VARIABLES PRINCIPALES
; ==============================
score dw 0

block_colour db 0Ah
block_border_colour db 0

position db 1
random_shape_number db 0

shift_counter db 0
successful_magic_shift db 0
successful_magic_shift_pred db 0

block_is_free db 0

; ==============================
; LIMITES DEL JUEGO
; ==============================
play_ground_start_col dw 20
play_ground_finish_col dw 300
play_ground_finish_row dw 200

; ==============================
; BLOQUES ACTIVOS (ACTUAL)
; ==============================
active_block_num_one   dw 0,0,0,0
active_block_num_two   dw 0,0,0,0
active_block_num_three dw 0,0,0,0
active_block_num_four  dw 0,0,0,0

; ==============================
; BLOQUES PREDICCION (SIN MOSTRAR)
; ==============================
active_block_num_one_pred   dw 0,0,0,0
active_block_num_two_pred   dw 0,0,0,0
active_block_num_three_pred dw 0,0,0,0
active_block_num_four_pred  dw 0,0,0,0

; ==============================
; CENTROS DE ROTACION
; ==============================
active_block_center dw 0,0,0,0,0,0,0,0

; ==============================
; VARIABLES DE DIBUJO
; ==============================
block_start_col dw 0
block_start_row dw 0
block_finish_col dw 0
block_finish_row dw 0

.code

; ==========================================
; INICIO
; ==========================================
start:
    mov ax, @data
    mov ds, ax

    call clear_screen
    call draw_border
    call display_puntaje

main_loop:
    call read_input
    call update_game
    jmp main_loop

; ==========================================
; LIMPIAR PANTALLA
; ==========================================
clear_screen proc
    mov ax, 0600h
    mov bh, 07
    mov cx, 0000
    mov dx, 184Fh
    int 10h
    ret
clear_screen endp

; ==========================================
; MOSTRAR PUNTAJE
; ==========================================
display_puntaje proc
    mov ah, 02h
    mov bh, 0
    mov dh, 2
    mov dl, 2
    int 10h

    mov ah, 09h
    lea dx, msg_puntaje
    int 21h
    ret
display_puntaje endp

; ==========================================
; ACTUALIZAR PUNTAJE
; ==========================================
update_puntaje proc
    mov ax, score
    mov bx, 10
    mov si, 12

convert_loop:
    xor dx, dx
    div bx
    add dl, '0'
    mov msg_puntaje[si], dl
    dec si
    cmp si, 8
    jne convert_loop

    call display_puntaje
    ret
update_puntaje endp
; ==========================================
; SHIFT ABAJO (CAIDA REAL)
; ==========================================
shape_shift_down proc
    mov successful_magic_shift, 0

    ; ----- CHECK BLOCK 1
    mov bx, active_block_num_one[6]
    cmp bx, play_ground_finish_row
    je exit_shift_down

    mov bx, active_block_num_one[0]
    mov block_start_col, bx
    mov bx, active_block_num_one[2]
    add bx, 12
    mov block_start_row, bx
    mov bx, active_block_num_one[4]
    mov block_finish_col, bx
    mov bx, active_block_num_one[6]
    add bx, 12
    mov block_finish_row, bx
    call is_this_block_free
    cmp block_is_free, 0
    je exit_shift_down

    ; ----- CHECK BLOCK 2
    mov bx, active_block_num_two[6]
    cmp bx, play_ground_finish_row
    je exit_shift_down

    mov bx, active_block_num_two[0]
    mov block_start_col, bx
    mov bx, active_block_num_two[2]
    add bx, 12
    mov block_start_row, bx
    mov bx, active_block_num_two[4]
    mov block_finish_col, bx
    mov bx, active_block_num_two[6]
    add bx, 12
    mov block_finish_row, bx
    call is_this_block_free
    cmp block_is_free, 0
    je exit_shift_down

    ; ----- CHECK BLOCK 3
    mov bx, active_block_num_three[6]
    cmp bx, play_ground_finish_row
    je exit_shift_down

    mov bx, active_block_num_three[0]
    mov block_start_col, bx
    mov bx, active_block_num_three[2]
    add bx, 12
    mov block_start_row, bx
    mov bx, active_block_num_three[4]
    mov block_finish_col, bx
    mov bx, active_block_num_three[6]
    add bx, 12
    mov block_finish_row, bx
    call is_this_block_free
    cmp block_is_free, 0
    je exit_shift_down

    ; ----- CHECK BLOCK 4
    mov bx, active_block_num_four[6]
    cmp bx, play_ground_finish_row
    je exit_shift_down

    mov bx, active_block_num_four[0]
    mov block_start_col, bx
    mov bx, active_block_num_four[2]
    add bx, 12
    mov block_start_row, bx
    mov bx, active_block_num_four[4]
    mov block_finish_col, bx
    mov bx, active_block_num_four[6]
    add bx, 12
    mov block_finish_row, bx
    call is_this_block_free
    cmp block_is_free, 0
    je exit_shift_down

    call magic_shift_down
    mov successful_magic_shift, 1

exit_shift_down:
    ret
shape_shift_down endp


; ==========================================
; SHIFT IZQUIERDA
; ==========================================
shape_shift_left proc
    mov successful_magic_shift, 0

    mov bx, active_block_num_one[0]
    cmp bx, play_ground_start_col
    je exit_left

    mov bx, active_block_num_one[0]
    sub bx, 12
    mov block_start_col, bx
    mov bx, active_block_num_one[2]
    mov block_start_row, bx
    mov bx, active_block_num_one[4]
    sub bx, 12
    mov block_finish_col, bx
    mov bx, active_block_num_one[6]
    mov block_finish_row, bx
    call is_this_block_free
    cmp block_is_free, 0
    je exit_left

    call magic_shift_left
    mov successful_magic_shift, 1

exit_left:
    ret
shape_shift_left endp


; ==========================================
; SHIFT DERECHA
; ==========================================
shape_shift_right proc
    mov successful_magic_shift, 0

    mov bx, active_block_num_one[4]
    cmp bx, play_ground_finish_col
    je exit_right

    mov bx, active_block_num_one[0]
    add bx, 12
    mov block_start_col, bx
    mov bx, active_block_num_one[2]
    mov block_start_row, bx
    mov bx, active_block_num_one[4]
    add bx, 12
    mov block_finish_col, bx
    mov bx, active_block_num_one[6]
    mov block_finish_row, bx
    call is_this_block_free
    cmp block_is_free, 0
    je exit_right

    call magic_shift_right
    mov successful_magic_shift, 1

exit_right:
    ret
shape_shift_right endp


; ==========================================
; SHIFT ARRIBA
; ==========================================
shape_shift_up proc
    mov successful_magic_shift, 0

    mov bx, active_block_num_one[2]
    cmp bx, 0
    je exit_up

    mov bx, active_block_num_one[0]
    mov block_start_col, bx
    mov bx, active_block_num_one[2]
    sub bx, 12
    mov block_start_row, bx
    mov bx, active_block_num_one[4]
    mov block_finish_col, bx
    mov bx, active_block_num_one[6]
    sub bx, 12
    mov block_finish_row, bx
    call is_this_block_free
    cmp block_is_free, 0
    je exit_up

    call magic_shift_up
    mov successful_magic_shift, 1

exit_up:
    ret
shape_shift_up endp
; ==========================================
; MOVIMIENTO REAL ABAJO
; ==========================================
magic_shift_down proc
    call erase_all_blocks

    add active_block_num_one[2], 12
    add active_block_num_one[6], 12

    add active_block_num_two[2], 12
    add active_block_num_two[6], 12

    add active_block_num_three[2], 12
    add active_block_num_three[6], 12

    add active_block_num_four[2], 12
    add active_block_num_four[6], 12

    call draw_all_blocks
    ret
magic_shift_down endp


; ==========================================
; IZQUIERDA
; ==========================================
magic_shift_left proc
    call erase_all_blocks

    sub active_block_num_one[0], 12
    sub active_block_num_one[4], 12

    sub active_block_num_two[0], 12
    sub active_block_num_two[4], 12

    sub active_block_num_three[0], 12
    sub active_block_num_three[4], 12

    sub active_block_num_four[0], 12
    sub active_block_num_four[4], 12

    call draw_all_blocks
    ret
magic_shift_left endp


; ==========================================
; DERECHA
; ==========================================
magic_shift_right proc
    call erase_all_blocks

    add active_block_num_one[0], 12
    add active_block_num_one[4], 12

    add active_block_num_two[0], 12
    add active_block_num_two[4], 12

    add active_block_num_three[0], 12
    add active_block_num_three[4], 12

    add active_block_num_four[0], 12
    add active_block_num_four[4], 12

    call draw_all_blocks
    ret
magic_shift_right endp


; ==========================================
; ARRIBA
; ==========================================
magic_shift_up proc
    call erase_all_blocks

    sub active_block_num_one[2], 12
    sub active_block_num_one[6], 12

    sub active_block_num_two[2], 12
    sub active_block_num_two[6], 12

    sub active_block_num_three[2], 12
    sub active_block_num_three[6], 12

    sub active_block_num_four[2], 12
    sub active_block_num_four[6], 12

    call draw_all_blocks
    ret
magic_shift_up endp
erase_all_blocks proc
    call erase_single_block
    ret
erase_all_blocks endp

draw_all_blocks proc
    call draw_single_block
    ret
draw_all_blocks endp
; ==========================================
; ROTACION PRINCIPAL
; ==========================================
shape_rotate proc

    mov shift_counter, 0

    ; ==============================
    ; CHECK BLOQUE 1
    ; ==============================
    mov bx, active_block_num_one[0]
    mov cx, active_block_center[2]
    add bx, cx
    mov cx, active_block_center[0]
    sub bx, cx
    mov block_start_row, bx

    mov bx, active_block_center[0]
    mov cx, active_block_center[2]
    add bx, cx
    mov cx, active_block_num_one[2]
    sub bx, cx
    mov block_start_col, bx

    mov bx, active_block_num_one[4]
    mov cx, active_block_center[6]
    add bx, cx
    mov cx, active_block_center[4]
    sub bx, cx
    mov block_finish_row, bx

    mov bx, active_block_center[4]
    mov cx, active_block_center[6]
    add bx, cx
    mov cx, active_block_num_one[6]
    sub bx, cx
    mov block_finish_col, bx

    call is_this_block_free
    cmp block_is_free, 0
    je rot_shift_inc

    jmp rot_check_2

rot_shift_inc:
    inc shift_counter

; ==============================
; CHECK BLOQUE 2
; ==============================
rot_check_2:

    mov bx, active_block_num_two[0]
    mov cx, active_block_center[2]
    add bx, cx
    mov cx, active_block_center[0]
    sub bx, cx
    mov block_start_row, bx

    mov bx, active_block_center[0]
    mov cx, active_block_center[2]
    add bx, cx
    mov cx, active_block_num_two[2]
    sub bx, cx
    mov block_start_col, bx

    mov bx, active_block_num_two[4]
    mov cx, active_block_center[6]
    add bx, cx
    mov cx, active_block_center[4]
    sub bx, cx
    mov block_finish_row, bx

    mov bx, active_block_center[4]
    mov cx, active_block_center[6]
    add bx, cx
    mov cx, active_block_num_two[6]
    sub bx, cx
    mov block_finish_col, bx

    call is_this_block_free
    cmp block_is_free, 0
    je rot_shift_inc2

    jmp rot_check_3

rot_shift_inc2:
    inc shift_counter

; ==============================
; CHECK BLOQUE 3
; ==============================
rot_check_3:

    mov bx, active_block_num_three[0]
    mov cx, active_block_center[2]
    add bx, cx
    mov cx, active_block_center[0]
    sub bx, cx
    mov block_start_row, bx

    mov bx, active_block_center[0]
    mov cx, active_block_center[2]
    add bx, cx
    mov cx, active_block_num_three[2]
    sub bx, cx
    mov block_start_col, bx

    mov bx, active_block_num_three[4]
    mov cx, active_block_center[6]
    add bx, cx
    mov cx, active_block_center[4]
    sub bx, cx
    mov block_finish_row, bx

    mov bx, active_block_center[4]
    mov cx, active_block_center[6]
    add bx, cx
    mov cx, active_block_num_three[6]
    sub bx, cx
    mov block_finish_col, bx

    call is_this_block_free
    cmp block_is_free, 0
    je rot_shift_inc3

    jmp rot_check_4

rot_shift_inc3:
    inc shift_counter

; ==============================
; CHECK BLOQUE 4
; ==============================
rot_check_4:

    mov bx, active_block_num_four[0]
    mov cx, active_block_center[2]
    add bx, cx
    mov cx, active_block_center[0]
    sub bx, cx
    mov block_start_row, bx

    mov bx, active_block_center[0]
    mov cx, active_block_center[2]
    add bx, cx
    mov cx, active_block_num_four[2]
    sub bx, cx
    mov block_start_col, bx

    mov bx, active_block_num_four[4]
    mov cx, active_block_center[6]
    add bx, cx
    mov cx, active_block_center[4]
    sub bx, cx
    mov block_finish_row, bx

    mov bx, active_block_center[4]
    mov cx, active_block_center[6]
    add bx, cx
    mov cx, active_block_num_four[6]
    sub bx, cx
    mov block_finish_col, bx

    call is_this_block_free
    cmp block_is_free, 0
    je rot_shift_inc4

    jmp rot_apply

rot_shift_inc4:
    inc shift_counter


; ==========================================
; APLICAR CORRECCION SI HAY COLISION
; ==========================================
rot_apply:

    cmp shift_counter, 0
    je rot_execute

    call shape_shift_left
    cmp successful_magic_shift, 0
    je shape_rotate_exit

    dec shift_counter
    jmp rot_apply


; ==========================================
; EJECUTAR ROTACION
; ==========================================
rot_execute:

    call erase_all_blocks

    ; ===== aplicar rotación real (cambio coords)

    ; bloque 1
    call rotate_block_one

    ; bloque 2
    call rotate_block_two

    ; bloque 3
    call rotate_block_three

    ; bloque 4
    call rotate_block_four

    call draw_all_blocks

    jmp shape_rotate_exit


; ==========================================
; SALIDA
; ==========================================
shape_rotate_exit:
    inc position
    cmp position, 5
    jne rot_end

    mov position, 1

rot_end:
    call draw_border
    ret

shape_rotate endp
rotate_block_one proc
    mov bx, active_block_num_one[0]
    mov cx, active_block_center[2]
    add bx, cx
    mov cx, active_block_center[0]
    sub bx, cx
    mov active_block_num_one[2], bx

    mov bx, active_block_center[0]
    mov cx, active_block_center[2]
    add bx, cx
    mov cx, active_block_num_one[2]
    sub bx, cx
    mov active_block_num_one[0], bx
    ret
rotate_block_one endp


rotate_block_two proc
    mov bx, active_block_num_two[0]
    mov cx, active_block_center[2]
    add bx, cx
    mov cx, active_block_center[0]
    sub bx, cx
    mov active_block_num_two[2], bx

    mov bx, active_block_center[0]
    mov cx, active_block_center[2]
    add bx, cx
    mov cx, active_block_num_two[2]
    sub bx, cx
    mov active_block_num_two[0], bx
    ret
rotate_block_two endp


rotate_block_three proc
    mov bx, active_block_num_three[0]
    mov cx, active_block_center[2]
    add bx, cx
    mov cx, active_block_center[0]
    sub bx, cx
    mov active_block_num_three[2], bx

    mov bx, active_block_center[0]
    mov cx, active_block_center[2]
    add bx, cx
    mov cx, active_block_num_three[2]
    sub bx, cx
    mov active_block_num_three[0], bx
    ret
rotate_block_three endp


rotate_block_four proc
    mov bx, active_block_num_four[0]
    mov cx, active_block_center[2]
    add bx, cx
    mov cx, active_block_center[0]
    sub bx, cx
    mov active_block_num_four[2], bx

    mov bx, active_block_center[0]
    mov cx, active_block_center[2]
    add bx, cx
    mov cx, active_block_num_four[2]
    sub bx, cx
    mov active_block_num_four[0], bx
    ret
rotate_block_four endp
; ==========================================
; UPDATE GAME LOOP (CAIDA + FIJACION)
; ==========================================
update_game proc

    call shape_shift_down
    cmp successful_magic_shift, 1
    je update_exit

    ; si no pudo bajar → fijar pieza
    call fix_current_piece
    call check_complete_lines
    call spawn_new_piece

update_exit:
    ret
update_game endp
fix_current_piece proc

    ; bloque 1
    mov bx, active_block_num_one[0]
    mov block_start_col, bx
    mov bx, active_block_num_one[2]
    mov block_start_row, bx
    mov bx, active_block_num_one[4]
    mov block_finish_col, bx
    mov bx, active_block_num_one[6]
    mov block_finish_row, bx
    call paint_fixed_block

    ; bloque 2
    mov bx, active_block_num_two[0]
    mov block_start_col, bx
    mov bx, active_block_num_two[2]
    mov block_start_row, bx
    mov bx, active_block_num_two[4]
    mov block_finish_col, bx
    mov bx, active_block_num_two[6]
    mov block_finish_row, bx
    call paint_fixed_block

    ; bloque 3
    mov bx, active_block_num_three[0]
    mov block_start_col, bx
    mov bx, active_block_num_three[2]
    mov block_start_row, bx
    mov bx, active_block_num_three[4]
    mov block_finish_col, bx
    mov bx, active_block_num_three[6]
    mov block_finish_row, bx
    call paint_fixed_block

    ; bloque 4
    mov bx, active_block_num_four[0]
    mov block_start_col, bx
    mov bx, active_block_num_four[2]
    mov block_start_row, bx
    mov bx, active_block_num_four[4]
    mov block_finish_col, bx
    mov bx, active_block_num_four[6]
    mov block_finish_row, bx
    call paint_fixed_block

    ret
fix_current_piece endp
check_complete_lines proc

    mov cx, play_ground_finish_row

row_loop:
    cmp cx, 0
    je end_check

    push cx
    call is_row_full
    cmp ax, 1
    jne next_row

    call clear_row
    call move_rows_down

    add score, 10
    call update_puntaje

next_row:
    pop cx
    sub cx, 12
    jmp row_loop

end_check:
    ret
check_complete_lines endp
is_row_full proc
    mov ax, 1
    mov bx, play_ground_start_col

col_loop:
    cmp bx, play_ground_finish_col
    je row_full

    mov block_start_col, bx
    mov block_start_row, cx
    call is_this_block_free

    cmp block_is_free, 1
    je row_not_full

    add bx, 12
    jmp col_loop

row_not_full:
    mov ax, 0

row_full:
    ret
is_row_full endp
clear_row proc
    mov bx, play_ground_start_col

clear_loop:
    cmp bx, play_ground_finish_col
    je clear_done

    mov block_start_col, bx
    mov block_start_row, cx
    call erase_single_block

    add bx, 12
    jmp clear_loop

clear_done:
    ret
clear_row endp
move_rows_down proc

    mov dx, cx

move_loop:
    cmp dx, 0
    je end_move

    mov bx, play_ground_start_col

inner_loop:
    cmp bx, play_ground_finish_col
    je next_row_move

    ; copiar bloque de arriba hacia abajo
    mov block_start_col, bx
    mov block_start_row, dx
    call copy_block_down

    add bx, 12
    jmp inner_loop

next_row_move:
    sub dx, 12
    jmp move_loop

end_move:
    ret
move_rows_down endp
spawn_new_piece proc

    mov position, 1

    ; pseudo random simple
    mov ax, score
    and ax, 3
    mov random_shape_number, al

    ; reiniciar en el centro superior
    mov active_block_num_one[0], 120
    mov active_block_num_one[2], 0
    mov active_block_num_one[4], 132
    mov active_block_num_one[6], 12

    mov active_block_num_two[0], 132
    mov active_block_num_two[2], 0
    mov active_block_num_two[4], 144
    mov active_block_num_two[6], 12

    mov active_block_num_three[0], 144
    mov active_block_num_three[2], 0
    mov active_block_num_three[4], 156
    mov active_block_num_three[6], 12

    mov active_block_num_four[0], 156
    mov active_block_num_four[2], 0
    mov active_block_num_four[4], 168
    mov active_block_num_four[6], 12

    call draw_all_blocks

    ret
spawn_new_piece endp
read_input proc
    mov ah, 01h
    int 16h
    jz no_key

    mov ah, 00h
    int 16h

    cmp ah, 4Bh
    je move_left

    cmp ah, 4Dh
    je move_right

    cmp ah, 50h
    je move_down

    cmp ah, 48h
    je rotate_key

    jmp no_key

move_left:
    call shape_shift_left
    jmp no_key

move_right:
    call shape_shift_right
    jmp no_key

move_down:
    call shape_shift_down
    jmp no_key

rotate_key:
    call shape_rotate

no_key:
    ret
read_input endp
end start
