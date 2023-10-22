        xdef animation

        xref wait_hz_200
        xref set_palette
        xref movepic_4colors

spinlock_hz200_3:
.loop:
        move.l  $0004ba,d0      ; retrieve hz_200
        cmp.l   $6(sp),d0        ; compare with t_next_chr
        ble     .break
        cmp.l   $a(sp),d0       ; compare with t_next_pic
        ble     .break
        cmp.l   $e(sp),d0       ; compare with t_end
        ble     .break
        bra     .loop
.break:
        rts

;;; a4 address of video memory
;;; a5 address of animation data
;;; a6 address of animation sequence
;;; registers will be saved and restored
animation:
        movem.l a0-a3/d0-d5,-(sp)
        ;; t_next_chr = 0(sp)
        ;; t_next_pic = 4(sp)
        ;; t_end = 8(sp)
        sub.l   #12,sp           ; Allocate 3 longs in the stack
        jsr     get_hz_200
        move.l  d0,0(sp)
        add.l   #10,0(sp)
        move.l  d0,4(sp)
        add.l   #25,4(sp)
        move.l  d0,8(sp)
        add.l   #160,8(sp)     ; 4x MUSIC_TEMPO

        ;; Spin lock until one event is reached
        pea     spinlock_hz200_3
	move.w  #38,-(sp)    ; Supexec function call
	trap    #14          ; Call XBIOS
	addq.l  #6,sp        ; Correct stack

        move.l  (a5),a3
        jsr     set_palette

        move.l  #25,d3          ; wait 1/8th second (/ 200 8)
        move.w  #5,d4           ; Repeating animation 5 times
.big_loop:
        move.w  #0,d5           ; index in sequence table
        move.w  #0,d6           ; inialize d6 word
        move.b  (a6,d5.w),d6    ; retrieve index in data table from sequence table
.seq_loop:
        asl.w   #2,d6           ; compute index in data table
        move.l  (a5,d6.w),a3
        jsr     movepic_4colors
        jsr     wait_hz_200
        addq.w  #1,d5
        move.w  #0,d6           ; inialize d6 word
        move.b  (a6,d5.w),d6    ; retrieve index in data table from sequence table
        bne     .seq_loop

        subq.b  #1,d4
        bpl     .big_loop

        add.l   #12,sp          ; Unallocate the 3 longs in stack
        movem.l (sp)+,a0-a3/d0-d5
        rts
