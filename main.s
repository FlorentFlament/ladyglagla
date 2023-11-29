        xdef tempo_cnt
        xdef beat_cnt
        xdef main
        xdef shadow_screen
        xdef current_screen

        ;; pictures data
        xref picture_callisto_glafouk
        xref picture_logo
        xref callisto_ladyglaglav9
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

        xref set_palette_col
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

MUSIC_TEMPO = 40                  ; 75 bpm
COLOR1 = $0577
COLOR2 = $0065
COLOR3 = $0656
COLOR4 = $0764

        section code
main:
        movem.l d0-d7/a0-a6,-(sp)
        move.l  sp,stackpointer_backup

        sub.l   #32000,sp       ; allocate some room for screen buffer
        move.l  sp,d0
        and.l  #$ffffff00,d0
        move.l  d0,sp   ; align sp to 256 bytes
        move.l  sp,shadow_screen ; save screenbuffer pointer
        ;; From here stack can be used as usual

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
        move.l  d0,current_screen           ; Save physical screen ram base in current_screen
        move.l  current_screen,a4           ; and a4 - used by some old routines

        ;; Initialize beat reference (used to synchronize parts)
        move.w  #0,d7

        ;; picerase_updown pattern

        move.w  #0,d4
        move.w  #COLOR4,d5
        jsr     set_palette_col
        move.l  #$00000000,d4   ; 5
        move.l  #$00000000,d5
        jsr     picerase_bottomup
        jsr     wait_next_pattern
        lea     text_intro_palette,a3
        jsr     set_palette
        lea     text_intro,a3
        move.w  #4,d3
        jsr     textwriter
        add.w   #8,d7           ; 8 beats for previous part
        jsr     spinlock_beat_count
        lea.l   glagla07,a3
        jsr     picdisplay2
        add.w   #8,d7
        jsr     spinlock_beat_count

        move.w  #30,d4
        move.w  #COLOR1,d5
        jsr     set_palette_col
        move.l  #$ffffffff,d4   ; 5
        move.l  #$ffffffff,d5
        jsr     picerase_bottomup
        jsr     wait_next_pattern
        lea.l   picture_callisto_glafouk,a3
        jsr     picdisplay2
        lea     text_glafouk_1,a3
        move.w  #9,d3
        jsr     textwriter
        add.w   #32,d7
        jsr     spinlock_beat_count

        move.l  #2390,d6        ; duration of animation - (- (* 15 160) 10)
                                ; 15 beats at 160 ticks per beat minus 10 margin
                                ; Passed to the `animation` routine

        move.w  #30,d4
        move.w  #COLOR2,d5
        jsr     set_palette_col
        move.l  #$ffffffff,d4   ; 5
        move.l  #$ffffffff,d5
        jsr     picerase_leftright
        lea.l   VraiREglagla01_data,a5
        lea.l   animation_data,a6
        jsr     uncompress_animation
        jsr     wait_next_pattern
        move.l  #text_glagla_1,d3
        lea.l   animation_data,a5
        lea.l   VraiREglagla01_sequence,a6
        add.w   #16,d7
        jsr     animation

        move.w  #30,d4
        move.w  #COLOR3,d5
        jsr     set_palette_col
        move.l  #$ffffffff,d4   ; 5
        move.l  #$ffffffff,d5
        jsr     picerase_topdown
        lea.l   VRAI_REglagla02_data,a5
        lea.l   animation_data,a6
        jsr     uncompress_animation
        jsr     wait_next_pattern
        move.l  #text_glagla_2,d3
        lea.l   animation_data,a5
        lea.l   VRAI_REglagla02_sequence,a6
        add.w   #16,d7
        jsr     animation

        move.w  #30,d4
        move.w  #COLOR4,d5
        jsr     set_palette_col
        move.l  #$ffffffff,d4   ; 5
        move.l  #$ffffffff,d5
        jsr     picerase_rightleft
        lea.l   VRAIglagla33_data,a5
        lea.l   animation_data,a6
        jsr     uncompress_animation
        jsr     wait_next_pattern
        move.l  #text_glagla_3,d3
        lea.l   animation_data,a5
        lea.l   VRAIglagla33_sequence,a6
        add.w   #16,d7
        jsr     animation

        move.w  #30,d4
        move.w  #COLOR1,d5
        jsr     set_palette_col
        move.l  #$ffffffff,d4   ; 5
        move.l  #$ffffffff,d5
        jsr     picerase_bottomup
        lea.l   VRAI_REglagla04_data,a5
        lea.l   animation_data,a6
        jsr     uncompress_animation
        jsr     wait_next_pattern
        move.l  #text_glagla_4,d3
        lea.l   animation_data,a5
        lea.l   VRAI_REglagla04_sequence,a6
        add.w   #16,d7
        jsr     animation

        move.w  #30,d4
        move.w  #COLOR3,d5
        jsr     set_palette_col
        move.l  #$ffffffff,d4   ; 5
        move.l  #$ffffffff,d5
        jsr     picerase_bottomup
        jsr     wait_next_pattern
        lea.l   callisto_ladyglaglav9,a3
        jsr     picdisplay2
        add.w   #8,d7
        jsr     spinlock_beat_count

;; Second part - with FXs

        move.w  #30,d4
        move.w  #COLOR2,d5
        jsr     set_palette_col
        move.l  #$ffffffff,d4   ; 5
        move.l  #$ffffffff,d5
        jsr     picerase_leftright
        lea.l   VraiREglagla01_data,a5
        lea.l   animation_data,a6
        jsr     uncompress_animation
        jsr     wait_next_pattern
        lea.l   animation_data,a5
        lea.l   VraiREglagla01_sequence,a6
        lea.l   fx_data_1_fx_structure,a3
        add.w   #16,d7          ; fx_wave_animation will end with proper beat
        jsr     fx_wave_animation

        move.w  #30,d4
        move.w  #COLOR3,d5
        jsr     set_palette_col
        move.l  #$ffffffff,d4   ; 5
        move.l  #$ffffffff,d5
        jsr     picerase_rightleft
        lea.l   VRAI_REglagla02_data,a5
        lea.l   animation_data,a6
        jsr     uncompress_animation
        jsr     wait_next_pattern
        lea.l   animation_data,a5
        lea.l   VRAI_REglagla02_sequence,a6
        lea.l   fx_data_2_fx_structure,a3
        add.w   #16,d7
        jsr     fx_wave_animation

        move.w  #30,d4
        move.w  #COLOR4,d5
        jsr     set_palette_col
        move.l  #$ffffffff,d4   ; 5
        move.l  #$ffffffff,d5
        jsr     picerase_topdown
        lea.l   VRAIglagla33_data,a5
        lea.l   animation_data,a6
        jsr     uncompress_animation
        jsr     wait_next_pattern
        lea.l   animation_data,a5
        lea.l   VRAIglagla33_sequence,a6
        lea.l   fx_data_3_fx_structure,a3
        add.w   #16,d7
        jsr     fx_wave_animation

        move.w  #30,d4
        move.w  #COLOR1,d5
        jsr     set_palette_col
        move.l  #$ffffffff,d4   ; 5
        move.l  #$ffffffff,d5
        jsr     picerase_bottomup
        lea.l   VRAI_REglagla04_data,a5
        lea.l   animation_data,a6
        jsr     uncompress_animation
        jsr     wait_next_pattern
        lea.l   animation_data,a5
        lea.l   VRAI_REglagla04_sequence,a6
        lea.l   fx_data_4_fx_structure,a3
        add.w   #16,d7
        jsr     fx_wave_animation

        ;; Flush
        move.w  #30,d4
        move.w  #COLOR2,d5
        jsr     set_palette_col
        move.l  #$ffffffff,d4   ; 5
        move.l  #$ffffffff,d5
        jsr     picerase_leftright
        jsr     wait_next_pattern
        lea     picture_logo,a3
        jsr     picdisplay2
        move.l  #500,d3         ; wait
        jsr     wait_hz_200
        jsr     wait_next_pattern
        move.w  #5000,d6        ; picscratch_fx parameter
        jsr     picscratch_fx
        jsr     wait_next_pattern
        lea     text_credits,a3
        move.w  #8,d3
        jsr     textwriter
        move.l  #500,d3         ; wait
        jsr     wait_hz_200
        jsr     wait_next_pattern
        jsr     picscratch_fx
        jsr     greetz
        add.w   #120,d7
        jsr     spinlock_beat_count

        move.w  #30,d4
        move.w  #COLOR3,d5
        jsr     set_palette_col
        move.l  #$ffffffff,d4   ; 5
        move.l  #$ffffffff,d5
        jsr     picerase_topdown
        jsr     wait_next_pattern
        lea.l   glagla07,a3
        jsr     picdisplay2

        .final_loop:
        bra     .final_loop

        move.w  #30,d4
        move.w  #COLOR4,d5
        jsr     set_palette_col
        move.l  #$ffffffff,d4   ; 5
        move.l  #$ffffffff,d5
        jsr     picerase_topdown

        ;; Restore previous VBL
        pea       restore_vbl
        move.w    #38,-(sp)    ; Supexec function call
        trap      #14          ; Call XBIOS
        addq.l    #6,sp        ; Correct stack

        ;; Display mouse with a line A function
        dc.w    $A009

        move.l  stackpointer_backup,sp ; restore stack pointer
        movem.l d0-d7/a0-a6,-(sp)
        clr.w   -(sp)           ; Pterm0
        trap    #1              ; GEMDOS
        ;; END

greetz:
        movem.l d0-d7/a0-a6,-(sp)
        move.w  #2000,d6        ; picscratch_fx parameter
        lea.l   text_greetz,a3
        move.w  #8,d3
        jsr     textwriter
        jsr     wait_next_pattern
        .loop:
        jsr     picscratch_fx
        jsr     wait_next_pattern
        jsr     textwriter
        jsr     wait_next_pattern
        tst.b   (a3)
        bne     .loop
        move.w  #5000,d6        ; picscratch_fx parameter
        jsr     picscratch_fx
        movem.l (sp)+,d0-d7/a0-a6
        rts

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
text_intro_palette:
        dc.w    COLOR4,$0000,$0000,$0000,$0000,$0000,$0000,$0000
        dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,COLOR4
text_intro:
        dc.b    $1b,'c',' '+0
        dc.b    $1b,'b',' '+1
        dc.b    $1b,'Y',' '+8,' '+17,"Flush"
        dc.b    $1b,'Y',' '+10,' '+16,"presents"
        dc.b    $1b,'Y',' '+12,' '+8,"our first Atari ST demo"
        dc.b    $1b,'Y',' '+14,' '+5,"running on stock Atari 520 STF"
        dc.b    $1b,'Y',' '+16,' '+2,"at Silly Venture 2023 winter edition"
        dc.b    0
text_glafouk_1:
        ;; Beware ! Need to add ' ' to the color to make it work !
        ;; Otherwise, behaviour is TOS dependant !
        dc.b    $1b,'c',' '+0   ; set background color to black
        dc.b    $1b,'b',' '+1       ; set foreground color to red
        dc.b    $1b,'Y',' '+4,' '+14,"Is Glafouk non bean..."
        dc.b    $1b,'Y',' '+5,' '+14,"Are he ?"
        dc.b    $1b,'Y',' '+6,' '+14,"He is none been Harry"
        dc.b    $1b,'Y',' '+7,' '+14,"even if he's been hairy..."
        dc.b    $1b,'Y',' '+8,' '+14,"He's globably merry but"
        dc.b    $1b,'Y',' '+9,' '+14,"he's not Mary however..."
        dc.b    $1b,'Y',' '+10,' '+14,"Sometimes he's wearing"
        dc.b    $1b,'Y',' '+11,' '+14,"skirts in Aalst,"
        dc.b    $1b,'Y',' '+12,' '+14,"but does it make him"
        dc.b    $1b,'Y',' '+13,' '+14,"a lady ? Well well well..."
        dc.b    $1b,'Y',' '+14,' '+14,"The clothes do not make"
        dc.b    $1b,'Y',' '+15,' '+14,"the woman or the man..."
        dc.b    $1b,'Y',' '+16,' '+14,"And the little bean"
        dc.b    $1b,'Y',' '+17,' '+14,"between your legs neither."
        dc.b    $1b,'Y',' '+18,' '+14,"Then... You are all a bit"
        dc.b    $1b,'Y',' '+19,' '+14,"Lady Glagla yourself..."
        dc.b    $1b,'Y',' '+20,' '+14,"Mouhahaha !"
        dc.b    0

text_glagla_1:
        dc.b    $1b,'c',' '+0   ; set text background color to background
        dc.b    $1b,'b',' '+4   ; set text color to index 4
        dc.b    $1b,'Y',' '+23,' '+0,"Scene musicians make music, "
        dc.b    $1b,'Y',' '+24,' '+0,"Lady Glagla makes bleepy noises..."
        dc.b    0
text_glagla_2:
        dc.b    $1b,'Y',' '+23,' '+0,"They sound and taste dirty like a fart,"
        dc.b    $1b,'Y',' '+24,' '+0,"but look how it's groovy baby..."
        dc.b    0
text_glagla_3:
        dc.b    $1b,'Y',' '+23,' '+0,"And they even have been played on posh"
        dc.b    $1b,'Y',' '+24,' '+0,"parties to shake the crowd's booty..."
        dc.b    0
text_glagla_4:
        dc.b    $1b,'Y',' '+23,' '+0,"If music is played then it's just a game"
        dc.b    $1b,'Y',' '+24,' '+0,"but games are for kids then... Mouhahaha"
        dc.b    0

text_credits:
        ;; colors are based on Flush logo palette
        dc.b    $1b,'c',' '+1       ; set background color to black
        dc.b    $1b,'b',' '+12       ; set foreground color to yellow
        ;; dc.b    $1b,'b',' '+5      ; set foreground color to red
        dc.b    $1b,'Y',' '+7,' '+12,"Theme: Yogib33r"
        dc.b    $1b,'Y',' '+9,' '+5,"Graphics: Yogib33r / Callisto"
        ;; dc.b    $1b,'b',' '+9       ; set foreground color to green
        dc.b    $1b,'Y',' '+11,' '+10,"Animations: Yogib33r"
        dc.b    $1b,'Y',' '+13,' '+13,"Music: Glafouk"
        dc.b    $1b,'Y',' '+15,' '+13,"Texts: Glafouk"
        dc.b    $1b,'Y',' '+17,' '+14,"Code: Flewww"
        dc.b    0

text_greetz:
        dc.b    $1b,'c',' '+1       ; set background color to black
        dc.b    $1b,'b',' '+0       ; set foreground color to white
        dc.b    $1b,'Y',' '+20,' '+17,"Grit'z",0
        dc.b    $1b,'Y',' '+4,' '+30,"Altair",0
        dc.b    $1b,'Y',' '+23,' '+11,"Bunch of Craving Kids",0
        dc.b    $1b,'Y',' '+8,' '+32,"Bomb",0
        dc.b    $1b,'Y',' '+19,' '+28,"Booze Design",0
        dc.b    $1b,'Y',' '+6,' '+26,"Cluster",0
        dc.b    $1b,'Y',' '+21,' '+25,"Cocoon",0
        dc.b    $1b,'Y',' '+2,' '+20,"Cookie Collective",0
        dc.b    $1b,'Y',' '+16,' '+27,"Dentifrice",0
        dc.b    $1b,'Y',' '+12,' '+28,"Dune",0
        dc.b    $1b,'Y',' '+5,' '+20,"Genesis Project",0
        dc.b    $1b,'Y',' '+24,' '+28,"g0blinish",0
        dc.b    $1b,'Y',' '+7,' '+25,"Hooy-Program",0
        dc.b    $1b,'Y',' '+9,' '+30,"Jac!",0
        dc.b    $1b,'Y',' '+3,' '+20,"Laboratoire Prout",0
        dc.b    $1b,'Y',' '+20,' '+26,"Mystic Bytes",0
        dc.b    $1b,'Y',' '+11,' '+29,"Noice",0
        dc.b    $1b,'Y',' '+22,' '+27,"Planet Jazz",0
        dc.b    $1b,'Y',' '+4,' '+29,"Popsy Team",0
        dc.b    $1b,'Y',' '+14,' '+13,"Royal Belgian Beer Squadron",0
        dc.b    $1b,'Y',' '+17,' '+27,"Sector One",0
        dc.b    $1b,'Y',' '+2,' '+30,"Shiru",0
        dc.b    $1b,'Y',' '+12,' '+25,"Swyng",0
        dc.b    $1b,'Y',' '+9,' '+20,"The Undead Sceners",0
        dc.b    $1b,'Y',' '+5,' '+31,"Up Rough",0
        dc.b    $1b,'Y',' '+18,' '+25,"Vital Motion",0
        dc.b    $1b,'Y',' '+3,' '+32,"X-men",0
        dc.b    0

        align   1               ; Word alignment required
animation_data:
        dc.l    0               ; to be updated at runtime
        dc.l    0
        dc.l    animation_pic2
        dc.l    animation_pic3
        dc.l    animation_pic4
        dc.l    animation_pic5

        section bss
stackpointer_backup:    dcb.l   1
shadow_screen:          dcb.l   1
current_screen:         dcb.l   1

tempo_cnt:              dcb.w   1
beat_cnt:               dcb.w   1

;;; animation buffer
animation_pic2:         dcb.b   80*200
animation_pic3:         dcb.b   80*200
animation_pic4:         dcb.b   80*200
animation_pic5:         dcb.b   80*200
