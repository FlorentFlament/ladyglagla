        xdef tempo_cnt
        xdef beat_cnt
        xdef main
        xdef break_here

        ;; pictures data
        xref picture_callisto_glafouk
        xref picture_logo
        xref callisto_ladyglagla_320x200
        xref glagla07

        ;; animations data
        xref VraiREglagla01_data
        xref VraiREglagla01_sequence
        xref VRAI_REglagla02_data
        xref VRAI_REglagla02_sequence
        xref VRAIglagla33_data
        xref VRAIglagla33_sequence
        xref VRAI_REglagla04_data
        xref VRAI_REglagla04_sequence

        xref PLY_AKYst_Start
        xref music_data
        xref picscratch_fx

        xref picdisplay
        xref picdisplay2
        xref picerase_bottomup
        xref picerase_topdown
        xref picerase_leftright
        xref picerase_rightleft
        xref textwriter

        xref wait_hz_200
        xref wait_next_pattern
        xref spinlock_beat_count

        xref animation

        xref fx_wave_animation
        xref fx_data_1_fx_structure
        xref fx_data_2_fx_structure

MUSIC_TEMPO=40                  ; 75 bpm

        section code
main:
        movem.l d0-d7/a0-a6,-(sp)

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
        move.w  #2,-(sp)        ; Physbase function call
        trap    #14             ; Call XBIOS
        addq.l  #2,sp
        move.l  d0,a4           ; Save physical screen ram base in a4

        ;; Initialize beat reference (used to synchronize parts)
        move.w  #0,d7

        ;; picerase_updown pattern
        move.l  #$00000000,d4   ; 5
        move.l  #$00000000,d5
        jsr     picerase_bottomup
        lea     text_intro,a0
        jsr     textwriter
        add.w   #8,d7           ; 8 beats for previous part
        jsr     spinlock_beat_count

        lea.l   glagla07,a3
        jsr     picdisplay2
        add.w   #8,d7
        jsr     spinlock_beat_count

        move.l  #$00000000,d4   ; 5
        move.l  #$00000000,d5
        jsr     picerase_bottomup
        jsr     wait_next_pattern
        lea.l   picture_callisto_glafouk,a3
        jsr     picdisplay2
        lea     text_glafouk_1,a0
        jsr     textwriter
        move.l  #100,d3         ; wait
        jsr     wait_hz_200
        lea     text_glafouk_2,a0
        jsr     textwriter
        add.w   #16,d7
        jsr     spinlock_beat_count

        move.l  #2390,d6        ; duration of animation - (- (* 15 160) 10)
                                ; 15 beats at 160 ticks per beat minus 10 margin
                                ; Passed to the `animation` routine

        move.l  #$0000ffff,d4   ; 2
        move.l  #$00000000,d5
        jsr     picerase_leftright
        lea.l   VraiREglagla01_data,a5
        lea.l   animation_data,a6
        jsr     uncompress_animation
        jsr     wait_next_pattern
        move.l  #text_glagla_1,d3
        lea.l   animation_data,a5
        lea.l   VraiREglagla01_sequence,a6
        jsr     animation
        add.w   #16,d7
        jsr     spinlock_beat_count

        move.l  #$ffffffff,d4   ; 3
        move.l  #$00000000,d5
        jsr     picerase_topdown
        lea.l   VRAI_REglagla02_data,a5
        lea.l   animation_data,a6
        jsr     uncompress_animation
        jsr     wait_next_pattern
        move.l  #text_glagla_2,d3
        lea.l   animation_data,a5
        lea.l   VRAI_REglagla02_sequence,a6
        jsr     animation
        add.w   #16,d7
        jsr     spinlock_beat_count

        move.l  #$0000ffff,d4   ; 2
        move.l  #$00000000,d5
        jsr     picerase_rightleft
        lea.l   VRAIglagla33_data,a5
        lea.l   animation_data,a6
        jsr     uncompress_animation
        jsr     wait_next_pattern
        move.l  #text_glagla_3,d3
        lea.l   animation_data,a5
        lea.l   VRAIglagla33_sequence,a6
        jsr     animation
        add.w   #16,d7
        jsr     spinlock_beat_count

        move.l  #$ffff0000,d4   ; 1
        move.l  #$00000000,d5
        jsr     picerase_bottomup
        lea.l   VRAI_REglagla04_data,a5
        lea.l   animation_data,a6
        jsr     uncompress_animation
        jsr     wait_next_pattern
        move.l  #text_glagla_4,d3
        lea.l   animation_data,a5
        lea.l   VRAI_REglagla04_sequence,a6
        jsr     animation
        add.w   #16,d7
        jsr     spinlock_beat_count

        move.l  #$ffff0000,d4   ; 1
        move.l  #$00000000,d5
        jsr     picerase_bottomup
        jsr     wait_next_pattern
        lea.l   callisto_ladyglagla_320x200,a3
        jsr     picdisplay2
        add.w   #8,d7
        jsr     spinlock_beat_count

;; Second part - with FXs

        move.l  #$0000ffff,d4   ; 2
        move.l  #$00000000,d4   ; 4
        jsr     picerase_leftright
        lea.l   VraiREglagla01_data,a5
        lea.l   animation_data,a6
        jsr     uncompress_animation
        jsr     wait_next_pattern
        move.l  #790,d6        ; duration of animation - (* 5 160)
        move.l  #no_text,d3
        lea.l   animation_data,a5
        lea.l   VraiREglagla01_sequence,a6
        lea.l   fx_data_1_fx_structure,a3
        add.w   #16,d7          ; fx_wave_animation will end with proper beat
        jsr     fx_wave_animation

        move.l  #$ffffffff,d4   ; 3
        move.l  #$00000000,d5
        jsr     picerase_rightleft
        lea.l   VRAI_REglagla02_data,a5
        lea.l   animation_data,a6
        jsr     uncompress_animation
        jsr     wait_next_pattern
        move.l  #no_text,d3
        lea.l   animation_data,a5
        lea.l   VRAI_REglagla02_sequence,a6
        lea.l   fx_data_2_fx_structure,a3
        add.w   #16,d7
        jsr     fx_wave_animation

        move.l  #$ffff0000,d4   ; 1
        move.l  #$00000000,d5
        jsr     picerase_topdown
        lea.l   VRAIglagla33_data,a5
        lea.l   animation_data,a6
        jsr     uncompress_animation
        jsr     wait_next_pattern
        move.l  #no_text,d3
        lea.l   animation_data,a5
        lea.l   VRAIglagla33_sequence,a6
        lea.l   fx_data_3_fx_structure,a3
        add.w   #16,d7
        jsr     fx_wave_animation

        move.l  #$0000ffff,d4   ; 2
        move.l  #$00000000,d5
        jsr     picerase_bottomup
        lea.l   VRAI_REglagla04_data,a5
        lea.l   animation_data,a6
        jsr     uncompress_animation
        jsr     wait_next_pattern
        move.l  #no_text,d3
        lea.l   animation_data,a5
        lea.l   VRAI_REglagla04_sequence,a6
        lea.l   fx_data_4_fx_structure,a3
        add.w   #16,d7
        jsr     fx_wave_animation

        ;; Flush
        move.l  #$ffffffff,d4   ; 3
        move.l  #$00000000,d5
        jsr     picerase_leftright
        jsr     wait_next_pattern
        lea     picture_logo,a3
        jsr     picdisplay2
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
        add.w   #24,d7           ; 8 beats for previous part
        jsr     spinlock_beat_count

        move.l  #$0000ffff,d4   ; 2
        move.l  #$00000000,d5
        jsr     picerase_topdown
        jsr     wait_next_pattern
        lea.l   glagla07,a3
        jsr     picdisplay2
        add.w   #16,d7
        jsr     spinlock_beat_count

        move.l  #$0000ffff,d4   ; 2
        move.l  #$00000000,d5
        jsr     picerase_topdown

        ;; Restore previous VBL
        pea       restore_vbl
        move.w    #38,-(sp)    ; Supexec function call
        trap      #14          ; Call XBIOS
        addq.l    #6,sp        ; Correct stack

        ;; Display mouse with a line A function
        dc.w    $A009

        movem.l d0-d7/a0-a6,-(sp)
        move.w  0,d0            ; Crash
        ;; clr.w   -(sp)           ; Pterm0
        ;; trap    #1              ; GEMDOS
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
text_intro:
        dc.b    $1b,'c',' '+0   ; set background color to black
        dc.b    $1b,'b',' '+15      ; set foreground color to red
        dc.b    $1b,'Y',' '+9,' '+17,"Flush"
        dc.b    $1b,'Y',' '+11,' '+16,"presents"
        dc.b    $1b,'Y',' '+13,' '+12,"an Atari ST demo"
        dc.b    $1b,'Y',' '+15,' '+1,"at Silly Venture 2023 winter edition"
        dc.b    0
text_glafouk_1:
        ;; Beware ! Need to add ' ' to the color to make it work !
        ;; Otherwise, behaviour is TOS dependant !
        dc.b    $1b,'c',' '+0   ; set background color to black
        dc.b    $1b,'b',' '+1       ; set foreground color to red
        dc.b    $1b,'Y',' '+5,' '+14,"Hey, hey !"
        dc.b    $1b,'Y',' '+6,' '+14,"Have you seen my t-shirt ?"
        dc.b    0
text_glafouk_2:
        dc.b    $1b,'Y',' '+7,' '+14,"No ?"
        dc.b    $1b,'Y',' '+8,' '+14,"But it's coz it's"
        dc.b    $1b,'Y',' '+9,' '+14,"under my sweatshirt..."
        dc.b    $1b,'Y',' '+10,' '+14,"To see it, I'll have"
        dc.b    $1b,'Y',' '+11,' '+14,"to undress a bit..."
        dc.b    $1b,'Y',' '+12,' '+14,"Wanna play strip p0ke(r)"
        dc.b    $1b,'Y',' '+13,' '+14,"and see my..."
        dc.b    $1b,'Y',' '+14,' '+14,"poke her face ?"
no_text:
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

        align 2
animation_data:
        dc.l    0               ; to be updated at runtime
        dc.l    0
        dc.l    animation_pic2
        dc.l    animation_pic3
        dc.l    animation_pic4
        dc.l    animation_pic5

        section bss
tempo_cnt:              dcb.w   1
beat_cnt:               dcb.w   1

;;; animation buffer
animation_pic2:         dcb.b   80*200
animation_pic3:         dcb.b   80*200
animation_pic4:         dcb.b   80*200
animation_pic5:         dcb.b   80*200
