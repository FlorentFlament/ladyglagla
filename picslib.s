;;; Basic picture display subroutines
        xref wait_hz_200

        xdef movepic_4colors
        xdef picdisplay
        xdef picerase

;;; Display pictures by blocks to make them appear slowly
;;; 160 bytes per line
;;; 8 lines at a time
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
        move.l  d5,a5           ; a5 points to first line to draw
        move.l  d6,a6           ; a6 points to first line of video memory
        add.l   #32000-DISPLAY_STEP,a5         ; Move a block of DISPLAY_STEP data
        add.l   #32000-DISPLAY_STEP,a6         ;
.picdisplay_loop:

        move.w  #DISPLAY_STEP-4,d0       ; Move long ints (4 bytes)
.picdisplay_line_loop:                   ; Move a DISPLAY_STEP block 4 bytes at a time
        move.l  (a5,d0.w),(a6,d0.w)
        subq.w  #4,d0
        bpl     .picdisplay_line_loop

        ;; Wait loop
        move.l  #1,d3           ; Wait 1/200th of a second
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

;;; arguments
;;; a3 address of picture
;;; a4 address of where picture needs to be writen
;;; All registers are saved then restored
movepic_16colors:
        ;; d6 - physical screen address
        ;; d5 - base picture address
        movem.l d0-d7/a0-a7,-(sp)

	;; Set picture palette
	move.l	a3,-(sp)
	move.w	#6,-(sp)	; setpalette
	trap	#14		; XBIOS trap
	addq.l	#6,sp

        ;; Copy picture data to video memory
        ;; Data starts after palette, i.e 32bytes after start of data
        add.l   #32,a3
        move.w  #32000-4,d3       ; Move long ints (4 bytes)
.move_loop:                   ; Move a DISPLAY_STEP block 4 bytes at a time
        move.l  (a3,d3.w),(a4,d3.w)
        subq.w  #4,d3
        bpl     .move_loop

        movem.l (sp)+,d0-d7/a0-a7
        rts

;;; arguments
;;; a3 address of picture
;;; a4 address of where picture needs to be writen
;;; All registers are saved then restored
movepic_4colors:
        movem.l d0-d7/a0-a7,-(sp)

	;; Set picture palette
	move.l	a3,-(sp)
	move.w	#6,-(sp)	; setpalette
	trap	#14		; XBIOS trap
	addq.l	#6,sp

        ;; Copy picture data to video memory
        ;; Data starts after palette, i.e 32bytes after start of data
        add.l   #32,a3
        move.l  #16000-4,d3     ; Move every long (4 bytes shift) from picture
        move.l  #32000-8,d4     ; Move 1 long out of 2 in (8 bytes shift) on video ram
.move_loop:
        move.l  (a3,d3.w),(a4,d4.w)
        subq.w  #4,d3
        subq.w  #8,d4
        bpl     .move_loop

        movem.l (sp)+,d0-d7/a0-a7
        rts
