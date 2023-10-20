        xdef animation

        xref wait_hz_200
        xref set_palette
        xref movepic_4colors

;;; a4 address of video memory
;;; a5 address of animation data
;;; a6 address of animation sequence
;;; registers will be saved and restored
animation:
        movem.l a3/d3-d5,-(sp)

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

        movem.l (sp)+,a3/d3-d5
        rts
