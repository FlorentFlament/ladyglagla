	xdef tempo_cnt
	xdef beat_cnt
        xdef main

        xref PLY_AKYst_Start
        xref music_data
        xref picscratch_fx
        xref set_palette
        xref picdisplay
        xref picdisplay2
        xref picgum_fx
        xref picerase
        xref picture_callisto_glafouk
        xref picture_logo
        xref textwriter
        xref wait_hz_200
        xref wait_next_pattern

        xref animation
        xref VraiREglagla01_data
        xref VraiREglagla01_sequence
        xref VRAI_REglagla02_data
        xref VRAI_REglagla02_sequence
        xref VRAIglagla33_data
        xref VRAIglagla33_sequence
        xref VRAI_REglagla04_data
        xref VRAI_REglagla04_sequence

MUSIC_TEMPO=40                  ; 75 bpm

	section code
main:
        ;; Initialize palette with first picture's
        lea     picture_callisto_glafouk,a3
        jsr     set_palette

        ;; Hide mouse with a line A function
        dc.w    $A00A

        ;; Initialize demo
        move.w  #MUSIC_TEMPO-1,tempo_cnt
        move.w  #0,beat_cnt

        ;; Initialize music player
	lea     music_data,a0
	jsr     PLY_AKYst_Start+0           ;init player and tune

        ;; Setup music player in VBL
	pea       set_music_player_vbl
	move.w    #38,-(sp)    ; Supexec function call
	trap      #14          ; Call XBIOS
	addq.l    #6,sp        ; Correct stack

        ;; Animation block
        ;; Get address of video memory
	move.w	#2,-(sp)	; Physbase function call
	trap	#14		; Call XBIOS
	addq.l	#2,sp
	move.l	d0,a4		; Save physical screen ram base in a4

.main_loop:
        ;; Ladyglagla introduction
        jsr     picerase
        jsr     wait_next_pattern
        lea     picture_callisto_glafouk,a3
        jsr     picdisplay
        lea     text_glafouk_1,a0
        jsr     textwriter
        move.l  #100,d3         ; wait
        jsr     wait_hz_200
        lea     text_glafouk_2,a0
        jsr     textwriter
        move.l  #200,d3         ; wait
        jsr     wait_hz_200

        jsr     wait_next_pattern
        jsr     picerase
        jsr     wait_next_pattern
        move.l  #text_glagla_1,d3
        lea.l   VraiREglagla01_data,a5
        lea.l   VraiREglagla01_sequence,a6
        jsr     animation

        jsr     wait_next_pattern
        jsr     picerase
        jsr     wait_next_pattern
        move.l  #text_glagla_2,d3
        lea.l   VRAI_REglagla02_data,a5
        lea.l   VRAI_REglagla02_sequence,a6
        jsr     animation

        jsr     wait_next_pattern
        jsr     picerase
        jsr     wait_next_pattern
        move.l  #text_glagla_3,d3
        lea.l   VRAIglagla33_data,a5
        lea.l   VRAIglagla33_sequence,a6
        jsr     animation

        jsr     wait_next_pattern
        jsr     picerase
        jsr     wait_next_pattern
        move.l  #text_glagla_4,d3
        lea.l   VRAI_REglagla04_data,a5
        lea.l   VRAI_REglagla04_sequence,a6
        jsr     animation

        ;; Flush
        jsr     wait_next_pattern
        jsr     picerase
        jsr     wait_next_pattern
        lea     picture_logo,a3
        jsr     picdisplay
        move.l  #500,d3         ; wait
        jsr     wait_hz_200
        jsr     wait_next_pattern
        jsr     picscratch_fx
        jsr     wait_next_pattern
        lea     text_credits,a0
        jsr     textwriter
        move.l  #500,d3         ; wait
        jsr     wait_hz_200
        jsr     wait_next_pattern
        jsr     picscratch_fx
        move.l  #100,d3         ; wait
        jsr     wait_hz_200

        jsr     wait_next_pattern
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
        ;; END

demo_vbl_stuff:
        subq.w  #1,tempo_cnt
        bpl     .endsub
        move.w  #MUSIC_TEMPO-1,tempo_cnt
        addq.w  #1,beat_cnt
.endsub
        rts

set_music_player_vbl:
	move    sr,-(sp)
	move    #$2700,sr       ; Disable interrupts (assumption to check)
	move.l  $70.w,old_vbl   ; Save VBL
	move.l  #vbl,$70.w      ; Set new VBL with player
	move    (sp)+,sr        ; Enable interrupts
        rts

vbl:
	movem.l d0-a6,-(sp)
        jsr     demo_vbl_stuff
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

text_glagla_1:
        dc.b    $1b,'c',' '+0   ; set text background color to background
        dc.b    $1b,'b',' '+4   ; set text color to index 4
        dc.b    $1b,'Y',' '+24,' '+0,"Hey, d'ya hear that fluffy mo5 platini ?",0
text_glagla_2:
        dc.b    $1b,'Y',' '+24,' '+0,"Wouhou, let's run Hell as Lady Glagla !",0
text_glagla_3:
        dc.b    $1b,'Y',' '+24,' '+0,"Hey hey, time for a li'le disco drink ?",0
text_glagla_4:
        dc.b    $1b,'Y',' '+24,' '+0,"Let's make some noise on that keyboard !",0

text_credits:
        ;; colors are based on Flush logo palette
        dc.b    $1b,'c',' '+1       ; set background color to black
        dc.b    $1b,'b',' '+12      ; set foreground color to red
        dc.b    $1b,'Y',' '+10,' '+6,"Graphics: Yogib33r / Callisto"
        dc.b    $1b,'b',' '+5       ; set color to yellow
        dc.b    $1b,'Y',' '+12,' '+13,"Music: Glafouk"
        dc.b    $1b,'b',' '+9       ; set foreground color to green
        dc.b    $1b,'Y',' '+14,' '+14,"Code: Flewww"
        dc.b    0

        section bss
tempo_cnt:      dcb.w 1
beat_cnt:       dcb.w 1
