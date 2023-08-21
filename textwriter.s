        xdef textwriter

textwriter:
        pea     text_data
        move.w  #9,-(sp)        ; Cconws
        trap    #1              ; Gemdos trap
        addq.l  #6,sp
        rts

        section text_data,data
text_data:
        dc.b    $1b,'Y',' '+5,' '+14,"Hey, Hey !",13,10
        dc.b    $1b,'Y',' '+6,' '+14,"Have you seen my t-shirt ?",13,10
        dc.b    0
