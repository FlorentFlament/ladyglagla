        xdef animation
        xdef spinlock_hz200_3

        xref wait_hz_200
        xref set_palette
        xref movepic_4colors

;;; a3 address of time_pointers (3x longs)
;;; -> d0 contains hz_200
spinlock_hz200_3:
.loop:
        move.l  $0004ba,d0      ; retrieve hz_200
        cmp.l   0(a3),d0        ; compare with t_next_chr
        bgt     .break
        cmp.l   4(a3),d0        ; compare with t_next_pic
        bgt     .break
        cmp.l   4(a3),d0        ; compare with t_end
        bgt     .break
        bra     .loop
.break:
        rts

;;; a4 address where picture will be writen
;;; a5 address of animation data
;;; a6 address of animation sequence
;;; d5 index in sequence table
draw_pic:
        movem.l d6/a3,-(sp)
        move.w  #0,d6           ; inialize d6 word
        move.b  (a6,d5.w),d6    ; retrieve index in data table from sequence table
.seq_loop:
        asl.w   #2,d6           ; compute index in data table
        move.l  (a5,d6.w),a3
        jsr     movepic_4colors
        movem.l (sp)+,d6/a3

        ;; Update sequence index
        addq.w  #1,d5
        tst.b   (a6,d5.w)       ; check whether end of sequence table has been reached
        bne     .end
        move.w  #0,d5           ; loop in sequence table with 0 is read
.end:
        rts

;;; Address of next character is in d3
draw_char:
        movem.l a0-a2/d0-d2,-(sp)
        move.l  d3,a0
        move.b  (a0),d0
        beq     .end            ; finish if character \0 encountered
        ;; Display character
        move.w  d0,-(sp)
        move.w  #2,-(sp)        ; Cconout
        trap    #1              ; Gemdos trap
        addq.l  #4,sp
        ;; increase character pointer
        addq.w  #1,d3
.end:
        movem.l (sp)+,a0-a2/d0-d2
        rts

;;; d3 address of string to write
;;; d6 duration of animation in hz_200 ticks
;;;     1 beat is 160 hz_200 ticks
;;;     16 beats animation - number of transitions (typically 1 or 2)
;;;     (* 14 160) 2240 -> minus 10-20 margin -> 2230
;;; a4 address of video memory
;;; a5 address of animation data
;;; a6 address of animation sequence
;;; registers will be saved and restored
animation:
        movem.l a0-a3/d0-d3/d5,-(sp)
        ;; t_next_chr = 0(sp)
        ;; t_next_pic = 4(sp)
        ;; t_end = 8(sp)
        sub.l   #12,sp           ; Allocate 3 longs in the stack
        jsr     get_hz_200
        move.l  d0,0(sp)
        add.l   #160,0(sp)       ; time for second character
        move.l  d0,4(sp)
        add.l   #25,4(sp)       ; time for next picture
        move.l  d0,8(sp)
        add.l   d6,8(sp)     ; time before end

        move.l  (a5),a3         ; -> a3 palette address
        move.w  #0,d5           ; initialize sequence index in d5
        jsr     set_palette
        jsr     draw_pic
        jsr     draw_char

        move.l  sp,a3           ; store address of time counters for use in spinlock
.main_loop:
        ;; Spin lock until one event is reached
        pea     spinlock_hz200_3
	move.w  #38,-(sp)    ; Supexec function call
	trap    #14          ; Call XBIOS
	addq.l  #6,sp        ; Correct stack

        ;; What to we do ?
        cmp.l   0(sp),d0        ; compare with t_next_chr
        ble     .t_next_pic
        ;; Display a character
        jsr     draw_char
        add.l   #10,0(sp)       ; prepare for next character display
.t_next_pic:
        cmp.l   4(sp),d0        ; compare with t_next_pic
        ble     .t_end
        ;; Display next pic
        jsr     draw_pic
        add.l   #25,4(sp)       ; prepare for next pic display
.t_end:
        cmp.l   8(sp),d0        ; compare with t_end
        ble     .main_loop
        ;; End of animation
        add.l   #12,sp          ; Unallocate the 3 longs in stack
        movem.l (sp)+,a0-a3/d0-d3/d5
        rts
