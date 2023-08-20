        xref PLY_AKYst_Start
        xref music_data
        xref picscratch_fx

	section code
main:
        ;; Initialize music player
	lea     music_data,a0
	jsr     PLY_AKYst_Start+0           ;init player and tune

        ;; Setup music player in VBL
	pea       set_music_player_vbl
	move.w    #38,-(sp)    ; Supexec function call
	trap      #14          ; Call XBIOS
	addq.l    #6,sp        ; Correct stack

        jsr picscratch_fx

        ;; Wait for any key press then return
	move.w	#8,-(sp)	; Cnecin
	trap	#1		; GEMDOS
        addq.l	#2,sp

        ;; Restore previous VBL
	pea       restore_vbl
	move.w    #38,-(sp)    ; Supexec function call
	trap      #14          ; Call XBIOS
	addq.l    #6,sp        ; Correct stack

        ;; Display mouse with a line A function
        dc.w    $A009

	clr.w	-(sp)		; Pterm0
	trap	#1		; GEMDOS

;;; Shifts one line to the left
;;; Address of beginning of line must be passed in a0
;;; d0,d1,a1 are used
line_shift_left::
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

set_music_player_vbl:
	move    sr,-(sp)
	move    #$2700,sr       ; Disable interrupts (assumption to check)
	move.l  $70.w,old_vbl   ; Save VBL
	move.l  #vbl,$70.w      ; Set new VBL with player
	move    (sp)+,sr        ; Enable interrupts
        rts

vbl::
	movem.l d0-a6,-(sp)
	lea     music_data,a0           ;tell the player where to find the tune start
	jsr     PLY_AKYst_Start+2       ;play that funky music
	movem.l (sp)+,d0-a6
old_vbl=*+2
        jmp     'Fixx'

restore_vbl:
	move    sr,-(sp)
	move    #$2700,sr
	move.l  old_vbl,$70.w           ;restore vbl
	move    (sp)+,sr                ;enable interrupts - tune will stop playing
	rts

        section bss
        ;; Put variables here
