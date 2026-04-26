shape_shift_down_pred proc 
    mov successful_magic_shift_pred, 0H 

    ; --- LIMITE INFERIOR ---
    mov bx, active_block_num_one_pred[6]
    cmp bx, play_ground_finish_row
    je exit_shape_shift_down_pred

    mov bx, active_block_num_two_pred[6]
    cmp bx, play_ground_finish_row
    je exit_shape_shift_down_pred 

    mov bx, active_block_num_three_pred[6]
    cmp bx, play_ground_finish_row
    je exit_shape_shift_down_pred

    mov bx, active_block_num_four_pred[6]
    cmp bx, play_ground_finish_row
    je exit_shape_shift_down_pred

    ; --- BLOQUE 1 ---
    mov bx, active_block_num_one_pred[0]
    mov block_start_col, bx    
    mov bx, active_block_num_one_pred[2]
    add bx, 12
    mov block_start_row, bx
    mov bx, active_block_num_one_pred[4]
    mov block_finish_col, bx    
    mov bx, active_block_num_one_pred[6]
    add bx, 12
    mov block_finish_row, bx 
    call is_this_block_free
    cmp block_is_free, 0H
    je exit_shape_shift_down_pred 

    ; --- BLOQUE 2 ---
    mov bx, active_block_num_two_pred[0]
    mov block_start_col, bx    
    mov bx, active_block_num_two_pred[2]
    add bx, 12
    mov block_start_row, bx
    mov bx, active_block_num_two_pred[4]
    mov block_finish_col, bx    
    mov bx, active_block_num_two_pred[6]
    add bx, 12
    mov block_finish_row, bx 
    call is_this_block_free
    cmp block_is_free, 0H
    je exit_shape_shift_down_pred 

    ; --- BLOQUE 3 ---
    mov bx, active_block_num_three_pred[0]
    mov block_start_col, bx    
    mov bx, active_block_num_three_pred[2]
    add bx, 12
    mov block_start_row, bx
    mov bx, active_block_num_three_pred[4]
    mov block_finish_col, bx    
    mov bx, active_block_num_three_pred[6]
    add bx, 12
    mov block_finish_row, bx 
    call is_this_block_free
    cmp block_is_free, 0H
    je exit_shape_shift_down_pred

    ; --- BLOQUE 4 ---
    mov bx, active_block_num_four_pred[0]
    mov block_start_col, bx    
    mov bx, active_block_num_four_pred[2]
    add bx, 12
    mov block_start_row, bx
    mov bx, active_block_num_four_pred[4]
    mov block_finish_col, bx    
    mov bx, active_block_num_four_pred[6]
    add bx, 12
    mov block_finish_row, bx 
    call is_this_block_free
    cmp block_is_free, 0H
    je exit_shape_shift_down_pred    

    ; --- SI TODO ESTA LIBRE ---
    call magic_shift_down_pred
    mov successful_magic_shift_pred, 1H

exit_shape_shift_down_pred:
    ret
endp shape_shift_down_pred
magic_shift_down_pred proc

    ; --- BLOQUE 1 ---
    mov bx, active_block_num_one_pred[2]
    add bx, 12
    mov active_block_num_one_pred[2], bx  

    mov bx, active_block_num_one_pred[6]
    add bx, 12
    mov active_block_num_one_pred[6], bx  

    ; --- BLOQUE 2 ---
    mov bx, active_block_num_two_pred[2]
    add bx, 12
    mov active_block_num_two_pred[2], bx    

    mov bx, active_block_num_two_pred[6]
    add bx, 12
    mov active_block_num_two_pred[6], bx 

    ; --- BLOQUE 3 ---
    mov bx, active_block_num_three_pred[2]
    add bx, 12
    mov active_block_num_three_pred[2], bx    

    mov bx, active_block_num_three_pred[6]
    add bx, 12
    mov active_block_num_three_pred[6], bx 

    ; --- BLOQUE 4 ---
    mov bx, active_block_num_four_pred[2]
    add bx, 12
    mov active_block_num_four_pred[2], bx    

    mov bx, active_block_num_four_pred[6]
    add bx, 12
    mov active_block_num_four_pred[6], bx 

    ret
endp magic_shift_down_pred
proc predict

    ; --- COPIA ---
    mov cx, 8

copy_loop:
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

    ; --- CAIDA RAPIDA ---
fast_loop_pred: 
    call shape_shift_down_pred
    cmp successful_magic_shift_pred, 0H
    je fast_loop_pred_exit
    jmp fast_loop_pred

fast_loop_pred_exit: 

    ; --- DIBUJO ---
    mov bl, block_colour 
    mov block_border_colour, bl

    ; BLOQUE 1
    mov bx, active_block_num_one_pred[0]
    mov block_start_col, bx
    mov bx, active_block_num_one_pred[2]
    mov block_start_row, bx 
    mov bx, active_block_num_one_pred[4]
    mov block_finish_col, bx 
    mov bx, active_block_num_one_pred[6]
    mov block_finish_row, bx  
    call draw_single_block_border

    ; BLOQUE 2
    mov bx, active_block_num_two_pred[0]
    mov block_start_col, bx
    mov bx, active_block_num_two_pred[2]
    mov block_start_row, bx 
    mov bx, active_block_num_two_pred[4]
    mov block_finish_col, bx 
    mov bx, active_block_num_two_pred[6]
    mov block_finish_row, bx  
    call draw_single_block_border

    ; BLOQUE 3
    mov bx, active_block_num_three_pred[0]
    mov block_start_col, bx
    mov bx, active_block_num_three_pred[2]
    mov block_start_row, bx 
    mov bx, active_block_num_three_pred[4]
    mov block_finish_col, bx 
    mov bx, active_block_num_three_pred[6]
    mov block_finish_row, bx  
    call draw_single_block_border

    ; BLOQUE 4
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
