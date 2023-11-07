;;; Picture stretching effect
        xdef picgum_fx_animation
        xdef picdisplay_stretched_4colors

        xref set_palette

;;; a4 - physical screen base address
;;; a5 - animation address
picgum_fx_animation:
        movem.l a0-a6/d0-d7,-(sp)
        sub.l   #(256*80),sp    ; Allocating RAM for padded picture

        ;; set palette
        move.l  (a5),a3
        jsr     set_palette

        ;; Copy padded image on the stack
        ;; This can be done more beautifully at some point
        move.l  sp,a2
        move.w  #0,d2
.pre_padloop:
        move.l  #0,(a2,d2)
        addq.w  #4,d2
        cmpi    #(28*80),d2
        blt     .pre_padloop

        add.w   #(28*80),a2
        move.l  4(a5),a3         ; -> a3 image address
        move.w  #0,d2
.copy_loop:
        move.l  (a3,d2),(a2,d2)
        addq.w  #4,d2
        cmpi    #(200*80),d2
        blt     .copy_loop

        add.w   #(200*80),a2
        move.w  #0,d2
.post_padloop:
        move.l  #0,(a2,d2)
        addq.w  #4,d2
        cmpi    #(28*80),d2
        blt     .post_padloop

        ;; using a5 to fetch data from picstretch_table
        lea     picstretch_table,a5
        
        ;; Animation initial parameters
        move.l  a4,a0                   ; physical screen address
        move.l  sp,a1                   ; picture address
        add.w   #(28*80),a1             ; Add 28 padding lines before picture
        lea     wave_table,a2        ; sin table address
        move.w  #(50*80),d1                ; pic initial offset
        move.w  #0,d2                ; wave sin initial offset
        move.w  #333,d3         ; d3/a3 pic stretch ratio
;        move.w  #266,a3
        move.w  #100,a3
        move.w  #1,d4           ; d4/a4 sin stretch ratio
        move.w  #1000,a4

        ;; Animation Loop
        move.w  #600,d7
.loop:
        ;; Animation parameters
        jsr     picdisplay_stretched_4colors

        ;; pic offset
;        add.w   #80,d1
;        cmp.w   #(80*200),d1
;        blt     .mod_200
;        sub.w   #(80*200),d1
.mod_200:
        ;; sin offset
;        add.w   #18,d2
;        and.w   #$01ff,d2
        
        ;; Compute image vertical stretching
        move.w  d7,d0
        and.w   #$3f,d0
        asl.w   #1,d0
        move.w  (a5,d0),d3
;        ;; Compute offset in picture
;        move.w  d3,d1
;        sub.w   #100,d1
;        asl.w   #4,d1   ; *16
;        move.w  d1,d0
;        asl.w   #2,d1   ; *64
;        add.w   d0,d1   ; *80
        
        
;        add.w   #1,d4
        dbra    d7,.loop

        add.l   #(256*80),sp
        movem.l (sp)+,a0-a6/d0-d7
        rts

;;; Palette is set already
;;; Parameters:
;;; a0 phy_base_addr base address of screen physical memory
;;; a1 pic_base_addr base address of picture to display
;;; a2 sin_base_addr base address of sinus table
;;; d1 pic_offset initial offset in picture - multiple of 80
;;; d2 sin_offset initial offset in sinus table - multiple of 2
;;; d3/a3 pic_X/pic_Y picture stretch ratio
;;; d4/a4 sin_X/sin_Y sinus table stretch ratio
picdisplay_stretched_4colors:
        movem.l a0-a6/d0-d7,-(sp)       ; save registers in stack

        ;; Some initialization
        lea.l   (200*160)(a0),a5        ; phy_end - End of screen physical mem
        lea.l   (200*80)(a1),a6         ; pic_end - End of picture
        move.w  a3,d5                   ; pic_Z - pic ratio computation
        subq.w  #1,d5                   ; minus 1
        move.w  a4,d6                   ; sin_Z - sin ratio computation
        subq.w  #1,d6                   ; minus 1
        ;; Compute pic_line_addr from pic_base_addr and pic_offset
        add.w   d1,a1

.picdisplay_loop:
        ;; a0 - phy_line_addr is the address of the current physical line
        ;; a1 - pic_line_addr is the address of the current picture line
        ;;      without wave offset

        move.w  (a2,d2),d0      ; retrieving sin offset
                                ; as word, already multiple of 80
        ;; Display a line
        REPT 20
        move.l  REPTN*4(a1,d0),REPTN*8(a0)
        ENDR

        ;;
        ;; Prepare next picture line
        ;;

        ;; Compute next picture line (considering picture stretch ratio)
        ;; Substract pic_X from pic_Z
        sub.w   d3,d5
        ;; As long as pic_Z <0 increase it by pic_Y and increase pic_line_addr
        bpl     .picz_positive
.picz_negative:
        add.w   #80,a1
        add.w   a3,d5
        bmi     .picz_negative
.picz_positive:
        cmp.l   a6,a1
        blt     .mod_200
        sub.w   #(200*80),a1
.mod_200:

        ;; Compute next sintable offset (considering sin table stretch ratio)
        ;; Substract sin_X from sin_Z
        sub.w   d4,d6
        ;; As long as sin_Z<0 increase it by sin_Y and increase sin_table_offset
        bpl     .sinz_positive
.sinz_negative:
        add.w   #2,d2
        add.w   a4,d6
        bmi     .sinz_negative
.sinz_positive:
        and.w   #$01ff,d2       ; d2 % 512

        add.w   #160,a0         ; next video buffer line (a4)

        cmp.l   a5,a0           ; Loop until end of display areay is reached
        blt     .picdisplay_loop

        movem.l (sp)+,a0-a6/d0-d7       ; restore registers from stack
        rts
        

        section wave_table,data
wave_table:
        dc.w $0000, $0000, $0000, $0050, $0050, $0050, $0050, $00a0
        dc.w $00a0, $00a0, $00a0, $00f0, $00f0, $00f0, $00f0, $0140
        dc.w $0140, $0140, $0140, $0140, $0190, $0190, $0190, $0190
        dc.w $01e0, $01e0, $01e0, $01e0, $01e0, $0230, $0230, $0230
        dc.w $0230, $0230, $0230, $0280, $0280, $0280, $0280, $0280
        dc.w $0280, $0280, $02d0, $02d0, $02d0, $02d0, $02d0, $02d0
        dc.w $02d0, $02d0, $02d0, $02d0, $0320, $0320, $0320, $0320
        dc.w $0320, $0320, $0320, $0320, $0320, $0320, $0320, $0320
        dc.w $0320, $0320, $0320, $0320, $0320, $0320, $0320, $0320
        dc.w $0320, $0320, $0320, $0320, $0320, $02d0, $02d0, $02d0
        dc.w $02d0, $02d0, $02d0, $02d0, $02d0, $02d0, $02d0, $0280
        dc.w $0280, $0280, $0280, $0280, $0280, $0280, $0230, $0230
        dc.w $0230, $0230, $0230, $0230, $01e0, $01e0, $01e0, $01e0
        dc.w $01e0, $0190, $0190, $0190, $0190, $0140, $0140, $0140
        dc.w $0140, $0140, $00f0, $00f0, $00f0, $00f0, $00a0, $00a0
        dc.w $00a0, $00a0, $0050, $0050, $0050, $0050, $0000, $0000
        dc.w $0000, $0000, $0000, $ffb0, $ffb0, $ffb0, $ffb0, $ff60
        dc.w $ff60, $ff60, $ff60, $ff10, $ff10, $ff10, $ff10, $fec0
        dc.w $fec0, $fec0, $fec0, $fec0, $fe70, $fe70, $fe70, $fe70
        dc.w $fe20, $fe20, $fe20, $fe20, $fe20, $fdd0, $fdd0, $fdd0
        dc.w $fdd0, $fdd0, $fdd0, $fd80, $fd80, $fd80, $fd80, $fd80
        dc.w $fd80, $fd80, $fd30, $fd30, $fd30, $fd30, $fd30, $fd30
        dc.w $fd30, $fd30, $fd30, $fd30, $fce0, $fce0, $fce0, $fce0
        dc.w $fce0, $fce0, $fce0, $fce0, $fce0, $fce0, $fce0, $fce0
        dc.w $fce0, $fce0, $fce0, $fce0, $fce0, $fce0, $fce0, $fce0
        dc.w $fce0, $fce0, $fce0, $fce0, $fce0, $fd30, $fd30, $fd30
        dc.w $fd30, $fd30, $fd30, $fd30, $fd30, $fd30, $fd30, $fd80
        dc.w $fd80, $fd80, $fd80, $fd80, $fd80, $fd80, $fdd0, $fdd0
        dc.w $fdd0, $fdd0, $fdd0, $fdd0, $fe20, $fe20, $fe20, $fe20
        dc.w $fe20, $fe70, $fe70, $fe70, $fe70, $fec0, $fec0, $fec0
        dc.w $fec0, $fec0, $ff10, $ff10, $ff10, $ff10, $ff60, $ff60
        dc.w $ff60, $ff60, $ffb0, $ffb0, $ffb0, $ffb0, $0000, $0000

picstretch_table:
	dc.w $007d, $0084, $008c, $0093, $009a, $00a0, $00a7, $00ad
	dc.w $00b2, $00b7, $00bb, $00bf, $00c2, $00c5, $00c7, $00c8
	dc.w $00c8, $00c8, $00c7, $00c5, $00c2, $00bf, $00bb, $00b7
	dc.w $00b2, $00ad, $00a7, $00a0, $009a, $0093, $008c, $0084
	dc.w $007d, $0076, $006e, $0067, $0060, $005a, $0053, $004d
	dc.w $0048, $0043, $003f, $003b, $0038, $0035, $0033, $0032
	dc.w $0032, $0032, $0033, $0035, $0038, $003b, $003f, $0043
	dc.w $0048, $004d, $0053, $005a, $0060, $0067, $006e, $0076
