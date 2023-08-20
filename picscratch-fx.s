        xref picture_callisto_glafouk
        xdef picscratch_fx

picscratch_fx:
        ;; Get address of video memory
	move.w	#2,-(sp)	; Physbase function call
	trap	#14		; Call XBIOS
	addq.l	#2,sp
	move.l	d0,a6		; Save physical screen ram base in a6

	;; Set picture palette
	move.l	#picture_callisto_glafouk,-(sp)
	move.w	#6,-(sp)	; setpalette
	trap	#14		; XBIOS trap
	addq.l	#6,sp

        ;; Hide mouse with a line A function
        dc.w    $A00A

        ;; Copy picture data to video memory
        ;; Data starts after palette, i.e 32bytes after start of data
        move.l  #picture_callisto_glafouk+32,a1
        move.w  #32000-4,d0
.pic_loop:
        move.l  (a1,d0.w),(a6,d0.w)
        subq.w  #4,d0
        bpl     .pic_loop

        ;; Wait for any key press then return
	move.w	#8,-(sp)	; Cnecin
	trap	#1		; GEMDOS
        addq.l	#2,sp

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

        rts
