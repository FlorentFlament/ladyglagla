        move.w	#2,-(sp)        ; Physbase function call
        trap  	#14             ; Call XBIOS
        addq.l	#2,sp           ; Correct stack
        move.l  d0,phybase      ; save physical screen ram base

        move.l  phybase,a1
        move.w  #32000-8,d1         ; 4*63
.loop:
        ;; 16bits words represent 16 consecutive bits
        ;; 4 such words represent 4 bitplanes - encoding pixel colors
        move.l  #$f0f00000,0(a1,d1)
        move.l  #$f0f00000,4(a1,d1)
        sub.w   #8,d1
        bpl     .loop
        
        ;; End of program
	move.w	#8,-(sp)	; Cnecin
	trap	#1		; GEMDOS
	addq.l	#2,sp
	clr.w	-(sp)		; Pterm0
	trap	#1		; GEMDOS

;;; Variables
phybase         DC.L    1
