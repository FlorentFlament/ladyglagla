;;; Basic picture display subroutines
        xref wait_hz_200

        xdef picdisplay
        xdef picerase_bottomup
        xdef picerase_topdown
        xdef picerase_leftright
        xdef picerase_rightleft
        xdef set_palette
        xdef movepic_4colors
        xdef memcopy_16k

;;; Display pictures by blocks to make them appear slowly
;;; 160 bytes per line
;;; 8 lines at a time
DISPLAY_STEP = 10*160

;;; a3 must contain address of picture
;;; a4 address of video memory
;;; d4 and d5 are the 2 longs to be used as erase colors
;;; All registers are saved then restored
picdisplay:
        ;; d6 - physical screen address
        ;; d5 - base picture address
        movem.l a3/a5/a6/d0/d3/d5/d6,-(sp)
        move.l  a3,d5
        move.l  a4,d6   ; Save physical screen ram base in d6

        move.l  d5,a3
        jsr     set_palette

        ;; Copy picture data to video memory
        ;; Data starts after palette, i.e 32bytes after start of data
        add.l   #32,d5
        move.l  d5,a5           ; a5 points to first line to draw
        move.l  d6,a6           ; a6 points to first line of video memory
        add.l   #32000-DISPLAY_STEP,a5         ; Move a block of DISPLAY_STEP data
        add.l   #32000-DISPLAY_STEP,a6         ;
.picdisplay_loop:
        move.w  #DISPLAY_STEP-4,d0       ; Move long ints (4 bytes)
.picdisplay_line_loop:                   ; Move a DISPLAY_STEP block 4 bytes at a time
        move.l  (a5,d0.w),(a6,d0.w)
        subq.w  #4,d0
        bpl     .picdisplay_line_loop
        ;; Wait loop
        move.l  #1,d3           ; Wait 1/200th of a second
        jsr     wait_hz_200
        sub.l   #DISPLAY_STEP,a5
        sub.l   #DISPLAY_STEP,a6
        cmp.l   d5,a5
        bge     .picdisplay_loop

        movem.l (sp)+,a3/a5/a6/d0/d3/d5/d6
        rts

;;; Erases the screen
;;; a4 address of video memory
;;; d4 and d5 are the 2 longs to be used as erase colors
picerase_bottomup:
        movem.l a6/d0/d3,-(sp)
        move.l  a4,a6                   ;
        add.l   #32000-DISPLAY_STEP,a6  ; a6 point to 1st line to draw
.loop:
        move.w  #DISPLAY_STEP-8,d0
.line_loop:
        move.l  d4,(a6,d0.w)
        move.l  d5,4(a6,d0.w)
        subq.w  #8,d0
        bpl     .line_loop
        ;; Wait loop
        move.l  #1,d3
        jsr     wait_hz_200
        sub.l   #DISPLAY_STEP,a6
        cmp.l   a4,a6
        bge     .loop

        movem.l (sp)+,a6/d0/d3
        rts

;;; Erases the screen from top to bottom
;;; a4 address of video memory
;;; d4 and d5 are the 2 longs to be used as erase colors
picerase_topdown:
        movem.l a4/a6/d0/d3,-(sp)
        move.l  a4,a6
        add.w   #32000,a4       ; Must stop there
.loop:
        move.w  #0,d0
.line_loop:
        move.l  d4,(a6,d0.w)
        move.l  d5,4(a6,d0.w)
        addq.w  #8,d0
        cmpi.w  #DISPLAY_STEP,d0
        bmi     .line_loop
        ;; Wait loop
        move.l  #1,d3
        jsr     wait_hz_200
        add.w   #DISPLAY_STEP,a6
        cmp.l   a4,a6
        blt     .loop

        movem.l (sp)+,a4/a6/d0/d3
        rts

;;; Erases the screen from left to right
;;; a4 address of video memory
;;; d4 and d5 are the 2 longs to be used as erase colors
picerase_leftright:
        movem.l a4/a6/d0/d3,-(sp)
        move.l  a4,a6
        add.w   #160,a4       ; Must stop there
.loop:
        move.w  #0,d0
.line_loop:
        move.l  d4,(a6,d0.w)
        move.l  d5,4(a6,d0.w)
        add.w   #160,d0         ; next line
        cmpi.w  #32000,d0
        blt     .line_loop
        ;; Wait loop
        move.l  #1,d3
        jsr     wait_hz_200
        add.w   #8,a6           ; next column
        cmp.l   a4,a6         ; end of line
        blt     .loop

        movem.l (sp)+,a4/a6/d0/d3
        rts

;;; Erases the screen from right to left
;;; a4 address of video memory
;;; d4 and d5 are the 2 longs to be used as erase colors
picerase_rightleft:
        movem.l a4/a6/d0/d3,-(sp)
        move.l  a4,a6
        add.w   #160-8,a6       ; Start there
.loop:
        move.w  #32000-160,d0
.line_loop:
        move.l  d4,(a6,d0.w)
        move.l  d5,4(a6,d0.w)
        sub.w   #160,d0         ; next line
        bpl     .line_loop
        ;; Wait loop
        move.l  #1,d3
        jsr     wait_hz_200
        sub.w   #8,a6           ; previous column
        cmp.l   a4,a6         ; end of line
        bge     .loop

        movem.l (sp)+,a4/a6/d0/d3
        rts

;;; a3 address of picture (prefixed by palette)
;;; a4 address of video ram
picdisplay2:
        move.l  a3,-(sp)
        jsr set_palette
        add.l   #32,a3          ; picture data is 32 bytes after the palette
        jsr movepic_16colors
        move.l  (sp)+,a3
        rts

;;; Set picture palette
;;; a3 address of palette to set
;;; Registers are saved then restored
set_palette:
        movem.l d0-d2/a0-a2,-(sp) ; Save registers possibly scratched by trap
	move.l	a3,-(sp)
	move.w	#6,-(sp)	; setpalette
	trap	#14		; XBIOS trap
	addq.l	#6,sp
        movem.l (sp)+,d0-d2/a0-a2 ; Restore registers
        rts

;;; arguments
;;; a3 address of picture
;;; a4 address of where picture needs to be writen
;;; All registers are saved then restored
movepic_16colors:
        ;; d6 - physical screen address
        ;; d5 - base picture address
        movem.l d3-d4,-(sp)
        ;; Copy picture data to video memory
        move.w  #32000-4,d3       ; Move long ints (4 bytes)
.move_loop:                   ; Move a DISPLAY_STEP block 4 bytes at a time
        move.l  (a3,d3.w),(a4,d3.w)
        subq.w  #4,d3
        bpl     .move_loop
        movem.l (sp)+,d3-d4
        rts

;;; Copy a 4 colors picture from one memory area to a video memory location
;;; arguments
;;; a3 address of picture
;;; a4 address of where picture needs to be writen
;;; All registers are saved then restored
movepic_4colors:
        movem.l d3-d4,-(sp)     ; backup registers d3 and d4 used as indexes
        ;; Copy picture data to video memory
        move.l  #16000-4,d3     ; Move every long (4 bytes shift) from picture
        move.l  #32000-8,d4     ; Move 1 long out of 2 in (8 bytes shift) on video ram
.move_loop:
        move.l  (a3,d3.w),(a4,d4.w)
        subq.w  #4,d3
        subq.w  #8,d4
        bpl     .move_loop
        movem.l (sp)+,d3-d4     ; restore registers d3 and d4 used as indexes
        rts

;;; Copy a 16k memory block from one memory area to another.
;;; arguments:
;;; a3 address of picture
;;; a4 address of where picture needs to be writen
;;; All registers are saved then restored
memcopy_16k:
        move.l  d3,-(sp)        ; backup registers d3 and d4 used as indexes
        ;; Copy picture data to video memory
        move.l  #16000-4,d3     ; Move every long (4 bytes shift) from picture
.move_loop:
        move.l  (a3,d3.w),(a4,d3.w)
        subq.w  #4,d3
        bpl     .move_loop
        move.l  (sp)+,d3        ; restore registers d3 and d4 used as indexes
        rts
        
