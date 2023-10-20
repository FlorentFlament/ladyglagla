        xdef animation

        xref wait_hz_200
        xref set_palette
        xref movepic_4colors

        xref VraiREglagla01_data

;;; a4 address of video memory
;;; a5 address of animation data
;;; registers will be saved and restored
animation:
        movem.l a3/d3/d4,-(sp)

        move.l  $00(a5),a3
        jsr     set_palette

        move.l  #25,d3          ; wait 1/8th second (/ 200 8)
        move.b  #5,d4           ; Repeating animation 5 times
.loop:
        move.l  $04(a5),a3
        jsr     movepic_4colors
        jsr     wait_hz_200
        move.l  $08(a5),a3
        jsr     movepic_4colors
        jsr     wait_hz_200
        move.l  $0c(a5),a3
        jsr     movepic_4colors
        jsr     wait_hz_200
        move.l  $10(a5),a3
        jsr     movepic_4colors
        jsr     wait_hz_200
        subq.b  #1,d4
        bpl     .loop

        movem.l (sp)+,a3/d3/d4
        rts
