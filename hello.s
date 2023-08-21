        xref PLY_AKYst_Start
        xref music_data
        xref picscratch_fx
        xref picdisplay
        xref picture_callisto_glafouk
        xref picture_logo
        xref textwriter
        xref wait_hz_200

	section code
main:
        ;; Hide mouse with a line A function
        dc.w    $A00A

        ;; Initialize music player
	lea     music_data,a0
	jsr     PLY_AKYst_Start+0           ;init player and tune

        ;; Setup music player in VBL
	pea       set_music_player_vbl
	move.w    #38,-(sp)    ; Supexec function call
	trap      #14          ; Call XBIOS
	addq.l    #6,sp        ; Correct stack

.main_loop:
        lea     picture_callisto_glafouk,a0
        jsr     picdisplay
        move.l  #200,d3         ; wait
        jsr     wait_hz_200
        lea     text_glafouk,a0
        jsr     textwriter
        move.l  #600,d3         ; wait
        jsr     wait_hz_200
        jsr     picscratch_fx
        lea     picture_logo,a0
        jsr     picdisplay
        move.l  #600,d3         ; wait
        jsr     wait_hz_200
        jsr     picscratch_fx
        bra     .main_loop

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

set_music_player_vbl:
	move    sr,-(sp)
	move    #$2700,sr       ; Disable interrupts (assumption to check)
	move.l  $70.w,old_vbl   ; Save VBL
	move.l  #vbl,$70.w      ; Set new VBL with player
	move    (sp)+,sr        ; Enable interrupts
        rts

vbl:
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

        section text_data,data
text_glafouk:
        dc.b    $1b,'Y',' '+5,' '+14,"Hey, hey !",13,10
        dc.b    $1b,'Y',' '+6,' '+14,"Have you seen my t-shirt ?",13,10
        dc.b    0

        section bss
        ;; Put variables here
