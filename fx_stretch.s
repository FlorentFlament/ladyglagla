;;; Picture stretching effect
        xdef fx_picstretch_animation
        xdef fx_wave_animation
        xdef wait_next_vbl
        xdef get_current_image_address

        xref get_hz_200
        xref set_palette

;;; d6 contains last hz_200 value we waited for
;;; wait for 4 hz_200
;;; Ensures we don't update the picture twice in the same VBL
;;; https://freemint.github.io/tos.hyp/en/bios_sysvars.html
wait_next_vbl:
        movem.l d0-d2/a0-a2,-(sp)
        ;; TODO: Change picture to animate the thing

        ;; Ensure we're not goind too fast
        addq.l  #4,d6           ; Next hz_200 to wait for
        jsr     get_hz_200
        cmp.l   d6,d0
        bge     .after_wait
        move.w  #37,-(sp)    ; Vsync XBIOS function. Wait for next vertical sync
        trap    #14          ; Call XBIOS
        addq.l  #2,sp        ; Correct stack
        jsr     get_hz_200
.after_wait:
        move.l  d0,d6           ; Update current hz_200
        movem.l (sp)+,d0-d2/a0-a2
        rts

;;; a6 contains the address of the following animation structure:
;;;  0(a6) - long - address of images sequence table
;;;  4(a6) - long - address of images pointers
;;;  8(a6) - long - time of next animation image
;;; 12(a6) - word - index of current image in sequence table
;;;
;;; a1 - returns the current image address in a1
;;; Index in sequence table and time of next animation are updated
get_current_image_address:
        movem.l a0/d0-d3,-(sp)
        move.l  0(a6),a0        ; sequence table address
        move.l  4(a6),a1        ; images pointers table addess
        move.l  8(a6),d2        ; time of next animation image
        move.w  12(a6),d3       ; index in sequence table

        ;; Is it time for new animation image ?
        jsr     get_hz_200      ; into d0
        cmp.l   d2,d0
        blt     .image_uptodate
        ;; time of next image has been reached
        add.w   #25,d0          ; time of next change
        move.l  d0,8(a6)

        addq.w  #2,d3           ; increase sequence index - sequence of words
        move.w  (a0,d3),d1      ; fetch image index
        bne     .store_sequence_index ;
        ;; if image index is 0 restart sequence from 0
        move.w  #0,d3
.store_sequence_index:
        move.w  d3,12(a6)       ; save current index in sequence table

.image_uptodate:
        move.w  (a0,d3),d1      ; fetch image index from sequence table
        asl.w   #2,d1           ; Convert to address index
        move.l  (a1,d1),a1      ; fetch image address to a1

        movem.l (sp)+,a0/d0-d3
        rts

;;; a4 - physical screen base address
;;; a5 - animation data (pictures' addresses) address
;;; a6 - animation sequence address
fx_picstretch_animation:
        movem.l a0-a6/d0-d7,-(sp)
        sub.w   #14,sp           ; Allocate 3 longs and 1 word
        ;;  0(sp) - long - address of images sequence table
        ;;  4(sp) - long - address of images pointers
        ;;  8(sp) - long - time of next animation image
        ;; 12(sp) - word - index of current image in sequence table

        ;; Initialize animation structure
        move.l  a6,0(sp)
        move.l  a5,4(sp)
        move.l  #0,8(sp)
        move.w  #0,12(sp)

        ;; set palette
        move.l  (a5),a3
        jsr     set_palette

        ;; Animation initial parameters
        move.l  a4,a0           ; physical screen address
        ;; a1 - image data is computed in the display loop
        lea     wave_table,a2   ; sin table address
        ;; d1 -  pic initial offset - is computed in the display loop
        move.w  #0,d2           ; wave sin initial offset
        ;; d3 is computed in the picture display loop
        move.w  #100,a3         ; d3/a3 pic stretch ratio
        move.w  #1,d4           ; d4/a4 sin stretch ratio
        move.w  #1000,a4
        lea     picstretch_table,a5

        ;; Animation Loop
        move.w  #0,d6           ; Use d6 to keep track of VBL
        move.w  #600,d7
.loop:
        ;; Animation updated parameters
        move.l  sp,a6
        jsr     get_current_image_address ; into a1
        ;; Compute image vertical stretching
        move.w  d7,d0
        and.w   #$3f,d0         ; 64 items table
        asl.w   #1,d0
        move.w  (a5,d0),d3      ; d3 is in [50; 200]
        ;; Compute offset in picture
        move.w  #100,d1
        sub.w   d3,d1
        bpl     .d1_positive
        add.w   #200,d1         ; Add picture size
.d1_positive:
        asl.w   #4,d1   ; *16
        move.w  d1,d0
        asl.w   #2,d1   ; *64
        add.w   d0,d1   ; *80

        ;; Display picture
        ;; Maybe we don't need to wait for next VBL in fact
        jsr     wait_next_vbl   ; d6 contains last vbl
        jsr     picdisplay_stretched_4colors
        dbra    d7,.loop

        add.w   #14,sp           ; Allocate 3 longs and 1 word
        movem.l (sp)+,a0-a6/d0-d7
        rts

;;; a2 - target address for padded picture
;;; a5 - animation address
;;; Return values
;;; a1 - contains padded picture address
;;; Uses a2-a3,d2
init_padded_picture_buffer:
        movem.l a2-a3/d2,-(sp)

        ;; set palette
        move.l  (a5),a3
        jsr     set_palette

        macro padloop
        move.w  #0,d2
.padloop\@:                     ; appends a unique ID to the label
        move.l  #0,(a2,d2)
        addq.w  #4,d2
        cmpi    #(28*80),d2
        blt     .padloop\@
        endm

        ;; Copy padded image on the stack
        padloop

        add.w   #(28*80),a2
        move.l  a2,a1           ; set return value
        move.l  4(a5),a3        ; -> a3 image address
        move.w  #0,d2
.copy_loop:
        move.l  (a3,d2),(a2,d2)
        addq.w  #4,d2
        cmp.w   #(200*80),d2
        blt     .copy_loop

        add.w   #(200*80),a2
        padloop

        movem.l (sp)+,a2-a3/d2
        rts

;;; a4 - physical screen base address
;;; a5 - animation address
fx_wave_animation:
        movem.l a0-a6/d0-d7,-(sp)
        sub.l   #(256*80),sp    ; Allocating RAM for padded picture

        move.l  sp,a2
        jsr init_padded_picture_buffer
        ;; a1 contains padded picture address

        ;; using a5 to fetch data from picstretch_table
        lea     picstretch_table,a5

        ;; Animation initial parameters
        move.l  a4,a0                   ; physical screen address
        lea     wave_table,a2   ; sin table address
        move.w  #0,d1           ; pic initial offset
        move.w  #0,d2           ; wave sin initial offset
        move.w  #1,d3           ; d3/a3 pic stretch ratio
        move.w  #1,a3
        ;move.w  #0,d4           ; d4/a4 sin stretch ratio (useless here)
        move.w  #100,a4

        ;; Animation Loop
        move.w  #600,d7
.loop:
        ;; Animation parameters
        ;; sin offset
        add.w   #18,d2          ; offset must be even
        and.w   #$01ff,d2

        ;; Display picture
        jsr     picdisplay_stretched_4colors

        ;; Compute wave stretching
        move.w  d7,d0
        lsr.w   #2,d0
        and.w   #$3f,d0         ; 64 items table
        asl.w   #1,d0
        move.w  (a5,d0),d4      ; d4 is in [50; 200]
        dbra    d7,.loop

        add.l   #(256*80),sp
        movem.l (sp)+,a0-a6/d0-d7
        rts

;;; Palette is set already
;;; Parameters:
;;; a0 phy_base_addr base address of screen physical memory
;;; a1 pic_base_addr base address of picture to display
;;; a2 sin_base_addr base address of sinus table
;;; d1 pic_offset initial offset in picture - multiple of 80
;;; d2 sin_offset initial offset in sinus table - multiple of 2
;;; d3/a3 pic_X/pic_Y picture stretch ratio
;;; d4/a4 sin_X/sin_Y sinus table stretch ratio
picdisplay_stretched_4colors:
        movem.l a0-a6/d0-d7,-(sp)       ; save registers in stack

        ;; Some initialization
        lea.l   (200*160)(a0),a5        ; phy_end - End of screen physical mem
        lea.l   (200*80)(a1),a6         ; pic_end - End of picture
        move.w  a3,d5                   ; pic_Z - pic ratio computation
        subq.w  #1,d5                   ; minus 1
        move.w  a4,d6                   ; sin_Z - sin ratio computation
        subq.w  #1,d6                   ; minus 1
        ;; Compute pic_line_addr from pic_base_addr and pic_offset
        add.w   d1,a1

.picdisplay_loop:
        ;; a0 - phy_line_addr is the address of the current physical line
        ;; a1 - pic_line_addr is the address of the current picture line
        ;;      without wave offset

        move.w  (a2,d2),d0      ; retrieving sin offset
                                ; as word, already multiple of 80
        ;; Display a line
        REPT 20
        move.l  REPTN*4(a1,d0),REPTN*8(a0)
        ENDR

        ;;
        ;; Prepare next picture line
        ;;

        ;; Compute next picture line (considering picture stretch ratio)
        ;; Substract pic_X from pic_Z
        sub.w   d3,d5
        ;; As long as pic_Z <0 increase it by pic_Y and increase pic_line_addr
        bpl     .picz_positive
.picz_negative:
        add.w   #80,a1
        add.w   a3,d5
        bmi     .picz_negative
.picz_positive:
        cmp.l   a6,a1
        blt     .mod_200
        sub.w   #(200*80),a1
.mod_200:

        ;; Compute next sintable offset (considering sin table stretch ratio)
        ;; Substract sin_X from sin_Z
        sub.w   d4,d6
        ;; As long as sin_Z<0 increase it by sin_Y and increase sin_table_offset
        bpl     .sinz_positive
.sinz_negative:
        add.w   #2,d2
        add.w   a4,d6
        bmi     .sinz_negative
.sinz_positive:
        and.w   #$01ff,d2       ; d2 % 512

        add.w   #160,a0         ; next video buffer line (a4)

        cmp.l   a5,a0           ; Loop until end of display areay is reached
        blt     .picdisplay_loop

        movem.l (sp)+,a0-a6/d0-d7       ; restore registers from stack
        rts


        section wave_table,data
wave_table:
        dc.w $0000, $0000, $0000, $0050, $0050, $0050, $0050, $00a0
        dc.w $00a0, $00a0, $00a0, $00f0, $00f0, $00f0, $00f0, $0140
        dc.w $0140, $0140, $0140, $0140, $0190, $0190, $0190, $0190
        dc.w $01e0, $01e0, $01e0, $01e0, $01e0, $0230, $0230, $0230
        dc.w $0230, $0230, $0230, $0280, $0280, $0280, $0280, $0280
        dc.w $0280, $0280, $02d0, $02d0, $02d0, $02d0, $02d0, $02d0
        dc.w $02d0, $02d0, $02d0, $02d0, $0320, $0320, $0320, $0320
        dc.w $0320, $0320, $0320, $0320, $0320, $0320, $0320, $0320
        dc.w $0320, $0320, $0320, $0320, $0320, $0320, $0320, $0320
        dc.w $0320, $0320, $0320, $0320, $0320, $02d0, $02d0, $02d0
        dc.w $02d0, $02d0, $02d0, $02d0, $02d0, $02d0, $02d0, $0280
        dc.w $0280, $0280, $0280, $0280, $0280, $0280, $0230, $0230
        dc.w $0230, $0230, $0230, $0230, $01e0, $01e0, $01e0, $01e0
        dc.w $01e0, $0190, $0190, $0190, $0190, $0140, $0140, $0140
        dc.w $0140, $0140, $00f0, $00f0, $00f0, $00f0, $00a0, $00a0
        dc.w $00a0, $00a0, $0050, $0050, $0050, $0050, $0000, $0000
        dc.w $0000, $0000, $0000, $ffb0, $ffb0, $ffb0, $ffb0, $ff60
        dc.w $ff60, $ff60, $ff60, $ff10, $ff10, $ff10, $ff10, $fec0
        dc.w $fec0, $fec0, $fec0, $fec0, $fe70, $fe70, $fe70, $fe70
        dc.w $fe20, $fe20, $fe20, $fe20, $fe20, $fdd0, $fdd0, $fdd0
        dc.w $fdd0, $fdd0, $fdd0, $fd80, $fd80, $fd80, $fd80, $fd80
        dc.w $fd80, $fd80, $fd30, $fd30, $fd30, $fd30, $fd30, $fd30
        dc.w $fd30, $fd30, $fd30, $fd30, $fce0, $fce0, $fce0, $fce0
        dc.w $fce0, $fce0, $fce0, $fce0, $fce0, $fce0, $fce0, $fce0
        dc.w $fce0, $fce0, $fce0, $fce0, $fce0, $fce0, $fce0, $fce0
        dc.w $fce0, $fce0, $fce0, $fce0, $fce0, $fd30, $fd30, $fd30
        dc.w $fd30, $fd30, $fd30, $fd30, $fd30, $fd30, $fd30, $fd80
        dc.w $fd80, $fd80, $fd80, $fd80, $fd80, $fd80, $fdd0, $fdd0
        dc.w $fdd0, $fdd0, $fdd0, $fdd0, $fe20, $fe20, $fe20, $fe20
        dc.w $fe20, $fe70, $fe70, $fe70, $fe70, $fec0, $fec0, $fec0
        dc.w $fec0, $fec0, $ff10, $ff10, $ff10, $ff10, $ff60, $ff60
        dc.w $ff60, $ff60, $ffb0, $ffb0, $ffb0, $ffb0, $0000, $0000

picstretch_table:
        dc.w $007d, $0084, $008c, $0093, $009a, $00a0, $00a7, $00ad
        dc.w $00b2, $00b7, $00bb, $00bf, $00c2, $00c5, $00c7, $00c8
        dc.w $00c8, $00c8, $00c7, $00c5, $00c2, $00bf, $00bb, $00b7
        dc.w $00b2, $00ad, $00a7, $00a0, $009a, $0093, $008c, $0084
        dc.w $007d, $0076, $006e, $0067, $0060, $005a, $0053, $004d
        dc.w $0048, $0043, $003f, $003b, $0038, $0035, $0033, $0032
        dc.w $0032, $0032, $0033, $0035, $0038, $003b, $003f, $0043
        dc.w $0048, $004d, $0053, $005a, $0060, $0067, $006e, $0076
