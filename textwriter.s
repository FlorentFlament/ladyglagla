        xref wait_hz_200
        xdef textwriter

textwriter:
        lea     text_data,a3

.loop:
        move.b  (a3),d3
        beq     .end            ; finish if character \0 encountered

        move.w  d3,-(sp)
        move.w  #2,-(sp)        ; Cconout
        trap    #1              ; Gemdos trap
        addq.l  #4,sp

        move.l  #10,d3
        jsr     wait_hz_200
        add.l   #1,a3
        bra     .loop

.end:
        rts

        section text_data,data
text_data:
        dc.b    $1b,'Y',' '+5,' '+14,"Hey, Hey !",13,10
        dc.b    $1b,'Y',' '+6,' '+14,"Have you seen my t-shirt ?",13,10
        dc.b    0
