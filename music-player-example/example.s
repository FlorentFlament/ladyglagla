;
; Very tiny shell for calling the Arkos 2 ST player
; Cobbled by GGN in 20 April 2018
; Uses rmac for assembling (probably not a big problem converting to devpac/vasm format)
;

    move.l #start,-(sp)         ; run start in monitor mode
    move.w #$26,-(sp)
    trap #14
    addq.l #6,sp    

    clr.w -(sp)                     ;terminate
    trap #1

start:

    lea tune,a0
    bsr PLY_AKYst_Start+0           ;init player and tune

    move sr,-(sp)
    move #$2700,sr
    move.l  $70.w,old_vbl           ;so how do you turn the player on?
    move.l  #vbl,$70.w              ;(makes gesture of turning an engine key on) *trrrrrrrrrrrrrr*
    move (sp)+,sr                   ;enable interrupts - tune will start playing
    
.waitspace:

    cmp.b #57,$fffffc02.w           ;wait for space keypress
    bne.s .waitspace

    move sr,-(sp)
    move #$2700,sr

    move.l  old_vbl,$70.w           ;restore vbl

    move (sp)+,sr                   ;enable interrupts - tune will stop playing
    rts                             ;bye!

vbl:
    movem.l d0-a6,-(sp)
    lea tune,a0                     ;tell the player where to find the tune start
    bsr.s PLY_AKYst_Start+2         ;play that funky music
    movem.l (sp)+,d0-a6    
old_vbl=*+2
    jmp 'GGN!'

    include "PlayerAky.s"

    data

tune:
    include "pachelbel-fixed.s"
    even
tune_end:

    bss
