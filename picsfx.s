;;; A few pictures FXs
        xdef picscratch_fx
        xdef picgum_fx_animation

        xref wait_hz_200
        xref set_palette
        xref picstretch_d3
        xref picstretch_d4


;;; a5 - base picture address
picgum_fx:
        movem.l a3/a5/d2,-(sp)
        move.l  a5,a3
        jsr     set_palette
        ;; Data starts after palette, i.e 32bytes after start of data
        add.l   #32,a5
        move.w  #400,d2
.loop:
        jsr     picdisplay_stretched
        dbra    d2,.loop
        movem.l (sp)+,a3/a5/d2
        rts

;;; a5 - animation address
picgum_fx_animation:
        movem.l a3/a5/d2-d5,-(sp)
        move.l  (a5),a3         ; -> a3 palette address
        jsr     set_palette
        move.l  4(a5),a5        ; next long is address of first animation picture data
        move.w  #20,d5           ; 3 loops
.big_loop:
        move.w  #0,d2
.loop:
        ;; Animation parameters
        move.w  picstretch_d3,d3
        move.w  picstretch_d4,d4
        jsr     picdisplay_stretched_4colors
        addq.w  #2,d2
        cmpi.w  #200,d2
        blt     .loop
        dbra    d5,.big_loop
        movem.l (sp)+,a3/a5/d2-d5
        rts

;;; Palette is set already
;;; Parameters
;;; a4 - physical screen base address
;;; a5 - base picture address
;;; d2 - index in displacement table
;;; Uses a2,a3,a4,a6
;;; Uses d0,d1,d2
picdisplay_stretched:
        movem.l a2-a6/d0-d2,-(sp)     ; save d2 and a5 for further use
	move.l	a4,a6		; Save physical screen ram base in a6

        lea.l   32000(a5),a4    ; Compute end of picture in a4
        lea.l   32000(a6),a2    ; End of screen in a2

        lea.l   stretch_table,a3 ; a3 contains stretch_table address
        ;; 2 200Hz ticks for a 1 plan display loop
        ;; 3 200Hz ticks for a 2 plans display loop
        ;; 6 200Hz ticks for a 4 plans display loop
.picdisplay_loop:
        REPT 40
        move.l  REPTN*4(a5),REPTN*4(a6)
        ENDR
        addq.w  #1,d2           ; increase line count
        add.w   #160,a6         ; write next picture line
        move.b  (a3,d2),d0      ; line displacement on the picture
        and.w   #$ff,d0
        asl.w   #5,d0           ; *32
        move.w  d0,d1           ; save value in d1
        asl.w   #2,d0           ; *128
        add.w   d1,d0           ; *160
        add.w   d0,a5           ; update displacement on the picture
        cmpa.l  a4,a5           ; modulus picture size
        blt     .mod_32000
        sub.l   #32000,a5
.mod_32000:
        cmp.l   a2,a6         ; display 200 lines
        blt     .picdisplay_loop

        movem.l (sp)+,a2-a6/d0-d2
        rts

;;; Palette is set already
;;; Parameters
;;; a4 - physical screen base address
;;; a5 - base picture address
;;; d2 - index in displacement table
;;; d3,d4 - speed in the displacement table is d3/d4
;;; Uses a2,a3,a4,a6
;;; Uses d0,d1,d2,d4
picdisplay_stretched_4colors:
        movem.l a2-a6/d0-d2/d5,-(sp)     ; save d2 and a5 for further use
	move.l	a4,a6		; Save physical screen ram base in a6

        lea.l   16000(a5),a4    ; Compute end of picture in a4
        lea.l   32000(a6),a2    ; End of screen in a2

        lea.l   stretch_table,a3 ; a3 contains stretch_table address
        ;; 2 200Hz ticks for a 1 plan display loop
        ;; 3 200Hz ticks for a 2 plans display loop
        ;; 6 200Hz ticks for a 4 plans display loop

        move.w  d4,d5           ; Using d5 as a counter
        subi.w  #1,d5
.picdisplay_loop:
        ;; a5 = base picture addr
        ;; a6 = base video memory addr
        REPT 20
        move.l  REPTN*4(a5),REPTN*8(a6)
        ENDR

        ;; Compute how many items to move forward in the table, i.e d3/d5
        ;; Substract d3 from d5
        sub.w   d3,d5
        ;; As long as d5 <0 increase d5 by d4 and increase d2 by 1
        bpl     .d5_positive
.d5_addloop:
        addq.w  #1,d2           ; increase line count
        add.w   d4,d5
        bmi     .d5_addloop
.d5_positive:

        cmpi.l  #200,d2         ; mod 200 (table is 200 long)
        blt     .mod_200
        sub.l   #200,d2
.mod_200:
        add.w   #160,a6         ; write next picture line
        move.b  (a3,d2),d0      ; line displacement on the picture
        and.w   #$ff,d0
        ;;
        asl.w   #4,d0           ; *16
        move.w  d0,d1           ; save value in d1
        asl.w   #2,d0           ; *64
        add.w   d1,d0           ; *80
        add.w   d0,a5           ; update displacement on the picture
        cmpa.l  a4,a5           ; modulus picture size
        blt     .mod_16000
        sub.l   #16000,a5
.mod_16000:
        cmp.l   a2,a6         ; display 200 lines
        blt     .picdisplay_loop

        movem.l (sp)+,a2-a6/d0-d2/d5
        rts

picscratch_fx:
        movem.l d0-d7/a0-a7,-(sp)

        ;; Get address of video memory
	move.w	#2,-(sp)	; Physbase function call
	trap	#14		; Call XBIOS
	addq.l	#2,sp
	move.l	d0,d6		; Save physical screen ram base in d6

        move.w  #5000-1,d7      ; Rotate 5000 lines
        ;; Rotate one line
.line_loop:
	move.w	#17,-(sp)	; random
	trap	#14		; XBIOS trap
        addq.l	#2,sp
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
	dc.b $01, $02, $01, $02, $01, $02, $01, $01
	dc.b $02, $01, $01, $02, $01, $01, $02, $01
	dc.b $01, $01, $01, $02, $01, $01, $01, $01
	dc.b $01, $01, $01, $01, $01, $01, $01, $00
	dc.b $01, $01, $01, $00, $01, $01, $01, $00
	dc.b $01, $00, $01, $01, $00, $01, $00, $01
	dc.b $01, $00, $01, $00, $01, $00, $01, $01
	dc.b $00, $01, $00, $01, $01, $00, $01, $01
	dc.b $00, $01, $01, $01, $01, $00, $01, $01
	dc.b $01, $01, $01, $01, $01, $01, $01, $01
	dc.b $01, $02, $01, $01, $01, $01, $02, $01
	dc.b $01, $02, $01, $01, $02, $01, $02, $01
	dc.b $01, $02, $01, $02, $01, $02, $01, $02
	dc.b $01, $01, $02, $01, $02, $01, $01, $02
	dc.b $01, $01, $02, $01, $01, $01, $01, $02
	dc.b $01, $01, $01, $01, $01, $01, $01, $01
	dc.b $01, $01, $01, $00, $01, $01, $01, $01
	dc.b $00, $01, $01, $00, $01, $01, $00, $01
	dc.b $00, $01, $01, $00, $01, $00, $01, $00
	dc.b $01, $01, $00, $01, $00, $01, $01, $00
	dc.b $01, $00, $01, $01, $01, $00, $01, $01
	dc.b $01, $00, $01, $01, $01, $01, $01, $01
	dc.b $01, $01, $01, $01, $01, $02, $01, $01
	dc.b $01, $01, $02, $01, $01, $02, $01, $01
	dc.b $02, $01, $01, $02, $01, $02, $01, $02
