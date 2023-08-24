        xref wait_hz_200

        xdef picdisplay
        xdef picdisplay_stretched
        xdef picerase
        xdef picscratch_fx
        xdef picgum_fx

DISPLAY_STEP = 8*160

;;; a0 must contain address of picture
;;; All registers are saved then restored
picdisplay:
        ;; d6 - physical screen address
        ;; d5 - base picture address
        movem.l d0-d7/a0-a7,-(sp)
        move.l  a0,d5

        ;; Get address of video memory
	move.w	#2,-(sp)	; Physbase function call
	trap	#14		; Call XBIOS
	addq.l	#2,sp
	move.l	d0,d6		; Save physical screen ram base in d6

	;; Set picture palette
	move.l	d5,-(sp)
	move.w	#6,-(sp)	; setpalette
	trap	#14		; XBIOS trap
	addq.l	#6,sp

        ;; Copy picture data to video memory
        ;; Data starts after palette, i.e 32bytes after start of data
        add.l   #32,d5
        move.l  d5,a5
        move.l  d6,a6           ; d5 and d6 point to lines to draw
        add.l   #32000-DISPLAY_STEP,a5         ; 160 bytes per line,
        add.l   #32000-DISPLAY_STEP,a6         ; 2 lines at a time
.picdisplay_loop:

        move.w  #DISPLAY_STEP-4,d0       ; 160 bytes per line, 2 lines at a time
.picdisplay_line_loop:
        move.l  (a5,d0.w),(a6,d0.w)
        subq.w  #4,d0
        bpl     .picdisplay_line_loop

        ;; Wait loop
        move.l  #1,d3
        jsr     wait_hz_200

        sub.l   #DISPLAY_STEP,a5
        sub.l   #DISPLAY_STEP,a6
        cmp.l   d5,a5
        bge     .picdisplay_loop

        movem.l (sp)+,d0-d7/a0-a7
        rts

;;; All registers are saved then restored
;;; Erases the screen
picerase:
        ;; d6 - physical screen address
        movem.l d0-d7/a0-a7,-(sp)

        ;; Get address of video memory
	move.w	#2,-(sp)	; Physbase function call
	trap	#14		; Call XBIOS
	addq.l	#2,sp
	move.l	d0,d6		; Save physical screen ram base in d6

        move.l  d6,a6           ; d6 point to lines to draw
        add.l   #32000-DISPLAY_STEP,a6         ; n lines at a time
.picdisplay_loop:

        move.w  #DISPLAY_STEP-4,d0
.picdisplay_line_loop:
        move.l  #0,(a6,d0.w)
        subq.w  #4,d0
        bpl     .picdisplay_line_loop

        ;; Wait loop
        move.l  #1,d3
        jsr     wait_hz_200

        sub.l   #DISPLAY_STEP,a6
        cmp.l   d6,a6
        bge     .picdisplay_loop

        movem.l (sp)+,d0-d7/a0-a7
        rts

;;; a5 - base picture address
picgum_fx:
	;; Set picture palette
	move.l	a5,-(sp)
	move.w	#6,-(sp)	; setpalette
	trap	#14		; XBIOS trap
	addq.l	#6,sp
        ;; Data starts after palette, i.e 32bytes after start of data
        add.l   #32,a5

        move.w  #400,d2
.loop:
        jsr     picdisplay_stretched
        dbra    d2,.loop
        rts

;;; Palette is set already
;;; Parameters
;;; a5 - base picture address
;;; d2 - index in displacement table
;;; Uses a2,a3,a4,a6
;;; Uses d0,d1,d2
picdisplay_stretched:
        movem.l d2/a5,-(sp)     ; save d2 and a5 for further use

        ;; Get address of video memory
	move.w	#2,-(sp)	; Physbase function call
	trap	#14		; Call XBIOS
	addq.l	#2,sp
	move.l	d0,a6		; Save physical screen ram base in a6

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

        movem.l (sp)+,d2/a5
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
	dc.b $01, $01, $01, $01, $01, $01, $01, $01
	dc.b $01, $01, $01, $01, $01, $01, $01, $01
	dc.b $01, $01, $01, $01, $01, $01, $01, $01
	dc.b $01, $01, $01, $01, $01, $01, $01, $01
	dc.b $01, $01, $01, $01, $01, $01, $01, $01
	dc.b $01, $01, $01, $01, $01, $01, $01, $01
	dc.b $01, $01, $01, $01, $01, $01, $01, $01
	dc.b $01, $01, $01, $01, $01, $01, $01, $01
	dc.b $01, $01, $01, $01, $01, $01, $01, $01
	dc.b $01, $01, $01, $01, $01, $01, $01, $01
	dc.b $01, $01, $01, $01, $01, $01, $01, $01
	dc.b $01, $01, $01, $01, $01, $01, $01, $01
	dc.b $01, $01, $01, $01, $01, $01, $01, $01
	dc.b $01, $01, $01, $01, $01, $01, $01, $01
	dc.b $01, $01, $01, $01, $01, $01, $01, $01
	dc.b $01, $01, $01, $01, $01, $01, $01, $01
	dc.b $01, $01, $01, $01, $01, $01, $01, $01
	dc.b $01, $01, $01, $01, $01, $01, $01, $01
	dc.b $01, $01, $01, $01, $01, $01, $01, $01
	dc.b $01, $01, $01, $01, $01, $01, $01, $01
	dc.b $01, $01, $01, $01, $01, $01, $01, $01
	dc.b $01, $01, $01, $01, $01, $01, $01, $01
	dc.b $01, $01, $01, $01, $01, $01, $01, $01
	dc.b $01, $01, $01, $01, $01, $01, $01, $01
	dc.b $01, $01, $01, $01, $01, $01, $01, $01
	dc.b $02, $02, $02, $02, $02, $02, $02, $01
	dc.b $02, $02, $02, $02, $02, $02, $02, $01
	dc.b $02, $02, $02, $02, $01, $02, $02, $01
	dc.b $02, $02, $01, $02, $02, $01, $02, $01
	dc.b $02, $01, $02, $01, $01, $02, $01, $01
	dc.b $02, $01, $01, $01, $02, $01, $01, $01
	dc.b $01, $01, $01, $01, $01, $01, $01, $01
	dc.b $00, $01, $01, $01, $00, $01, $01, $00
	dc.b $01, $00, $01, $00, $01, $00, $01, $00
	dc.b $01, $00, $00, $01, $00, $00, $01, $00
	dc.b $00, $00, $01, $00, $00, $00, $00, $00
	dc.b $01, $00, $00, $00, $00, $00, $00, $00
	dc.b $00, $00, $00, $00, $01, $00, $00, $00
	dc.b $00, $00, $00, $00, $00, $00, $00, $00
	dc.b $01, $00, $00, $00, $00, $00, $01, $00
	dc.b $00, $00, $01, $00, $00, $01, $00, $00
	dc.b $01, $00, $01, $00, $01, $00, $01, $00
	dc.b $01, $00, $01, $01, $00, $01, $01, $01
	dc.b $00, $01, $01, $01, $01, $01, $01, $01
	dc.b $01, $01, $01, $01, $02, $01, $01, $01
	dc.b $02, $01, $01, $02, $01, $01, $02, $01
	dc.b $02, $01, $02, $01, $02, $02, $01, $02
	dc.b $02, $01, $02, $02, $01, $02, $02, $02
	dc.b $02, $01, $02, $02, $02, $02, $02, $02
	dc.b $02, $01, $02, $02, $02, $02, $02, $02
	dc.b $01, $01, $01, $01, $01, $01, $01, $01
	dc.b $01, $01, $01, $01, $01, $01, $01, $01
	dc.b $01, $01, $01, $01, $01, $01, $01, $01
	dc.b $01, $01, $01, $01, $01, $01, $01, $01
	dc.b $01, $01, $01, $01, $01, $01, $01, $01
	dc.b $01, $01, $01, $01, $01, $01, $01, $01
	dc.b $01, $01, $01, $01, $01, $01, $01, $01
	dc.b $01, $01, $01, $01, $01, $01, $01, $01
	dc.b $01, $01, $01, $01, $01, $01, $01, $01
	dc.b $01, $01, $01, $01, $01, $01, $01, $01
	dc.b $01, $01, $01, $01, $01, $01, $01, $01
	dc.b $01, $01, $01, $01, $01, $01, $01, $01
	dc.b $01, $01, $01, $01, $01, $01, $01, $01
	dc.b $01, $01, $01, $01, $01, $01, $01, $01
	dc.b $01, $01, $01, $01, $01, $01, $01, $01
	dc.b $01, $01, $01, $01, $01, $01, $01, $01
	dc.b $01, $01, $01, $01, $01, $01, $01, $01
	dc.b $01, $01, $01, $01, $01, $01, $01, $01
	dc.b $01, $01, $01, $01, $01, $01, $01, $01
	dc.b $01, $01, $01, $01, $01, $01, $01, $01
	dc.b $01, $01, $01, $01, $01, $01, $01, $01
	dc.b $01, $01, $01, $01, $01, $01, $01, $01
	dc.b $01, $01, $01, $01, $01, $01, $01, $01
	dc.b $01, $01, $01, $01, $01, $01, $01, $01
	dc.b $01, $01, $01, $01, $01, $01, $01, $01
