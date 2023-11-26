        xref wait_hz_200
        xdef textwriter

;;; a3 Address of text to write - will be moved just after end of
;;; string ('\0')
textwriter:
        movem.l d0-d3/a0-a2,-(sp)

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
        add.l   #1,a3
        movem.l (sp)+,d0-d3/a0-a2
        rts
