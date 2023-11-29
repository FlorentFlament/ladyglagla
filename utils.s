        xdef get_hz_200
        xdef wait_hz_200
        xdef wait_next_pattern
        xdef spinlock_hz200_simple
        xdef spinlock_beat_count
        xdef transition

        xref beat_cnt

;;; Wait loop: argument is 200th of second passed in d3
;;; register are saved and restored
wait_hz_200:
        movem.l d0-d3/a0-a2,-(sp) ; Save registers

        jsr     get_hz_200
        add.l   d0,d3        ; Compute end time in d3
.wait_loop:
        jsr     get_hz_200
        cmp.l   d0,d3        ; Check whether we've reached end time
        bge     .wait_loop   ; Loop until d0 >= d3, delay has elapsed

        movem.l (sp)+,d0-d3/a0-a2 ; Restore registers
        rts

;;; userlan get_hz_200
;;; hz_200 is returned in d0
;;; Potentially scratches d0-d2/a0-a2
get_hz_200:
        movem.l a0-a2/d1-d2,-(sp)
        pea     get_hz_200_sup
        move.w  #38,-(sp)    ; Supexec function call
        trap    #14          ; Call XBIOS
        addq.l  #6,sp        ; Correct stack
        movem.l (sp)+,a0-a2/d1-d2
        rts

;;; To be called by Supexec
;;; returns the content of the 200 Hz timer in d0. It's 32 bits long
;;; https://freemint.github.io/tos.hyp/en/bios_sysvars.html
get_hz_200_sup:
        ;; TOS maintains a system variable at $0004ba traditionally
        ;; named hz_200. This is a counter that is incremented 200
        ;; times per second, controlled by Timer C on the timer chip
        ;; source: https://bumbershootsoft.wordpress.com/2021/05/29/timing-on-the-atari-st/
        move.l  $0004ba,d0
        rts

wait_next_pattern:
        move.w  d0,-(sp)
.loop:
        ;; Wait for next beat
        move.w  tempo_cnt,d0
        bne     .loop
        move.w  (sp)+,d0
        rts

;;; Argument
;;; d7 - the absolute beat count to wait for
spinlock_beat_count:
        .spin_loop:
        cmp.w   beat_cnt,d7
        bgt     .spin_loop
        rts

;;; d3 - Target time to wait for (absolute in 200th of seconds)
;;; Will spinlocks until time is reached
spinlock_hz200_simple:
        move.l  d0,-(sp)

        .spin_loop:
        move.l  $0004ba,d0      ; retrieve hz_200
        cmp.l   d3,d0           ; compare with d1
        blt     .spin_loop

        move.l  (sp)+,d0
        rts

;;; a3 - Adresse of new palette
transition:
        movem.l d0-d2/a0-d2,-(sp)

        ;; Wait for vsync.
        ;; ensuring that the screen switch and the set_palette are
        ;; performed during the same VBL.
        ;; Yeah I know the probability is very low, but I'm fine with
        ;; spending 1/50th second to lower this probability down to 0.
        move.w    #37,-(sp)    ; Offset 0
        trap      #14          ; Call XBIOS
        addq.l    #2,sp        ; Correct stack

        ;; The switch buffers and set palette
        jsr     switch_screen_buffers ; a4 will contain the new current_screen
        jsr     set_palette           ; a3 contains the new palette

        movem.l (sp)+,d0-d2/a0-d2
        rts
