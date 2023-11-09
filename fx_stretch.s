;;; Picture stretching effect
        xdef fx_picstretch_animation
        xdef fx_wave_animation
        xdef get_current_image_address
        xdef picdisplay_stretched_4colors
        xdef wait_next_hz200
        xdef fx_next_frame

        xref get_hz_200
        xref set_palette
        xref spinlock_hz200_simple

        ;; Number of hz_200 units (200th of seconds) per frame
        ;; 4 200th of seconds per frame for 50 FPS
        ;; 5 for 40 FPS
        ;; 6 for 33 FPS
        ;; 8 for 25 FPS
FX_HZ200_PERIOD=5
ANIMATION_HZ200_PERIOD=25       ; 1 image every 25 hz200 i.e 8 FPS

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
;;; a6 - animation sequence
fx_wave_animation:
        movem.l a0-a6/d0-d7,-(sp)

        ;; set palette
        ;; <TODO> Do somewhere else ?
        move.l  (a5),a3
        jsr     set_palette

        ;; Allocate 4 longs for animation structure
        sub.w   #16,sp
        move.l  sp,a0           ; a6 points to the animation structure
        ;; Allocate 9 longs for picture structure
        sub.w   #36,sp          ; sp
        move.l  sp,a1           ; a5 points to the picture structure
        ;; Allocate 7 longs for fx structure
        sub.w   #28,sp          ; sp
        move.l  sp,a2           ; a5 points to the fx structure

        ;; Initialize animation structure
        move.l  a6,0(a0)
        move.l  a5,4(a0)
        jsr     get_hz_200
        add.w   #ANIMATION_HZ200_PERIOD,d0
        move.l  d0,8(a0)
        move.l  #0,12(a0)

        ;; Initialize picture structure
        move.l  a4,16(a1)               ; physical screen address
        move.l  #0,20(a1)               ; address of picture to display (dummy)
        move.l  #wave_table,24(a1)      ; wave sin table address
        move.l  #0,0(a1)                ; pic initial offset
        move.l  #0,2(a1)                ; wave sin initial offset
        move.l  #100,8(a1)              ; d3/a3 pic stretch ratio
        move.l  #100,28(a1)
        move.l  #1,12(a1)             ; d4/a4 sin stretch ratio (useless here)
        move.l  #1000,32(a1)

        ;; Initialize fx structure
        move.l  #18,0(a2)       ; wave_offset_speed
        move.l  #2,4(a2)        ; wave_ratio_speed
        move.l  #4,8(a2)        ; stretch_ratio_speed
        move.l  #0,12(a2)       ; stretch_index
        jsr     get_hz_200
        add.w   #FX_HZ200_PERIOD,d0
        move.l  d0,16(a2)       ; next_frame_hz200
        move.l  a0,20(a2)       ; address of animation structure
        move.l  a1,24(a2)       ; address of picture structure

        ;; Animation Loop
        move.l  a2,a6
        move.w  #400,d7         ; 40 fps - 10 seconds
.loop:
        jsr     fx_next_frame   ; with fx structure in a6
        dbra    d7,.loop

        add.w   #(16+36+28),sp           ; Allocate 3 longs and 1 word
        movem.l (sp)+,a0-a6/d0-d7
        rts

;;; Requires an FX structure in a6
;;; 28 bytes long
;;; To be extracted with: `movem.l (a6),d1-d4/a0-a1`
;;; Parameters - 24 bytes (4*6) in total
;;;  0(a6) - d1 - wave_offset_speed - Speed at which wave offset needs increment
;;;  4(a6) - d2 - wave_ratio_speed - Speed at which the wave ratio changes
;;;  8(a6) - d3 - stretch_ratio_speed - Speed at which the image stretch changes
;;; 12(a6) - d4 - stretch_index - Index in the image stretch table
;;; 16(a6) - d5 - next_frame_hz200 - hz200 time for next frame
;;; 20(a6) - a0 - address of animation structure
;;; 24(a6) - a1 - address of picture structure
fx_next_frame
        movem.l d0-d7/a0-a6,-(sp)
        movem.l (a6),d1-d5/a0-a1

        ;; Compute wave stretching ratio
        lea     picstretch_table,a2
        move.w  (a2,d4),d0      ; d0 is in [50; 200]
        move.l  d0,8(a1)

        ;; Compute picture offset to compensate stretching ratio
        move.w  #100,d6
        sub.w   d0,d6
        ;; Ensure offset is in picture
        bpl     .offset_positive
        add.w   #200,d6         ; Add picture size
        .offset_positive:
        asl.w   #4,d6   ; *16
        move.w  d6,d0
        asl.w   #2,d6   ; *64
        add.w   d0,d6   ; *80
        move.l  d6,0(a1)

        ;; Retrieve address of picture to display
        movem.l a1/a5/a6,-(sp)
        move.l  a0,a6
        move.l  a1,a5
        jsr     get_current_image_address ; into a1 (from a6)
        move.l  a1,20(a5)       ; 20(a5) is address of picture in picture_struct
        movem.l (sp)+,a1/a5/a6

        ;; Display picture
        move.l  a6,-(sp)
        move.l  a1,a6
        jsr     picdisplay_stretched_4colors
        move.l  (sp)+,a6

        move.l  d5,d6
        jsr     wait_next_hz200   ; d6 contains next hz200 to wait for

        ;; Update loop parameters
        add.w   d3,d4           ; index to a word table
        and.w   #$1ff,d4         ; 256 items but left-shifted
        move.l  d4,12(a6)
        add.l   #FX_HZ200_PERIOD,d5
        move.l  d5,16(a6)

        movem.l (sp)+,d0-d7/a0-a6
        rts

;;; a6 contains the address of the following animation structure:
;;;  0(a6) - long - address of images sequence table
;;;  4(a6) - long - address of images pointers
;;;  8(a6) - long - time of next animation image
;;; 12(a6) - long - index of current image in sequence table
;;;
;;; a1 - returns the current image address in a1
;;; Index in sequence table and time of next animation are updated
get_current_image_address:
        movem.l a0/d0-d3,-(sp)
        move.l  0(a6),a0        ; sequence table address
        move.l  4(a6),a1        ; images pointers table addess
        move.l  8(a6),d2        ; time of next animation image
        move.l  12(a6),d3       ; index in sequence table

        ;; Is it time for new animation image ?
        jsr     get_hz_200      ; into d0
        cmp.l   d2,d0
        blt     .image_uptodate
        ;; time of next image has been reached
        add.w   #ANIMATION_HZ200_PERIOD,d2          ; time of next change
        move.l  d2,8(a6)

        addq.w  #2,d3           ; increase sequence index - sequence of words
        move.w  (a0,d3),d1      ; fetch image index
        bne     .store_sequence_index ;
        ;; if image index is 0 restart sequence from 0
        move.w  #0,d3
.store_sequence_index:
        move.l  d3,12(a6)       ; save current index in sequence table

.image_uptodate:
        move.w  (a0,d3),d1      ; fetch image index from sequence table
        asl.w   #2,d1           ; Convert to address index
        move.l  (a1,d1),a1      ; fetch image address to a1

        movem.l (sp)+,a0/d0-d3
        rts

;;; picture_struct
;;; Parameters are stored at an address (usually in the stack)
;;; pointed to by a6
;;; To be extracted with: `movem.l (a6),d1-d4/a0-a4`
;;; Parameters - 36 bytes (4*9) in total
;;; 16(a6) - a0 - phy_base_addr base address of screen physical memory
;;; 20(a6) - a1 - pic_base_addr base address of picture to display
;;; 24(a6) - a2 - sin_base_addr base address of sinus table
;;;  0(a6) - d1 - pic_offset initial offset in picture - multiple of 80
;;;  4(a6) - d2 - sin_offset initial offset in sinus table - multiple of 2
;;;  8(a6) - d3 - d3/a3 pic_X/pic_Y picture stretch ratio
;;; 28(a6) - a3
;;; 12(a6) - d4 - d4/a4 sin_X/sin_Y sinus table stretch ratio
;;; 32(a6) - a4
picdisplay_stretched_4colors:
        movem.l a0-a6/d0-d7,-(sp)       ; save registers in stack
        movem.l (a6),d1-d4/a0-a4        ; retrieve registers values from a6

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

        ;; *** Prepare next picture line *** ;;

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
        dc.w $007d, $007f, $0081, $0083, $0084, $0086, $0088, $008a
        dc.w $008c, $008d, $008f, $0091, $0093, $0095, $0096, $0098
        dc.w $009a, $009b, $009d, $009f, $00a0, $00a2, $00a4, $00a5
        dc.w $00a7, $00a8, $00aa, $00ab, $00ad, $00ae, $00af, $00b1
        dc.w $00b2, $00b3, $00b5, $00b6, $00b7, $00b8, $00b9, $00ba
        dc.w $00bb, $00bc, $00bd, $00be, $00bf, $00c0, $00c1, $00c2
        dc.w $00c2, $00c3, $00c4, $00c4, $00c5, $00c5, $00c6, $00c6
        dc.w $00c7, $00c7, $00c7, $00c7, $00c8, $00c8, $00c8, $00c8
        dc.w $00c8, $00c8, $00c8, $00c8, $00c8, $00c7, $00c7, $00c7
        dc.w $00c7, $00c6, $00c6, $00c5, $00c5, $00c4, $00c4, $00c3
        dc.w $00c2, $00c2, $00c1, $00c0, $00bf, $00be, $00bd, $00bc
        dc.w $00bb, $00ba, $00b9, $00b8, $00b7, $00b6, $00b5, $00b3
        dc.w $00b2, $00b1, $00af, $00ae, $00ad, $00ab, $00aa, $00a8
        dc.w $00a7, $00a5, $00a4, $00a2, $00a0, $009f, $009d, $009b
        dc.w $009a, $0098, $0096, $0095, $0093, $0091, $008f, $008d
        dc.w $008c, $008a, $0088, $0086, $0084, $0083, $0081, $007f
        dc.w $007d, $007b, $0079, $0077, $0076, $0074, $0072, $0070
        dc.w $006e, $006d, $006b, $0069, $0067, $0065, $0064, $0062
        dc.w $0060, $005f, $005d, $005b, $005a, $0058, $0056, $0055
        dc.w $0053, $0052, $0050, $004f, $004d, $004c, $004b, $0049
        dc.w $0048, $0047, $0045, $0044, $0043, $0042, $0041, $0040
        dc.w $003f, $003e, $003d, $003c, $003b, $003a, $0039, $0038
        dc.w $0038, $0037, $0036, $0036, $0035, $0035, $0034, $0034
        dc.w $0033, $0033, $0033, $0033, $0032, $0032, $0032, $0032
        dc.w $0032, $0032, $0032, $0032, $0032, $0033, $0033, $0033
        dc.w $0033, $0034, $0034, $0035, $0035, $0036, $0036, $0037
        dc.w $0038, $0038, $0039, $003a, $003b, $003c, $003d, $003e
        dc.w $003f, $0040, $0041, $0042, $0043, $0044, $0045, $0047
        dc.w $0048, $0049, $004b, $004c, $004d, $004f, $0050, $0052
        dc.w $0053, $0055, $0056, $0058, $005a, $005b, $005d, $005f
        dc.w $0060, $0062, $0064, $0065, $0067, $0069, $006b, $006d
        dc.w $006e, $0070, $0072, $0074, $0076, $0077, $0079, $007b

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
