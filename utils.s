        xdef get_hz_200
        xdef wait_hz_200
        xdef wait_next_pattern

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
	pea     get_hz_200_sup
	move.w  #38,-(sp)    ; Supexec function call
	trap    #14          ; Call XBIOS
	addq.l  #6,sp        ; Correct stack
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
        ;; Wait for even beat
        move.w  beat_cnt,d0
        and.w   #$01,d0
        beq     .loop
        ;; Wait for next beat
        move.w  tempo_cnt,d0
        bne     .loop
        move.w  (sp)+,d0
        rts
