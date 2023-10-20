        xref PLY_AKYst_Start
        xref music_data
        xref picscratch_fx
        xref picdisplay
        xref picdisplay_stretched
        xref picgum_fx
        xref picerase
        xref picture_callisto_glafouk
        xref picture_logo
        xref textwriter
        xref wait_hz_200

        xref set_palette
        xref movepic_4colors

	xdef VraiREglagla01_palette
        xdef VraiREglagla01_0001_data
        xdef VraiREglagla01_0002_data
        xdef VraiREglagla01_0003_data
        xdef VraiREglagla01_0004_data

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
        jsr     picerase
        move.l  #200,d3         ; wait
        jsr     wait_hz_200

        ;; testing new function
        ;; Get address of video memory
	move.w	#2,-(sp)	; Physbase function call
	trap	#14		; Call XBIOS
	addq.l	#2,sp
	move.l	d0,a4		; Save physical screen ram base in a4

        lea     VraiREglagla01_palette,a3
        jsr     set_palette

        move.l  #25,d3          ; wait 1/8th second (/ 200 8)
        move.b  #5,d4           ; Repeating animation 5 times
.VraiREglagla01:
        lea     VraiREglagla01_0001_data,a3
        jsr     movepic_4colors
        jsr     wait_hz_200
        lea     VraiREglagla01_0002_data,a3
        jsr     movepic_4colors
        jsr     wait_hz_200
        lea     VraiREglagla01_0003_data,a3
        jsr     movepic_4colors
        jsr     wait_hz_200
        lea     VraiREglagla01_0004_data,a3
        jsr     movepic_4colors
        jsr     wait_hz_200
        subq.b  #1,d4
        bpl     .VraiREglagla01

        move.l  #200,d3         ; wait
        jsr     wait_hz_200

        jsr     picerase
        move.l  #200,d3         ; wait
        jsr     wait_hz_200
        lea     picture_callisto_glafouk,a0
        jsr     picdisplay
        move.l  #200,d3         ; wait
        jsr     wait_hz_200
        lea     text_glafouk_1,a0
        jsr     textwriter
        move.l  #200,d3         ; wait
        jsr     wait_hz_200
        lea     text_glafouk_2,a0
        jsr     textwriter
        move.l  #600,d3         ; wait
        jsr     wait_hz_200
        jsr     picscratch_fx
        jsr     picerase
        move.l  #200,d3         ; wait
        jsr     wait_hz_200
        lea     picture_logo,a0
        jsr     picdisplay
        move.l  #600,d3         ; wait
        jsr     wait_hz_200
        lea     picture_logo,a5
        jsr     picgum_fx
        move.l  #200,d3         ; wait
        jsr     wait_hz_200
        jsr     picscratch_fx
        lea     text_credits,a0
        jsr     textwriter
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
text_glafouk_1:
        ;; Beware ! Need to add ' ' to the color to make it work !
        ;; Otherwise, behaviour is TOS dependant !
        dc.b    $1b,'c',' '+0   ; set background color to black
        dc.b    $1b,'b',' '+1       ; set foreground color to red
        dc.b    $1b,'Y',' '+5,' '+14,"Hey, hey !"
        dc.b    $1b,'Y',' '+6,' '+14,"Have you seen my t-shirt ?"
        dc.b    0
text_glafouk_2:
        dc.b	$1b,'Y',' '+7,' '+14,"No ?"
        dc.b	$1b,'Y',' '+8,' '+14,"But it's coz it's"
        dc.b	$1b,'Y',' '+9,' '+14,"under my sweatshirt..."
        dc.b	$1b,'Y',' '+10,' '+14,"To see it, I'll have"
        dc.b	$1b,'Y',' '+11,' '+14,"to undress a bit..."
        dc.b	$1b,'Y',' '+12,' '+14,"Wanna play strip p0ke(r)"
        dc.b	$1b,'Y',' '+13,' '+14,"and see my..."
        dc.b	$1b,'Y',' '+14,' '+14,"poke her face ?"
        dc.b    0


text_credits:
        ;; colors are based on Flush logo palette
        dc.b    $1b,'c',' '+1       ; set background color to black
        dc.b    $1b,'b',' '+12       ; set foreground color to red
        dc.b    $1b,'Y',' '+10,' '+6,"Graphics: Yogib33r / Callisto"
        dc.b    $1b,'b',' '+5       ; set color to yellow
        dc.b    $1b,'Y',' '+12,' '+13,"Music: Glafouk"
        dc.b    $1b,'b',' '+9            ; set foreground color to green
        dc.b    $1b,'Y',' '+14,' '+14,"Code: Flewww"
        dc.b    0

        section bss
        ;; Put variables here
