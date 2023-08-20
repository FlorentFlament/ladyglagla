        xdef picscratch_fx

;;; a0 must contain address of picture
;;; All registers are saved then restored
picscratch_fx:
        movem.l d0-d7/a0-a7,-(sp)
        move.l  a0,a5

        ;; Get address of video memory
	move.w	#2,-(sp)	; Physbase function call
	trap	#14		; Call XBIOS
	addq.l	#2,sp
	move.l	d0,a6		; Save physical screen ram base in a6

	;; Set picture palette
	move.l	a5,-(sp)
	move.w	#6,-(sp)	; setpalette
	trap	#14		; XBIOS trap
	addq.l	#6,sp

        ;; Copy picture data to video memory
        ;; Data starts after palette, i.e 32bytes after start of data
        move.l  #32,a1
        add.l   a5,a1
        move.w  #32000-4,d0
.pic_loop:
        move.l  (a1,d0.w),(a6,d0.w)
        subq.w  #4,d0
        bpl     .pic_loop

        ;; Wait loop
        move.l  #600,-(sp)
        jsr     wait_hz_200
        addq.l  #4,sp

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
        add.l   a6,a0

        jsr     line_shift_left
        dbra    d7,.line_loop

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

;;; Wait loop: argument is 200th of second
;;; Passed on the stack for fun
;;; 8(sp) to access the argument ??
;;; Uses d3
wait_hz_200::
        move.l  d3,-(sp)        ; Save registers content

	pea       get_hz_200
	move.w    #38,-(sp)    ; Supexec function call
	trap      #14          ; Call XBIOS
	addq.l    #6,sp        ; Correct stack
        ;; d0 has the value of hz_200 timer
        move.l  d0,d3
        add.l   8(sp),d3        ; Store target time in d3

.wait_loop:
	pea       get_hz_200
	move.w    #38,-(sp)    ; Supexec function call
	trap      #14          ; Call XBIOS
	addq.l    #6,sp        ; Correct stack
        cmp.l   d0,d3
        bge     .wait_loop      ; Loop until d0 >= d3, delay has elapsed

        move.l  (sp)+,d3        ; Restore registers content
        rts

;;; To be called by Supexec
;;; returns the content of the 200 Hz timer in d0. It's 32 bits long
;;; https://freemint.github.io/tos.hyp/en/bios_sysvars.html
get_hz_200:
        ;; TOS maintains a system variable at $0004ba traditionally
        ;; named hz_200. This is a counter that is incremented 200
        ;; times per second, controlled by Timer C on the timer chip
        ;; source: https://bumbershootsoft.wordpress.com/2021/05/29/timing-on-the-atari-st/
        move.l  $0004ba,d0
        rts
