        xdef wait_hz_200

;;; Wait loop: argument is 200th of second passed in d3
;;; register are saved and restored
wait_hz_200:
        movem.l d0-d3/a0-a2,-(sp) ; Save registers

	pea     get_hz_200
	move.w  #38,-(sp)    ; Supexec function call
	trap    #14          ; Call XBIOS
	addq.l  #6,sp        ; Correct stack
        ;; d0 has the value of hz_200 timer
        add.l   d0,d3        ; Compute end time in d3

.wait_loop:
	pea     get_hz_200
	move.w  #38,-(sp)    ; Supexec function call
	trap    #14          ; Call XBIOS
	addq.l  #6,sp        ; Correct stack
        cmp.l   d0,d3        ; Check whether we've reached end time
        bge     .wait_loop   ; Loop until d0 >= d3, delay has elapsed

        movem.l (sp)+,d0-d3/a0-a2 ; Restore registers
        rts

;;; To be called by Supexec
;;; returns the content of the 200 Hz timer in d0. It's 32 bits long
;;; https://freemint.github.io/tos.hyp/en/bios_sysvars.html
get_hz_200:
        ;; TOS maintains a system variable at $0004ba traditionally
        ;; named hz_200. This is a counter that is incremented 200
        ;; times per second, controlled by Timer C on the timer chip
        ;; source: https://bumbershootsoft.wordpress.com/2021/05/29/timing-on-the-atari-st/
        move.l  $0004ba,d0
        rts
