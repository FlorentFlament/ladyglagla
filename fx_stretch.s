;;; Picture stretching effect
        xdef fx_picstretch_animation
        xdef fx_wave_animation
        xdef get_current_image_address
        xdef picdisplay_stretched_4colors
        xdef wait_next_hz200

        xref get_hz_200
        xref set_palette
        xref spinlock_hz200_simple

        ;; Number of hz_200 units (200th of seconds) per frame
        ;; 4 200th of seconds per frame for 50 FPS
        ;; 5 for 40 FPS
        ;; 6 for 33 FPS
        ;; 8 for 25 FPS
FX_HZ200_PERIOD=5

;;; d6 contains next hz_200 value to wait for
wait_next_hz200:
        movem.l d0-d3/a0-a2,-(sp)

        move.l  d6,d3
        pea     spinlock_hz200_simple
        move.w  #38,-(sp)       ; Supexec function call
        trap    #14             ; Call XBIOS
        addq.l  #6,sp           ; Correct stack

        .after_wait:
        movem.l (sp)+,d0-d3/a0-a2
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
        ;; a5 - used as temporary address register for indirect accesses
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
        move.l  sp,a6           ; Address of animation structure
        jsr     get_hz_200
        add.w   #FX_HZ200_PERIOD,d0
        move.l  d0,d6          ; Stores successive hz_2000 in d6

        ;; Animation Loop
        move.w  #600,d7
.loop:
        ;; Animation updated parameters
        ;; Compute image vertical stretching
        lea     picstretch_table,a5
        move.w  d7,d0
        and.w   #$3f,d0         ; 64 items table
        asl.w   #1,d0
        move.w  (a5,d0),d3      ; d3 is in [50; 200]

        ;; Retrieve offset for picture movement
        lea     offset_table,a5
        move.w  d7,d0
        and.w   #$ff,d0         ; 64 items table
        asl.w   #1,d0
        move.w  (a5,d0),d1      ; d1 is in [-50; 50]
        ;; Compensate offset to center stretch FX
        add.w   #100,d1
        sub.w   d3,d1

        ;; Ensure offset is in picture
        bpl     .offset_positive
        add.w   #200,d1         ; Add picture size
        .offset_positive:
        asl.w   #4,d1   ; *16
        move.w  d1,d0
        asl.w   #2,d1   ; *64
        add.w   d0,d1   ; *80

        ;; Display picture
        jsr     get_current_image_address ; into a1
        jsr     picdisplay_stretched_4colors
        jsr     wait_next_hz200 ; d6 contains next hz200 to wait for

        ;; Update loop variables then loop
        add.w   #FX_HZ200_PERIOD,d6
        subq.w  #1,d7
        bpl     .loop

        add.w   #14,sp           ; Allocate 3 longs and 1 word
        movem.l (sp)+,a0-a6/d0-d7
        rts

;;; a4 - physical screen base address
;;; a5 - animation address
fx_wave_animation:
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
        move.l  a4,a0                   ; physical screen address
        lea     wave_table,a2   ; sin table address
        ;move.w  #0,d1           ; pic initial offset - unused
        move.w  #0,d2           ; wave sin initial offset
        move.w  #1,d3           ; d3/a3 pic stretch ratio
        move.w  #1,a3
        ;move.w  #0,d4           ; d4/a4 sin stretch ratio (useless here)
        move.w  #100,a4
        move.l  sp,a6           ; address of animation structure
        jsr     get_hz_200
        add.w   #FX_HZ200_PERIOD,d0
        move.w  d0,d6          ; Stores successive hz_2000 in d6

        ;; Animation Loop
        move.w  #600,d7
.loop:
        ;; Animation updated parameters

        ;; Compute wave stretching
        lea     picstretch_table,a5
        move.w  d7,d0
        lsr.w   #2,d0
        and.w   #$3f,d0         ; 64 items table
        asl.w   #1,d0
        move.w  (a5,d0),d4      ; d4 is in [50; 200]

        ;; Retrieve offset for picture movement
        lea     offset_table,a5
        move.w  d7,d0
        and.w   #$ff,d0         ; 64 items table
        asl.w   #1,d0
        move.w  (a5,d0),d1      ; d1 is in [-50; 50]

        ;; Ensure offset is in picture
        bpl     .offset_positive
        add.w   #200,d1         ; Add picture size
        .offset_positive:
        asl.w   #4,d1   ; *16
        move.w  d1,d0
        asl.w   #2,d1   ; *64
        add.w   d0,d1   ; *80

        ;; Display picture
        jsr     get_current_image_address ; into a1
        jsr     picdisplay_stretched_4colors
        jsr     wait_next_hz200   ; d6 contains next hz200 to wait for

        ;; Update loop parameters then loop
        add.w   #FX_HZ200_PERIOD,d6
        ;; Update sin offset
        add.w   #18,d2          ; offset must be even
        and.w   #$01ff,d2
        dbra    d7,.loop

        add.w   #14,sp           ; Allocate 3 longs and 1 word
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
        move.w  a3,d5                   ; pic_Z - pic ratio computation
        subq.w  #1,d5                   ; minus 1
        move.w  a4,d6                   ; sin_Z - sin ratio computation
        subq.w  #1,d6                   ; minus 1

.picdisplay_loop:
        ;; a0 - phy_line_addr is the address of the current physical line
        ;; d1 - pic_line_offset is the offset of the current picture line
        ;;      without wave offset
        ;; d2 - wave_offset is the wave_offset in the wave_table
        ;; d0 - is the sum mod 200

        move.w  (a2,d2),d0      ; can be negative
        add.w   d1,d0
        bpl     .offset_positive
        add.w   #(200*80),d0
.offset_positive:
        cmp.w   #(200*80),d0
        blt     .offset_mod200
        sub.w   #(200*80),d0
.offset_mod200:

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
        add.w   #80,d1
        add.w   a3,d5
        bmi     .picz_negative
.picz_positive:
        cmp.w   #(200*80),d1
        blt     .picz_mod200
        sub.w   #(200*80),d1
.picz_mod200:

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

offset_table:
        dc.w $0000, $0001, $0002, $0004, $0005, $0006, $0007, $0009
        dc.w $000a, $000b, $000c, $000d, $000f, $0010, $0011, $0012
        dc.w $0013, $0014, $0015, $0016, $0018, $0019, $001a, $001b
        dc.w $001c, $001d, $001e, $001f, $0020, $0021, $0022, $0022
        dc.w $0023, $0024, $0025, $0026, $0027, $0027, $0028, $0029
        dc.w $002a, $002a, $002b, $002c, $002c, $002d, $002d, $002e
        dc.w $002e, $002f, $002f, $002f, $0030, $0030, $0031, $0031
        dc.w $0031, $0031, $0031, $0032, $0032, $0032, $0032, $0032
        dc.w $0032, $0032, $0032, $0032, $0032, $0032, $0031, $0031
        dc.w $0031, $0031, $0031, $0030, $0030, $002f, $002f, $002f
        dc.w $002e, $002e, $002d, $002d, $002c, $002c, $002b, $002a
        dc.w $002a, $0029, $0028, $0027, $0027, $0026, $0025, $0024
        dc.w $0023, $0022, $0022, $0021, $0020, $001f, $001e, $001d
        dc.w $001c, $001b, $001a, $0019, $0018, $0016, $0015, $0014
        dc.w $0013, $0012, $0011, $0010, $000f, $000d, $000c, $000b
        dc.w $000a, $0009, $0007, $0006, $0005, $0004, $0002, $0001
        dc.w $0000, $ffff, $fffe, $fffc, $fffb, $fffa, $fff9, $fff7
        dc.w $fff6, $fff5, $fff4, $fff3, $fff1, $fff0, $ffef, $ffee
        dc.w $ffed, $ffec, $ffeb, $ffea, $ffe8, $ffe7, $ffe6, $ffe5
        dc.w $ffe4, $ffe3, $ffe2, $ffe1, $ffe0, $ffdf, $ffde, $ffde
        dc.w $ffdd, $ffdc, $ffdb, $ffda, $ffd9, $ffd9, $ffd8, $ffd7
        dc.w $ffd6, $ffd6, $ffd5, $ffd4, $ffd4, $ffd3, $ffd3, $ffd2
        dc.w $ffd2, $ffd1, $ffd1, $ffd1, $ffd0, $ffd0, $ffcf, $ffcf
        dc.w $ffcf, $ffcf, $ffcf, $ffce, $ffce, $ffce, $ffce, $ffce
        dc.w $ffce, $ffce, $ffce, $ffce, $ffce, $ffce, $ffcf, $ffcf
        dc.w $ffcf, $ffcf, $ffcf, $ffd0, $ffd0, $ffd1, $ffd1, $ffd1
        dc.w $ffd2, $ffd2, $ffd3, $ffd3, $ffd4, $ffd4, $ffd5, $ffd6
        dc.w $ffd6, $ffd7, $ffd8, $ffd9, $ffd9, $ffda, $ffdb, $ffdc
        dc.w $ffdd, $ffde, $ffde, $ffdf, $ffe0, $ffe1, $ffe2, $ffe3
        dc.w $ffe4, $ffe5, $ffe6, $ffe7, $ffe8, $ffea, $ffeb, $ffec
        dc.w $ffed, $ffee, $ffef, $fff0, $fff1, $fff3, $fff4, $fff5
        dc.w $fff6, $fff7, $fff9, $fffa, $fffb, $fffc, $fffe, $ffff
