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
        move.l  #30,8(a1)              ; d3/a3 pic_ratio
        move.l  #100,28(a1)
        move.l  #200,12(a1)               ; d4/a4 wave_ratio
        move.l  #100,32(a1)
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
        move.l  #wave_table,18(a2)       ; Table address (if any)
        ;; Store structrure address into fx structure
        move.l  a2,8(a0)

        ;; Allocate pic_ratio controller - (7*2+2*4)=22 bytes
        sub.w   #22,sp
        move.l  sp,a2           ; a1 points to the animation structure
        ;; Initialize pic_ratio controller
        move.w  #2,0(a2)        ; (0,1,2) inactive/linear/table
        move.w  #2,2(a2)        ; Linear step / 2 when word Table
        move.w  #0,4(a2)        ; Current value / Table index
        move.w  #(2*256),6(a2)  ; linear/table_index modulus
        move.w  #100,8(a2)      ; X - of X/Y speed factor
        move.w  #100,10(a2)     ; Y - of X/Y speed factor
        move.w  #0,12(a2)       ; Z - of speed factor
        lea.l   8(a1),a3
        move.l  a3,14(a2)       ; Address of parameter to control
        move.l  #pic_ratio_table,18(a2)       ; Table address (if any)
        ;; Store structure address into fx structure
        move.l  a2,12(a0)

        ;; Allocate wave_offset controller - (7*2+2*4)=22 bytes
        sub.w   #22,sp
        move.l  sp,a2           ; a1 points to the animation structure
        ;; Initialize wave_offset controller
        move.w  #1,0(a2)        ; (0,1,2) inactive/linear/table
        move.w  #(2*8),2(a2)   ; Linear step / 2 when word Table
        move.w  #0,4(a2)        ; Current value / Table index
        move.w  #(2*256),6(a2)  ; linear/table_index modulus
        move.w  #100,8(a2)      ; X - of X/Y speed factor
        move.w  #100,10(a2)     ; Y - of X/Y speed factor
        move.w  #0,12(a2)       ; Z - of speed factor
        lea.l   4(a1),a3        ; Address of parameter to control
        move.l  a3,14(a2)
        move.l  #0,18(a2)       ; Table address (if any)
        ;; Store structrure address into fx structure
        move.l  a2,16(a0)

        ;; Allocate wave_ratio controller - (7*2+2*4)=22 bytes
        sub.w   #22,sp
        move.l  sp,a2           ; a1 points to the animation structure
        ;; Initialize wave_ratio controller
        move.w  #2,0(a2)        ; (0,1,2) inactive/linear/table
        move.w  #4,2(a2)        ; Linear step / 2 when word Table
        move.w  #0,4(a2)        ; Current value / Table index
        move.w  #(2*256),6(a2)  ; linear/table_index modulus
        move.w  #100,8(a2)      ; X - of X/Y speed factor
        move.w  #100,10(a2)     ; Y - of X/Y speed factor
        move.w  #0,12(a2)       ; Z - of speed factor
        lea.l   12(a1),a3       ; Address of parameter to control
        move.l  a3,14(a2)
        move.l  #wave_ratio_table,18(a2)       ; Table address (if any)
        ;; Store structure address into fx structure
        move.l  a2,20(a0)

        ;; set palette
        move.l  (a5),a3
        jsr     set_palette

        ;; Move to main fx_loop
        move.l  a0,a6
        jsr fx_loop             ; with fx structure in a6

        add.w   #(24+16+36+22+22+22+22),sp    ; Allocate 3 longs and 1 word
        movem.l (sp)+,a0-a6/d0-d7
        rts

;;; Parameters
;;; a6 - fx structure
fx_loop:
        movem.l a0-a6/d0-d7,-(sp)

        ;; Animation Loop
        jsr     get_hz_200      ; into d0
        move.l  d0,d6           ; hz_200 is in d6
        add.l   #FX_HZ200_PERIOD,d6

        move.w  #0,d7           ; frame counter is in d7
        .loop:
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
;;;  0(a6) - address of animation structure
;;;  4(a6) - address of picture structure
;;;  8(a6) - address of pic_offset controller
;;; 12(a6) - address of pic_ratio controller
;;; 16(a6) - address of wave_offset controller
;;; 20(a6) - address of wave_ratio controller
fx_next_frame
        movem.l d0-d7/a0-a6,-(sp)
        move.l  a6,a5           ; fx structure in a5
        move.l  4(a5),a4        ; picture structure in a4

        move.l  8(a5),a6
        jsr     process_controller ; pic_offset controller
        move.l  12(a5),a6
        jsr     process_controller ; pic_ratio controller
        move.l  16(a5),a6
        jsr     process_controller ; wave_offset controller
        move.l  20(a5),a6
        jsr     process_controller ; wave_ratio controller

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
        move.l  18(a6),a1       ; a1 - address of lookup table
        move.w  (a1,d1),2(a0)   ; words table

        .end:
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

;;; Picture structure
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
        sub.w   #(2*220),sp             ; 200 words to computes lines stretching
        movem.l (a6),d1-d4/a0-a4        ; retrieve registers values from a6

        ;; Pic stretching phase
        ;; d3,a3,d5 as X,Y,Z for ratio computation
        ;; d1 is picture displacement (initially offset)

        ;; Compute picture offset compensated for stretching ratio
        move.w  #(100+190),d0   ; Also compensate for the headrooms (for wave)
        sub.w   d3,d0
        asl.w   #4,d0           ; *16
        move.w  d0,d7
        asl.w   #2,d0           ; *64
        add.w   d7,d0           ; *80
        add.w   d0,d1           ; Add compensation do provided offset

        ;; Offset mod 200
        bpl     .offset_positive
        add.w   #(80*200),d1
        .offset_positive:
        cmp.w   #(80*200),d1
        blt     .offset_mod200
        sub.w   #(80*200),d1
        .offset_mod200:

        ;; Initialize stretching loop
        move.w  a3,d5                   ; pic_Z - pic ratio computation
        subq.w  #1,d5                   ; minus 1
        move.w  #0,d0           ; Our memory counter
        .stretch_loop:
        move.w  d1,(sp,d0)

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
        blt     .picline_mod200
        sub.w   #(200*80),d1
        .picline_mod200:

        add.w   #2,d0           ; words
        cmp.w   #(2*220),d0
        blt     .stretch_loop

        ;; Wave FX and copying picture lines in screen memory

        ;; d4,a4,d5 as X,Y,Z for ratio computation
        ;; d2 is wave displacement (initially offset)
        move.w  a4,d5                   ; sin_Z - sin ratio computation
        subq.w  #1,d5                   ; minus 1
        lea.l   (2*10)(sp),a5
        move.w  #0,d0                   ; index in stretched lines
.picdisplay_loop:
        ;; a0 - phy_line_addr is the address of the current physical line
        ;; a1 - pic_base_addr base address of picture to display
        ;; a2 - wave_base_addr base address of wave table

        move.w  (a2,d2),d1      ; can be negative
        add.w   d0,d1           ; index modified by wave
        move.w  (a5,d1),d1      ; line offset in d1 (multiple of 80)

        ;; Display a line
        REPT 20
        move.l  REPTN*4(a1,d1),REPTN*8(a0)
        ENDR

        ;; Compute next sintable offset (considering sin table stretch ratio)
        ;; Substract sin_X from sin_Z
        sub.w   d4,d5
        ;; As long as sin_Z<0 increase it by sin_Y and increase sin_table_offset
        bpl     .sinz_positive
.sinz_negative:
        add.w   #2,d2
        add.w   a4,d5
        bmi     .sinz_negative
.sinz_positive:
        and.w   #$01ff,d2       ; d2 % 512

        add.w   #160,a0         ; next video buffer line (a4)
        add.w   #2,d0
        cmp.l   #(2*200),d0      ; Loop until end of display areay is reached
        blt     .picdisplay_loop

        add.w   #(2*220),sp
        movem.l (sp)+,a0-a6/d0-d7       ; restore registers from stack
        rts


        section wave_table,data
wave_table:
        dc.w $0000, $0000, $0000, $0002, $0002, $0002, $0002, $0004
        dc.w $0004, $0004, $0004, $0006, $0006, $0006, $0006, $0008
        dc.w $0008, $0008, $0008, $0008, $000a, $000a, $000a, $000a
        dc.w $000c, $000c, $000c, $000c, $000c, $000e, $000e, $000e
        dc.w $000e, $000e, $000e, $0010, $0010, $0010, $0010, $0010
        dc.w $0010, $0010, $0012, $0012, $0012, $0012, $0012, $0012
        dc.w $0012, $0012, $0012, $0012, $0014, $0014, $0014, $0014
        dc.w $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014
        dc.w $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014
        dc.w $0014, $0014, $0014, $0014, $0014, $0012, $0012, $0012
        dc.w $0012, $0012, $0012, $0012, $0012, $0012, $0012, $0010
        dc.w $0010, $0010, $0010, $0010, $0010, $0010, $000e, $000e
        dc.w $000e, $000e, $000e, $000e, $000c, $000c, $000c, $000c
        dc.w $000c, $000a, $000a, $000a, $000a, $0008, $0008, $0008
        dc.w $0008, $0008, $0006, $0006, $0006, $0006, $0004, $0004
        dc.w $0004, $0004, $0002, $0002, $0002, $0002, $0000, $0000
        dc.w $0000, $0000, $0000, $fffe, $fffe, $fffe, $fffe, $fffc
        dc.w $fffc, $fffc, $fffc, $fffa, $fffa, $fffa, $fffa, $fff8
        dc.w $fff8, $fff8, $fff8, $fff8, $fff6, $fff6, $fff6, $fff6
        dc.w $fff4, $fff4, $fff4, $fff4, $fff4, $fff2, $fff2, $fff2
        dc.w $fff2, $fff2, $fff2, $fff0, $fff0, $fff0, $fff0, $fff0
        dc.w $fff0, $fff0, $ffee, $ffee, $ffee, $ffee, $ffee, $ffee
        dc.w $ffee, $ffee, $ffee, $ffee, $ffec, $ffec, $ffec, $ffec
        dc.w $ffec, $ffec, $ffec, $ffec, $ffec, $ffec, $ffec, $ffec
        dc.w $ffec, $ffec, $ffec, $ffec, $ffec, $ffec, $ffec, $ffec
        dc.w $ffec, $ffec, $ffec, $ffec, $ffec, $ffee, $ffee, $ffee
        dc.w $ffee, $ffee, $ffee, $ffee, $ffee, $ffee, $ffee, $fff0
        dc.w $fff0, $fff0, $fff0, $fff0, $fff0, $fff0, $fff2, $fff2
        dc.w $fff2, $fff2, $fff2, $fff2, $fff4, $fff4, $fff4, $fff4
        dc.w $fff4, $fff6, $fff6, $fff6, $fff6, $fff8, $fff8, $fff8
        dc.w $fff8, $fff8, $fffa, $fffa, $fffa, $fffa, $fffc, $fffc
        dc.w $fffc, $fffc, $fffe, $fffe, $fffe, $fffe, $0000, $0000

wave_ratio_table:
pic_ratio_table:
        dc.w $0064, $0062, $0060, $005d, $005b, $0059, $0057, $0055
        dc.w $0053, $0051, $004f, $004d, $004a, $0048, $0046, $0044
        dc.w $0043, $0041, $003f, $003d, $003b, $0039, $0037, $0036
        dc.w $0034, $0032, $0031, $002f, $002e, $002c, $002b, $0029
        dc.w $0028, $0026, $0025, $0024, $0023, $0021, $0020, $001f
        dc.w $001e, $001d, $001c, $001b, $001a, $001a, $0019, $0018
        dc.w $0018, $0017, $0016, $0016, $0016, $0015, $0015, $0015
        dc.w $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014
        dc.w $0015, $0015, $0015, $0016, $0016, $0016, $0017, $0018
        dc.w $0018, $0019, $001a, $001a, $001b, $001c, $001d, $001e
        dc.w $001f, $0020, $0021, $0023, $0024, $0025, $0026, $0028
        dc.w $0029, $002b, $002c, $002e, $002f, $0031, $0032, $0034
        dc.w $0036, $0038, $0039, $003b, $003d, $003f, $0041, $0043
        dc.w $0045, $0047, $0049, $004b, $004d, $004f, $0051, $0053
        dc.w $0055, $0057, $0059, $005b, $005e, $0060, $0062, $0064
        dc.w $0066, $0069, $006b, $006d, $006f, $0071, $0074, $0076
        dc.w $0078, $007a, $007c, $007f, $0081, $0083, $0085, $0087
        dc.w $0089, $008b, $008d, $008f, $0092, $0094, $0096, $0098
        dc.w $0099, $009b, $009d, $009f, $00a1, $00a3, $00a5, $00a6
        dc.w $00a8, $00aa, $00ab, $00ad, $00ae, $00b0, $00b1, $00b3
        dc.w $00b4, $00b6, $00b7, $00b8, $00b9, $00bb, $00bc, $00bd
        dc.w $00be, $00bf, $00c0, $00c1, $00c2, $00c2, $00c3, $00c4
        dc.w $00c4, $00c5, $00c6, $00c6, $00c6, $00c7, $00c7, $00c7
        dc.w $00c8, $00c8, $00c8, $00c8, $00c8, $00c8, $00c8, $00c8
        dc.w $00c7, $00c7, $00c7, $00c6, $00c6, $00c6, $00c5, $00c4
        dc.w $00c4, $00c3, $00c2, $00c2, $00c1, $00c0, $00bf, $00be
        dc.w $00bd, $00bc, $00bb, $00b9, $00b8, $00b7, $00b6, $00b4
        dc.w $00b3, $00b1, $00b0, $00ae, $00ad, $00ab, $00aa, $00a8
        dc.w $00a6, $00a4, $00a3, $00a1, $009f, $009d, $009b, $0099
        dc.w $0097, $0095, $0093, $0091, $008f, $008d, $008b, $0089
        dc.w $0087, $0085, $0083, $0081, $007e, $007c, $007a, $0078
        dc.w $0076, $0073, $0071, $006f, $006d, $006b, $0068, $0066
