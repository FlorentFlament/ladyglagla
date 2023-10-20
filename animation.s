        xdef animation

        xref wait_hz_200
        xref set_palette
        xref movepic_4colors
        
        xref VraiREglagla01_palette
        xref VraiREglagla01_0001_data
        xref VraiREglagla01_0002_data
        xref VraiREglagla01_0003_data
        xref VraiREglagla01_0004_data
        
animation:      
        lea     VraiREglagla01_palette,a3
        jsr     set_palette

        move.l  #25,d3          ; wait 1/8th second (/ 200 8)
        move.b  #5,d4           ; Repeating animation 5 times
.VraiREglagla01:
        lea     VraiREglagla01_0001_data,a3
        jsr     movepic_4colors
        jsr     wait_hz_200
        lea     VraiREglagla01_0002_data,a3
        jsr     movepic_4colors
        jsr     wait_hz_200
        lea     VraiREglagla01_0003_data,a3
        jsr     movepic_4colors
        jsr     wait_hz_200
        lea     VraiREglagla01_0004_data,a3
        jsr     movepic_4colors
        jsr     wait_hz_200
        subq.b  #1,d4
        bpl     .VraiREglagla01

        rts
