proc clear_predict
    mov block_border_colour, 0H

    mov bx, active_block_num_one_pred[0]
    mov block_start_col, bx
    mov bx, active_block_num_one_pred[2]
    mov block_start_row, bx
    mov bx, active_block_num_one_pred[4]
    mov block_finish_col, bx
    mov bx, active_block_num_one_pred[6]
    mov block_finish_row, bx
    call draw_single_block_border

    mov bx, active_block_num_two_pred[0]
    mov block_start_col, bx
    mov bx, active_block_num_two_pred[2]
    mov block_start_row, bx
    mov bx, active_block_num_two_pred[4]
    mov block_finish_col, bx
    mov bx, active_block_num_two_pred[6]
    mov block_finish_row, bx
    call draw_single_block_border

    mov bx, active_block_num_three_pred[0]
    mov block_start_col, bx
    mov bx, active_block_num_three_pred[2]
    mov block_start_row, bx
    mov bx, active_block_num_three_pred[4]
    mov block_finish_col, bx
    mov bx, active_block_num_three_pred[6]
    mov block_finish_row, bx
    call draw_single_block_border

    mov bx, active_block_num_four_pred[0]
    mov block_start_col, bx
    mov bx, active_block_num_four_pred[2]
    mov block_start_row, bx
    mov bx, active_block_num_four_pred[4]
    mov block_finish_col, bx
    mov bx, active_block_num_four_pred[6]
    mov block_finish_row, bx
    call draw_single_block_border

    ret
endp clear_predict
proc predict

    call clear_predict   ; limpia ghost anterior

    ; copiar bloque actual
    mov bx, active_block_num_one[0]  
    mov active_block_num_one_pred[0], bx
    mov bx, active_block_num_one[2]  
    mov active_block_num_one_pred[2], bx 
    mov bx, active_block_num_one[4]  
    mov active_block_num_one_pred[4], bx 
    mov bx, active_block_num_one[6]  
    mov active_block_num_one_pred[6], bx 

    mov bx, active_block_num_two[0] 
    mov active_block_num_two_pred[0], bx 
    mov bx, active_block_num_two[2] 
    mov active_block_num_two_pred[2], bx
    mov bx, active_block_num_two[4] 
    mov active_block_num_two_pred[4], bx
    mov bx, active_block_num_two[6] 
    mov active_block_num_two_pred[6], bx  

    mov bx, active_block_num_three[0]
    mov active_block_num_three_pred[0], bx
    mov bx, active_block_num_three[2]
    mov active_block_num_three_pred[2], bx
    mov bx, active_block_num_three[4]
    mov active_block_num_three_pred[4], bx
    mov bx, active_block_num_three[6]
    mov active_block_num_three_pred[6], bx 

    mov bx, active_block_num_four[0]
    mov active_block_num_four_pred[0], bx 
    mov bx, active_block_num_four[2]
    mov active_block_num_four_pred[2], bx
    mov bx, active_block_num_four[4]
    mov active_block_num_four_pred[4], bx
    mov bx, active_block_num_four[6]
    mov active_block_num_four_pred[6], bx

fast_loop_pred: 
    call shape_shift_down_pred
    cmp successful_magic_shift_pred, 0H
    je fast_loop_pred_exit
    jmp fast_loop_pred

fast_loop_pred_exit: 

    ; ⚠️ IMPORTANTE: color tenue para ghost
    mov block_border_colour, 08H   ; gris

    ; dibujar SOLO bordes (NO fill)
    mov bx, active_block_num_one_pred[0]
    mov block_start_col, bx
    mov bx, active_block_num_one_pred[2]
    mov block_start_row, bx 
    mov bx, active_block_num_one_pred[4]
    mov block_finish_col, bx 
    mov bx, active_block_num_one_pred[6]
    mov block_finish_row, bx  
    call draw_single_block_border

    mov bx, active_block_num_two_pred[0]
    mov block_start_col, bx
    mov bx, active_block_num_two_pred[2]
    mov block_start_row, bx 
    mov bx, active_block_num_two_pred[4]
    mov block_finish_col, bx 
    mov bx, active_block_num_two_pred[6]
    mov block_finish_row, bx  
    call draw_single_block_border

    mov bx, active_block_num_three_pred[0]
    mov block_start_col, bx
    mov bx, active_block_num_three_pred[2]
    mov block_start_row, bx 
    mov bx, active_block_num_three_pred[4]
    mov block_finish_col, bx 
    mov bx, active_block_num_three_pred[6]
    mov block_finish_row, bx  
    call draw_single_block_border

    mov bx, active_block_num_four_pred[0]
    mov block_start_col, bx
    mov bx, active_block_num_four_pred[2]
    mov block_start_row, bx 
    mov bx, active_block_num_four_pred[4]
    mov block_finish_col, bx 
    mov bx, active_block_num_four_pred[6]
    mov block_finish_row, bx  
    call draw_single_block_border

    ret
endp predict
proc display_score     
    mov ah, 02H
    mov bh, 00H
    mov dh, 02H
    mov dl, 02H    
    int 10h

    mov ah, 09H
    lea dx, msg_score
    int 21h  

    ret
endp display_score
proc update_score 
    xor ax, ax
    mov si, 9 
    mov ax, score
    mov bx, 10

convert_loop:
    cmp si, 5
    je score_done
    xor dx, dx
    div bx
    add dl, 30h
    mov [msg_score+si], dl
    dec si
    jmp convert_loop

score_done:
    call display_score 
    ret
endp update_score 
