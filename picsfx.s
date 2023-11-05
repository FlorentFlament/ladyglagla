;;; A few pictures FXs
        xdef picscratch_fx
        xdef picgum_fx_animation
        xdef picdisplay_stretched_4colors

        xref set_palette
        xref picstretch_d3
        xref picstretch_d4

;;; a4 - physical screen base address
;;; a5 - animation address
picgum_fx_animation:
        movem.l a0-a6/d0-d7,-(sp)
        sub.l   #(256*80),sp    ; Allocating RAM for padded picture

        move.l  (a5),a3         ; -> a3 palette address
        jsr     set_palette

        move.l  sp,a2
        ;; Copy padded image on the stack
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

        move.l  a4,a0                   ; physical screen address
        move.l  sp,a1                   ; picture address
        add.w   #(28*80),a1             ; Add 28 padding lines before picture
        lea     stretch_table,a2        ; sin table address
        move.w  #(30*80),d1
        move.w  #0,d2
        move.w  #600,d7
.loop:
        ;; Animation parameters
        move.w  #4,d3
        move.w  #5,a3
        move.w  #2,d4
        move.w  #4,a4
        jsr     picdisplay_stretched_4colors
        add.w   #14,d2
        and.w   #$01ff,d2
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

picscratch_fx:
        movem.l d0-d7/a0-a7,-(sp)

        ;; Get address of video memory
        move.w  #2,-(sp)        ; Physbase function call
        trap    #14             ; Call XBIOS
        addq.l  #2,sp
        move.l  d0,d6           ; Save physical screen ram base in d6

        move.w  #5000-1,d7      ; Rotate 5000 lines
        ;; Rotate one line
.line_loop:
        move.w  #17,-(sp)       ; random
        trap    #14             ; XBIOS trap
        addq.l  #2,sp
        and.l   #$00ff,d0       ; % 256

        cmp.w   #200,d0         ; % 200
        bmi     .mod_200
        sub.w   #200,d0

.mod_200:
        asl.w   #5,d0           ; *32
        move.w  d0,a0
        asl.w   #2,d0           ; *128
        add.w   d0,a0           ; *160
        add.l   d6,a0

        jsr     line_shift_left
        dbra    d7,.line_loop   ; <- bug

        movem.l (sp)+,d0-d7/a0-a7
        rts

;;; Shifts one line to the left
;;; Address of beginning of line must be passed in a0
;;; d0,d1,a1 are used
line_shift_left:
        move.w  #2,d1
.bitplanes_loop:
        move.w  #160,a1       ; 160 bytes per line
        sub.w   d1,a1
.rotate_loop:
        roxl.w  (a0,a1)         ; Rotate video block
        suba.w  #8,a1           ; Fix deplacement without updating SR flags
        move.w  a1,d0           ; Move deplacement and test negativity
        btst.l  #15,d0          ;
        beq     .rotate_loop
        addq.w  #2,d1
        cmpi.w  #8,d1
        ble     .bitplanes_loop
        rts

        section stretch_table,data
stretch_table:
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
