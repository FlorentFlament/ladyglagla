;;; Picture stretching effect
        xdef fx_picstretch_animation
        xdef fx_wave_animation
        xdef get_current_image_address
        xdef picdisplay_stretched_4colors
        xdef wait_next_hz200
        xdef fx_next_frame
        xdef fx_loop
        xdef process_controller

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

;;; Parameters:
;;; a4 - physical screen base address
;;; a5 - animation address
;;; a6 - animation sequence
fx_wave_animation:
        movem.l a0-a6/d0-d7,-(sp)
        ;; Initialize fx structures before calling main fx loop

        ;; Allocate 5 longs for fx structure
        ;; It encapsulates very other structure
        sub.w   #24,sp          ; sp
        move.l  sp,a0           ; a0 points to the fx structure

        ;; Allocate 4 longs for animation structure
        sub.w   #16,sp
        move.l  sp,a1           ; a1 points to the animation structure
        ;; Initialize animation structure
        jsr     get_hz_200
        add.w   #ANIMATION_HZ200_PERIOD,d0
        move.l  d0,0(a1)
        move.l  #0,4(a1)
        move.l  a6,8(a1)
        move.l  a5,12(a1)
        ;; Store animation structrure address into fx structure
        move.l  a1,(a0)

        ;; Allocate 9 longs for picture structure
        sub.w   #36,sp
        move.l  sp,a1           ; a1 points to the picture structure
        ;; Initialize picture structure
        move.l  a4,16(a1)               ; physical screen address
        move.l  #0,20(a1)               ; address of picture to display
        move.l  #wave_table,24(a1)      ; wave table address
        move.l  #0,0(a1)                ; pic_offset
        move.l  #0,4(a1)                ; wave_offset
        move.l  #100,8(a1)              ; d3/a3 pic_ratio
        move.l  #100,28(a1)
        move.l  #1,12(a1)               ; d4/a4 wave_ration
        move.l  #1000,32(a1)
        ;; Store structrure address into fx structure
        move.l  a1,4(a0)

        ;; Allocate pic_offset controller - (7*2+2*4)=22 bytes
        sub.w   #22,sp
        move.l  sp,a2           ; a1 points to the animation structure
        ;; Initialize pic_offset controller
        move.w  #1,0(a2)        ; (0,1,2) inactive/linear/table
        move.w  #80,2(a2)       ; Linear step / 2 when word Table
        move.w  #0,4(a2)        ; Current value / Table index
        move.w  #(80*200),6(a2) ; linear/table_index modulus
        move.w  #100,8(a2)      ; X - of X/Y speed factor
        move.w  #100,10(a2)     ; Y - of X/Y speed factor
        move.w  #0,12(a2)       ; Z - of speed factor
        move.l  a1,14(a2)       ; Address of parameter to control
        move.l  #0,18(a2)       ; Table address (if any)
        ;; Store structrure address into fx structure
        move.l  a2,20(a0)

        ;; Allocate 4 words for fx_stretch structure
        sub.w   #8,sp
        move.l  sp,a1           ; a2 points to the fx_stretch structure
        ;; Initialize fx_stretch structure
        move.w  #0,0(a1)       ; stretch_X - stretch_ratio_speed (X/Y)
        move.w  #100,2(a1)     ; stretch_Y
        move.w  #0,4(a1)       ; stretch_Z
        move.w  #0,6(a1)       ; stretch_index
        ;; Store structrure address into fx structure
        move.l  a1,8(a0)

        ;; Allocate 4 words for fx_offset structure
        sub.w   #8,sp
        move.l  sp,a1           ; a3 points to the fx_offset structure
        ;; Initialize fx_offset structure
        move.w  #0,0(a1)       ; offset_X - offset_ratio_speed (X/Y)
        move.w  #0,2(a1)       ; offset_Y
        move.w  #0,4(a1)       ; offset_Z
        move.w  #0,6(a1)       ; offset_index
        ;; Store structrure address into fx structure
        move.l  a1,12(a0)

        ;; Allocate 4 words for fx_wave structure
        sub.w   #8,sp
        move.l  sp,a1           ; a4 points to the fx_wave structure
        ;; Initialize fx_wave structure
        move.w  #1,0(a1)       ; wave_X - wave_ratio_speed (X/Y)
        move.w  #1000,2(a1)    ; wave_Y
        move.w  #0,4(a1)       ; wave_Z
        move.w  #0,6(a1)       ; wave_index
        ;; Store structrure address into fx structure
        move.l  a1,16(a0)

        ;; set palette
        move.l  (a5),a3
        jsr     set_palette

        ;; Move to main fx_loop
        move.l  a0,a6
        jsr fx_loop             ; with fx structure in a6

        add.w   #(24+16+36+22+8+8+8),sp           ; Allocate 3 longs and 1 word
        movem.l (sp)+,a0-a6/d0-d7
        rts

;;; Parameters
;;; a6 - fx structure
fx_loop:
        movem.l a0-a6/d0-d7,-(sp)

        ;; Animation Loop
        lea.l   stretch_speed_table,a0 ; for stretch speed trajectory
        move.l  8(a6),a1               ; fx_stretch structure in a1

        jsr     get_hz_200      ; into d0
        move.l  d0,d6           ; hz_200 is in d6
        add.l   #FX_HZ200_PERIOD,d6
        move.w  #0,d7           ; frame counter is in d7

        .loop:
        move.w  d7,d0           ; for stretch speed lookup
        lsr.w   #3,d0           ; /8
        asl.w   #1,d0
        move.w  (a0,d0),(a1)    ; update stretch X
        jsr     fx_next_frame   ; with fx structure in a6

        ;; Update loop parameters
        jsr     wait_next_hz200   ; d6 contains next hz200 to wait for
        add.l   #FX_HZ200_PERIOD,d6

        addq.w  #1,d7
        cmp.w   #1022,d7         ; 40 fps - 512 - 16 beats = 12.8 secs
        blt     .loop

        movem.l (sp)+,a0-a6/d0-d7
        rts

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

;;; Requires an FX structure in a6
;;; 24 bytes long (6*4)
;;; To be extracted with: `movem.l (a6),a0-a4`
;;;  0(a6) - a0 - address of animation structure
;;;  4(a6) - a1 - address of picture structure
;;;  8(a6) - a2 - address of fx_stretch structure
;;; 12(a6) - a3 - address of fx_offset structure
;;; 16(a6) - a4 - address of fx_wave structure
;;; 20(a6) - a5 - address of pic_offset controller
fx_next_frame
        movem.l d0-d7/a0-a6,-(sp)
        move.l  a6,a5           ; fx structure in a5
        move.l  4(a5),a4        ; picture structure in a4

        move.l  20(a5),a6
        jsr     process_controller ; controller data pointed by a6

        ;; Compute stretching ratio
        move.l  8(a5),a6
        jsr     get_next_stretch_X ; into d0
        move.l  d0,8(a4)           ; stretch_X into picture struct

        ;; Compute picture offset to compensate stretching ratio
        move.w  #100,d1
        sub.w   d0,d1
        ;; Ensure offset is in picture
        bpl     .offset_positive
        add.w   #200,d1         ; Add picture size
        .offset_positive:
        asl.w   #4,d1   ; *16
        move.w  d1,d0
        asl.w   #2,d1   ; *64
        add.w   d0,d1   ; *80
        ;move.l  d1,0(a4)        ; picture offset into picture struct

        ;; Retrieve address of picture to display
        move.l  0(a5),a6
        jsr     get_current_image_address ; into a1 (from a6)
        move.l  a1,20(a4)       ; at address of picture in picture_struct

        ;; Display picture
        move.l  a4,a6
        jsr     picdisplay_stretched_4colors

        movem.l (sp)+,d0-d7/a0-a6
        rts

;;; Parameters:
;;; a6 - address of controller structure (22 bytes = 7*2+2*4)
;;; Controller structure:
;;;  0(a6) - (0,1,2) inactive/linear/table
;;;  2(a6) - d0 - Value step / 2 when Table
;;;  4(a6) - d1 - Current value / Table index
;;;  6(a6) - d2 - linear/table_index modulus
;;;  8(a6) - d3 - X - of X/Y speed factor
;;; 10(a6) - d4 - Y - of X/Y speed factor
;;; 12(a6) - d5 - Z - of speed factor
;;; 14(a6) - Address of parameter to control
;;; 18(a6) - Table address (if any)
process_controller:
        movem.l d1-d7/a0-a6,-(sp)
        cmpi.w  #0,(a6)
        beq     .end

        movem.w 2(a6),d0-d5
        sub.w   d3,d5           ; Substract X from Z
        ;; As long as Z<0 increase Z by Y
        ;;   Also increase current value by value step
        bpl     .z_positive
        .z_negative:
        add.w   d0,d1           ; increase current value by value step
        add.w   d4,d5           ; increase Z by Y
        bmi     .z_negative
        .z_positive:
        ;; modulus d2
        cmp.w   d2,d1
        blt     .mod_d2
        sub.w   d2,d1
        .mod_d2:

        ;; Store updated values
        move.w  d1,4(a6)
        move.w  d5,12(a6)

        ;; Parameter is a long (for now)
        move.l  14(a6),a0       ; a0 - address of parameter to update
        move.l  d1,(a0)
        cmpi.w  #2,(a6)         ; Use value from table if table mode
        bne     .end
        ;; Using Table
        move.l  18(a6),a1       ;a1 - address of lookup table
        move.l  (a6,d1),(a0)

        .end:
        movem.l (sp)+,d1-d7/a0-a6
        rts

;;; Requires:
;;; a6 - an fx_stretch structure
;;; Returns:
;;; d0 - pic_X picture stretch ratio (not to be confused with stretch_X)
;;; Note: stretch_X is not updated there
;;; fx_stretch structure:
;;; 0(a6) - d1 - stretch_X
;;; 2(a6) - d2 - stretch_Y
;;; 4(a6) - d3 - stretch_Z
;;; 6(a6) - d4 - stretch_index
get_next_stretch_X:
        movem.l d1-d7/a0-a6,-(sp)
        movem.w (a6),d1-d4

        ;; Compute next stretch index
        ;; Substract stretch_X from stretch_Z
        sub.w   d1,d3
        ;; As long as stretch_Z<0 increase it by stretch_Y
        ;;   Also increase stretch index
        bpl     .stretchz_positive
.sinz_negative:
        add.w   #2,d4           ; increase by a word
        add.w   d2,d3
        bmi     .sinz_negative
.stretchz_positive:
        and.w   #$01ff,d4       ; 256 items but left-shifted

        ;; Update stretch_z and stretch_index into fx_stretch structure
        move.w  d3,4(a6)
        move.w  d4,6(a6)

        ;; return pic_X value in d0
        lea     picstretch_table,a0
        move.w  (a0,d4),d0      ; d0 is in [50; 200]

        movem.l (sp)+,d1-d7/a0-a6
        rts

;;; Parameters
;;; a6 contains the address of the following animation structure:
;;;  0(a6) - long - time of next animation image
;;;  4(a6) - long - index of current image in sequence table
;;;  8(a6) - long - address of images sequence table
;;; 12(a6) - long - address of images pointers
;;; Return value:
;;; a1 - returns the current image address in a1
;;; Notes:
;;; Index in sequence table and time of next animation are updated
get_current_image_address:
        movem.l d0-d3/a0,-(sp)
        movem.l (a6),d2-d3/a0-a1

        ;; Is it time for new animation image ?
        jsr     get_hz_200      ; into d0
        cmp.l   d2,d0
        blt     .image_uptodate
        ;; time of next image has been reached
        add.l   #ANIMATION_HZ200_PERIOD,d2          ; time of next change

        addq.w  #2,d3           ; increase sequence index - sequence of words
        move.w  (a0,d3),d1      ; fetch image index
        bne     .store_values ;
        ;; if image index is 0 restart sequence from 0
        move.w  #0,d3

        .store_values:
        movem.l d2-d3,(a6)

        .image_uptodate:
        move.w  (a0,d3),d1      ; fetch image index from sequence table
        asl.w   #2,d1           ; Convert to address index
        move.l  (a1,d1),a1      ; fetch image address to a1

        movem.l (sp)+,d0-d3/a0
        rts

;;; picture_structure
;;; Parameters are stored at an address (usually in the stack)
;;; pointed to by a6
;;; To be extracted with: `movem.l (a6),d1-d4/a0-a4`
;;; Parameters - 36 bytes (4*9) in total
;;; 16(a6) - a0 - phy_base_addr base address of screen physical memory
;;; 20(a6) - a1 - pic_base_addr base address of picture to display
;;; 24(a6) - a2 - wave_base_addr base address of wave table
;;;  0(a6) - d1 - pic_offset offset in picture - multiple of 80
;;;  4(a6) - d2 - wave_offset offset in wave table - multiple of 2
;;;  8(a6) - d3 - d3/a3 pic_X/pic_Y pic_ratio (stretching)
;;; 28(a6) - a3
;;; 12(a6) - d4 - d4/a4 sin_X/sin_Y wave_ratio
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
        move.l  REPTN*4(a1,d0),REPTN*8(a0) ; <-
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
        dc.w $0064, $0066, $0068, $0069, $006b, $006d, $006f, $0070
        dc.w $0072, $0074, $0076, $0078, $007a, $007b, $007d, $007f
        dc.w $0081, $0083, $0085, $0086, $0088, $008a, $008c, $008e
        dc.w $0090, $0091, $0093, $0095, $0097, $0098, $009a, $009c
        dc.w $009d, $009f, $00a1, $00a2, $00a4, $00a5, $00a7, $00a8
        dc.w $00aa, $00ab, $00ad, $00ae, $00b0, $00b1, $00b2, $00b4
        dc.w $00b5, $00b6, $00b7, $00b8, $00b9, $00ba, $00bc, $00bd
        dc.w $00bd, $00be, $00bf, $00c0, $00c1, $00c2, $00c2, $00c3
        dc.w $00c4, $00c4, $00c5, $00c5, $00c6, $00c6, $00c7, $00c7
        dc.w $00c7, $00c7, $00c8, $00c8, $00c8, $00c8, $00c8, $00c8
        dc.w $00c8, $00c8, $00c8, $00c7, $00c7, $00c7, $00c7, $00c6
        dc.w $00c6, $00c5, $00c5, $00c4, $00c4, $00c3, $00c2, $00c1
        dc.w $00c1, $00c0, $00bf, $00be, $00bd, $00bc, $00bb, $00ba
        dc.w $00b9, $00b8, $00b7, $00b6, $00b4, $00b3, $00b2, $00b1
        dc.w $00af, $00ae, $00ac, $00ab, $00a9, $00a8, $00a6, $00a5
        dc.w $00a3, $00a2, $00a0, $009e, $009d, $009b, $0099, $0098
        dc.w $0096, $0094, $0092, $0091, $008f, $008d, $008b, $008a
        dc.w $0088, $0086, $0084, $0082, $0080, $007f, $007d, $007b
        dc.w $0079, $0077, $0075, $0074, $0072, $0070, $006e, $006c
        dc.w $006a, $0069, $0067, $0065, $0063, $0062, $0060, $005e
        dc.w $005d, $005b, $0059, $0058, $0056, $0055, $0053, $0052
        dc.w $0050, $004f, $004d, $004c, $004a, $0049, $0048, $0046
        dc.w $0045, $0044, $0043, $0042, $0041, $0040, $003e, $003d
        dc.w $003d, $003c, $003b, $003a, $0039, $0038, $0038, $0037
        dc.w $0036, $0036, $0035, $0035, $0034, $0034, $0033, $0033
        dc.w $0033, $0033, $0032, $0032, $0032, $0032, $0032, $0032
        dc.w $0032, $0032, $0032, $0033, $0033, $0033, $0033, $0034
        dc.w $0034, $0035, $0035, $0036, $0036, $0037, $0038, $0039
        dc.w $0039, $003a, $003b, $003c, $003d, $003e, $003f, $0040
        dc.w $0041, $0042, $0043, $0044, $0046, $0047, $0048, $0049
        dc.w $004b, $004c, $004e, $004f, $0051, $0052, $0054, $0055
        dc.w $0057, $0058, $005a, $005c, $005d, $005f, $0061, $0062

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

stretch_speed_table:
        dc.w $0032, $003c, $0046, $0050, $005a, $0064, $006e, $0078
        dc.w $0082, $008c, $0096, $00a0, $00aa, $00b4, $00be, $00c8
        dc.w $00d2, $00dc, $00e6, $00f0, $00fa, $0104, $010e, $0118
        dc.w $0122, $012c, $0136, $0140, $014a, $0154, $015e, $0168
        dc.w $0172, $017c, $0186, $0190, $019a, $01a4, $01ae, $01b8
        dc.w $01c2, $01cc, $01d6, $01e0, $01ea, $01f4, $01fe, $0208
        dc.w $0212, $021c, $0226, $0230, $023a, $0244, $024e, $0258
        dc.w $0262, $026c, $0276, $0280, $028a, $0294, $029e, $02a8
        dc.w $02b2, $02bc, $02c6, $02d0, $02da, $02e4, $02ee, $02f8
        dc.w $0302, $030c, $0316, $0320, $0316, $030c, $0302, $02f8
        dc.w $02ee, $02e4, $02da, $02d0, $02c6, $02bc, $02b2, $02a8
        dc.w $029e, $0294, $028a, $0280, $0276, $026c, $0262, $0258
        dc.w $024e, $0244, $023a, $0230, $0226, $021c, $0212, $0208
        dc.w $01fe, $01f4, $01ea, $01e0, $01d6, $01cc, $01c2, $01b8
        dc.w $01ae, $01a4, $019a, $0190, $0190, $0190, $0190, $0190
        dc.w $0190, $0190, $0190, $0190, $0190, $0190, $0190, $0190
