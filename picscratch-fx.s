        xref wait_hz_200

        xdef picdisplay
        xdef picscratch_fx

DISPLAY_STEP = 1280

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
