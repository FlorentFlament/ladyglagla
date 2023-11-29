;;; Basic picture display subroutines
        xref wait_hz_200
        xref transition

        xdef picdisplay2
        xdef picerase_bottomup
        xdef picerase_topdown
        xdef picerase_leftright
        xdef picerase_rightleft
        xdef set_palette
        xdef set_palette_col
        xdef movepic_4colors
        xdef memcopy_16k
        xdef clear_screen
        xdef switch_screen_buffers

        xdef set_palette_col_sup

;;; Address of palette is: 0xffff8240 - 16 words
;;; https://freemint.github.io/tos.hyp/en/bios_sysvars.html
PALETTE_ADDRESS = $ffff8240
PALETTE_15_ADDRESS = PALETTE_ADDRESS+(2*15)

;;; Display pictures by blocks to make them appear slowly
;;; 160 bytes per line
;;; 8 lines at a time
DISPLAY_STEP = 10*160

;;; Erases the screen
;;; d4 and d5 are the 2 longs to be used as erase colors
picerase_bottomup:
        movem.l a6/d0/d3,-(sp)
        move.l  current_screen,a6                   ;
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
        cmp.l   current_screen,a6
        bge     .loop

        movem.l (sp)+,a6/d0/d3
        rts

;;; Erases the screen from top to bottom
;;; d4 and d5 are the 2 longs to be used as erase colors
picerase_topdown:
        movem.l a4/a6/d0/d3,-(sp)
        move.l  current_screen,a6
        move.l  current_screen,a4
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
;;; d4 and d5 are the 2 longs to be used as erase colors
picerase_leftright:
        movem.l a4/a6/d0/d3,-(sp)
        move.l  current_screen,a6
        move.l  current_screen,a4
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
;;; d4 and d5 are the 2 longs to be used as erase colors
picerase_rightleft:
        movem.l a4/a6/d0/d3,-(sp)
        move.l  current_screen,a6
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
        cmp.l   current_screen,a6         ; end of line
        bge     .loop

        movem.l (sp)+,a4/a6/d0/d3
        rts

;;; a3 address of picture (prefixed by palette)
picdisplay2:
        move.l  a3,-(sp)

        move.l  shadow_screen,a4 ; write the picture in the shadow buffer
        add.l   #32,a3          ; picture data is 32 bytes after the palette
        jsr     movepic_16colors

        move.l  (sp)+,a3
        jsr     transition
        rts

;;; Set picture palette
;;; a3 address of palette to set
;;; Registers are saved then restored
set_palette:
        movem.l d0-d2/a0-a2,-(sp) ; Save registers possibly scratched by trap
        move.l  a3,-(sp)
        move.w  #6,-(sp)        ; setpalette
        trap    #14             ; XBIOS trap
        addq.l  #6,sp
        movem.l (sp)+,d0-d2/a0-a2 ; Restore registers
        rts

;;; set_palette_lastcol code executed in supervisor mode
;;; d4.w - palette index
;;; d5.w - color
set_palette_col_sup:
        movem.l d4/a0,-(sp)
        lea.l   PALETTE_ADDRESS,a0
        move.w  d5,(a0,d4)
        movem.l (sp)+,d4/a0
        rts

;;; Sets the last color of the palette
;;; d4.w - palette index
;;; d5.w - color
set_palette_col:
        movem.l a0-a2/d1-d2,-(sp)
        pea     set_palette_col_sup
        move.w  #38,-(sp)    ; Supexec function call
        trap    #14          ; Call XBIOS
        addq.l  #6,sp        ; Correct stack
        movem.l (sp)+,a0-a2/d1-d2
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

;;; arguments:
;;; a4 - screen memory to be cleared
clear_screen:
        move.l  d4,-(sp)
        move.l  #32000-4,d4
.move_loop:
        move.l  #$00000000,(a4,d4.w)
        subq.w  #4,d4
        bpl     .move_loop
        move.l  (sp)+,d4
        rts

;;; a4 new screen address (to be set)
set_screen_sup:
        ; doc: https://freemint.github.io/tos.hyp/en/bios_sysvars.html
        move.l  a4,$45e         ; screenpt
        rts

;;; Switches current_screen and shadow_screen pointers
;;; Set Screen Physical Address to new current_screen
;;; Set new current_screen in a4 (for old routines still using this)
switch_screen_buffers:
        movem.l d0-d2/a0-a2,-(sp)

        ;; Switch current_screen with shadow_screen
        ;; At the end the new current_screen is also in a4
        move.l  shadow_screen,a4
        move.l  current_screen,shadow_screen
        move.l  a4,current_screen

        pea     set_screen_sup
        move.w  #38,-(sp)    ; Supexec function call
        trap    #14          ; Call XBIOS
        addq.l  #6,sp        ; Correct stack

        movem.l (sp)+,d0-d2/a0-a2
        rts
