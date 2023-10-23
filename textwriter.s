        xref wait_hz_200
        xdef textwriter

;;; a0 Address of text to write - will be overwritten
;;; as d0-d2/a0-d2
;;; Text to write must end with character \0
textwriter:
        movem.l a3/d3,-(sp)
        move.l  a0,a3

.loop:
        move.b  (a3),d3
        beq     .end            ; finish if character \0 encountered

        move.w  d3,-(sp)
        move.w  #2,-(sp)        ; Cconout
        trap    #1              ; Gemdos trap
        addq.l  #4,sp

        move.l  #8,d3
        jsr     wait_hz_200
        add.l   #1,a3
        bra     .loop

.end:
        movem.l (sp)+,a3/d3
        rts
