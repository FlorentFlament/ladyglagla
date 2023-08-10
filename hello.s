	xref picture_logo_data
	xref picture_logo_palette

	section code,code
main:
	;; Get address of video memory
	move.w	#2,-(sp)	; Physbase function call
	trap	#14		; Call XBIOS
	addq.l	#2,sp
	move.l	d0,a6		; Save physical screen ram base in a6

	;; Set picture palette
	move.l	#picture_logo_palette,-(sp)
	move.w	#6,-(sp)	; setpalette
	trap	#14		; XBIOS trap
	addq.l	#6,sp

        ;; Copy picture data to video memory
        move.l  #picture_logo_data,a1
        move.w  #32000-4,d1
.loop:
        move.l  (a1,d1.w),(a6,d1.w)
        sub.w   #4,d1
        bpl     .loop

        ;; Wait for any key press then return
	move.w	#8,-(sp)	; Cnecin
	trap	#1		; GEMDOS
        addq.l	#2,sp
	clr.w	-(sp)		; Pterm0
	trap	#1		; GEMDOS

        section bss,bss
        ;; Put variables here
