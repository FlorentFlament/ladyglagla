;;; Picture stretching effect
        xdef fx_wave_animation
        xdef fx_next_frame
        xdef fx_data_1_fx_structure
        xdef fx_data_2_fx_structure
        xdef fx_data_3_fx_structure
        xdef fx_data_4_fx_structure

        xref beat_cnt
        xref get_hz_200
        xref set_palette
        xref spinlock_hz200_simple
        xref clear_screen

        ;; Number of hz_200 units (200th of seconds) per frame
        ;; 4 200th of seconds per frame for 50 FPS
        ;; 5 for 40 FPS
        ;; 6 for 33 FPS
        ;; 8 for 25 FPS
FX_HZ200_PERIOD=5
ANIMATION_HZ200_PERIOD=25       ; 1 image every 25 hz200 i.e 8 FPS

;;; Parameters:
;;; a3 - fx_structure address
;;; a4 - physical screen base address
;;; a5 - animation address
;;; a6 - animation sequence
;;; d7 - beat count to wait for
fx_wave_animation:
        movem.l d0-d7/a0-a6,-(sp)

        ;; set palette
        move.l  a3,a0
        move.l  (a5),a3
        jsr     set_palette
        jsr     clear_screen

        ;; Initialize fx structures before calling main fx loop
        jsr     get_hz_200
        add.l   #ANIMATION_HZ200_PERIOD,d0
        move.l  d0,40(a0)
        move.l  a6,48(a0)
        move.l  a5,52(a0)
        move.l  a4,72(a0)

        ;; Move to main fx_loop
        move.l  a0,a6
        move.w  d7,d5
        jsr fx_loop             ; with fx structure in a6

        ;; release allocated structures
        movem.l (sp)+,d0-d7/a0-a6
        rts

;;; Parameters
;;; a6 - fx structure
;;; d5 - beat count to wait for
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
        cmp.w   beat_cnt,d5
        bgt     .loop

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

;;; Requires:
;;; - d7.w - contains the frame counter
;;; - a6.l - an FX structure - 40 bytes long (10*4)
;;;      0(a6) - address of animation structure
;;;      4(a6) - address of picture structure
;;;      8(a6) - address of pic_offset controller
;;;     12(a6) - address of pic_ratio controller
;;;     16(a6) - address of wave_offset controller
;;;     20(a6) - address of wave_ratio controller
;;;     24(a6) - address of pic_offset meta
;;;     28(a6) - address of pic_ratio meta
;;;     32(a6) - address of wave_offset meta
;;;     36(a6) - address of wave_ratio meta
fx_next_frame
        movem.l d0-d7/a0-a6,-(sp)
        move.l  a6,a5           ; fx structure in a5
        move.l  4(a5),a4        ; picture structure in a4

        move.l  24(a5),a6
        jsr     process_meta ; pic_ratio meta
        move.l  28(a5),a6
        jsr     process_meta ; pic_ratio meta
        move.l  32(a5),a6
        jsr     process_meta ; pic_ratio meta
        move.l  36(a5),a6
        jsr     process_meta ; pic_ratio meta
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

;;; d7 - frame counter
;;; a6 - meta structure
;;;      0(a6) - 0/1 inactive/active
;;;      2(a6) - sequence table
;;;      6(a6) - parameter to control
process_meta:
        movem.l d0-d7/a0-a6,-(sp)
        cmp.w   #0,(a6)
        beq     .end

        lsr     #3,d7 ; 40 FPS /8 -> 5 meta keys per second
        asl     #1,d7 ; indexing words (multiple of 2)
        move.l  2(a6),a0 ; address of sequence table
        move.l  6(a6),a1 ; address of parameter to control
        move.w  (a0,d7),(a1)

        .end:
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
        movem.l d0-d7/a0-a6,-(sp)
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
        movem.l (sp)+,d0-d7/a0-a6
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
        cmp.w   #(2*200),d0      ; Loop until end of display areay is reached
        blt     .picdisplay_loop

        add.w   #(2*220),sp
        movem.l (sp)+,a0-a6/d0-d7       ; restore registers from stack
        rts


        section data

fx_data_1_fx_structure:
        dc.l    fx_data_1_animation_structure
        dc.l    fx_data_1_picture_structure
        dc.l    fx_data_1_pic_offset_controller
        dc.l    fx_data_1_pic_ratio_controller
        dc.l    fx_data_1_wave_offset_controller
        dc.l    fx_data_1_wave_ratio_controller
        dc.l    fx_data_1_pic_offset_meta
        dc.l    fx_data_1_pic_ratio_meta
        dc.l    fx_data_1_wave_offset_meta
        dc.l    fx_data_1_wave_ratio_meta

fx_data_1_animation_structure:
        dc.l    0 ; time of next animation image - offste +40
        dc.l    0 ; index of current image in sequence table
        dc.l    0 ; address of images sequence table - offset +48
        dc.l    0 ; address of images pointers - offset +52

fx_data_1_picture_structure:
fx_data_1_pic_offset:   dc.l    0       ; pic_offset
fx_data_1_wave_offset:  dc.l    0       ; wave_offset
fx_data_1_pic_ratio:    dc.l    90      ; pic_X - pic_ratio
fx_data_1_wave_ratio    dc.l    1       ; wav_X - wave_ratio
fx_data_1_phy_screen:   dc.l    0       ; physical screen address - offset +72
        dc.l    0             ; address of picture to display
        dc.l    wave_table    ; wave table address
        dc.l    100           ; pic_Y
        dc.l    100           ; wav_Y

fx_data_1_pic_offset_controller:
        dc.w    0             ; (0,1,2) inactive/linear/table
        dc.w    2             ; Linear step / 2 when word Table
        dc.w    0             ; Current value / Table index
        dc.w    2*256         ; linear/table_index modulus
fx_data_1_pic_offset_X: dc.w    100     ; X - of X/Y speed factor
        dc.w    100           ; Y - of X/Y speed factor
        dc.w    0             ; Z - of speed factor
        dc.l    fx_data_1_pic_offset    ; Address of parameter to control
        dc.l    pic_offset_table        ; Table address (if any)

fx_data_1_pic_offset_meta:
        ;; pic_offset meta contoller
        dc.w    0             ; 0/1 inactive/active
        dc.l    0             ; sequence table
        dc.l    fx_data_1_pic_offset_X  ; parameter to control

fx_data_1_pic_ratio_controller:
        dc.w    2             ; (0,1,2) inactive/linear/table
        dc.w    2*1           ; Linear step / 2 when word Table
        dc.w    0             ; Current value / Table index
        dc.w    2*256         ; linear/table_index modulus
fx_data_1_pic_ratio_X:  dc.w    100     ; X - of X/Y speed factor
        dc.w    100           ; Y - of X/Y speed factor
        dc.w    0             ; Z - of speed factor
        dc.l    fx_data_1_pic_ratio     ; Address of parameter to control
        dc.l    pic_ratio_table         ; Table address (if any)

fx_data_1_pic_ratio_meta:
        dc.w    1             ; 0/1 inactive/active
        dc.l    fx_1_pic_ratio_sequence ; sequence table
        dc.l    fx_data_1_pic_ratio_X   ; parameter to control

fx_data_1_wave_offset_controller:
        dc.w    0             ; (0,1,2) inactive/linear/table
        dc.w    2*8           ; Linear step / 2 when word Table
        dc.w    0             ; Current value / Table index
        dc.w    2*256         ; linear/table_index modulus
fx_data_1_wave_offset_X: dc.w   100     ; X - of X/Y speed factor
        dc.w    100           ; Y - of X/Y speed factor
        dc.w    0             ; Z - of speed factor
        dc.l    fx_data_1_wave_offset ; Address of parameter to control
        dc.l    0             ; Table address (if any)

fx_data_1_wave_offset_meta:
        dc.w    0             ; 0/1 inactive/active
        dc.l    0             ; sequence table
        dc.l    fx_data_1_wave_offset_X ; Address of parameter to control

fx_data_1_wave_ratio_controller:
        dc.w    0             ; (0,1,2) inactive/linear/table
        dc.w    2*1           ; Linear step / 2 when word Table
        dc.w    0             ; Current value / Table index
        dc.w    2*256         ; linear/table_index modulus
fx_data_1_wave_ratio_X: dc.w    100     ; X - of X/Y speed factor
        dc.w    100           ; Y - of X/Y speed factor
        dc.w    0             ; Z - of speed factor
        dc.l    fx_data_1_wave_ratio    ; Address of parameter to control
        dc.l    wave_ratio_table        ; Table address (if any)

fx_data_1_wave_ratio_meta
        dc.w    0             ; 0/1 inactive/active
        dc.l    0             ; sequence table
        dc.l    fx_data_1_wave_ratio_X  ; Address of parameter to control


fx_data_2_fx_structure:
        dc.l    fx_data_2_animation_structure
        dc.l    fx_data_2_picture_structure
        dc.l    fx_data_2_pic_offset_controller
        dc.l    fx_data_2_pic_ratio_controller
        dc.l    fx_data_2_wave_offset_controller
        dc.l    fx_data_2_wave_ratio_controller
        dc.l    fx_data_2_pic_offset_meta
        dc.l    fx_data_2_pic_ratio_meta
        dc.l    fx_data_2_wave_offset_meta
        dc.l    fx_data_2_wave_ratio_meta

fx_data_2_animation_structure:
        dc.l    0 ; time of next animation image - offste +40
        dc.l    0 ; index of current image in sequence table
        dc.l    0 ; address of images sequence table - offset +48
        dc.l    0 ; address of images pointers - offset +52

fx_data_2_picture_structure:
fx_data_2_pic_offset:   dc.l    0       ; pic_offset
fx_data_2_wave_offset:  dc.l    0       ; wave_offset
fx_data_2_pic_ratio:    dc.l    90      ; pic_X - pic_ratio
fx_data_2_wave_ratio    dc.l    1       ; wav_X - wave_ratio
fx_data_2_phy_screen:   dc.l    0       ; physical screen address - offset +72
        dc.l    0             ; address of picture to display
        dc.l    wave_table    ; wave table address
        dc.l    100           ; pic_Y
        dc.l    100           ; wav_Y

fx_data_2_pic_offset_controller:
        dc.w    0             ; (0,1,2) inactive/linear/table
        dc.w    2             ; Linear step / 2 when word Table
        dc.w    0             ; Current value / Table index
        dc.w    2*256         ; linear/table_index modulus
fx_data_2_pic_offset_X: dc.w    100     ; X - of X/Y speed factor
        dc.w    100           ; Y - of X/Y speed factor
        dc.w    0             ; Z - of speed factor
        dc.l    fx_data_2_pic_offset    ; Address of parameter to control
        dc.l    pic_offset_table        ; Table address (if any)

fx_data_2_pic_offset_meta:
        ;; pic_offset meta contoller
        dc.w    0             ; 0/1 inactive/active
        dc.l    0             ; sequence table
        dc.l    fx_data_2_pic_offset_X  ; parameter to control

fx_data_2_pic_ratio_controller:
        dc.w    0             ; (0,1,2) inactive/linear/table
        dc.w    2*1           ; Linear step / 2 when word Table
        dc.w    0             ; Current value / Table index
        dc.w    2*256         ; linear/table_index modulus
fx_data_2_pic_ratio_X:  dc.w    100     ; X - of X/Y speed factor
        dc.w    100           ; Y - of X/Y speed factor
        dc.w    0             ; Z - of speed factor
        dc.l    fx_data_2_pic_ratio     ; Address of parameter to control
        dc.l    pic_ratio_table         ; Table address (if any)

fx_data_2_pic_ratio_meta:
        dc.w    0             ; 0/1 inactive/active
        dc.l    0             ; sequence table
        dc.l    fx_data_2_pic_ratio_X   ; parameter to control

fx_data_2_wave_offset_controller:
        dc.w    1             ; (0,1,2) inactive/linear/table
        dc.w    2*1           ; Linear step / 2 when word Table
        dc.w    0             ; Current value / Table index
        dc.w    2*256         ; linear/table_index modulus
fx_data_2_wave_offset_X: dc.w   800     ; X - of X/Y speed factor
        dc.w    100           ; Y - of X/Y speed factor
        dc.w    0             ; Z - of speed factor
        dc.l    fx_data_2_wave_offset ; Address of parameter to control
        dc.l    0             ; Table address (if any)

fx_data_2_wave_offset_meta:
        dc.w    1             ; 0/1 inactive/active
        dc.l    fx_2_wave_offset_sequence ; sequence table
        dc.l    fx_data_2_wave_offset_X ; Address of parameter to control

fx_data_2_wave_ratio_controller:
        dc.w    0             ; (0,1,2) inactive/linear/table
        dc.w    2*1           ; Linear step / 2 when word Table
        dc.w    0             ; Current value / Table index
        dc.w    2*256         ; linear/table_index modulus
fx_data_2_wave_ratio_X: dc.w    200     ; X - of X/Y speed factor
        dc.w    100           ; Y - of X/Y speed factor
        dc.w    0             ; Z - of speed factor
        dc.l    fx_data_2_wave_ratio    ; Address of parameter to control
        dc.l    wave_ratio_table        ; Table address (if any)

fx_data_2_wave_ratio_meta
        dc.w    1             ; 0/1 inactive/active
        dc.l    fx_2_wave_ratio_sequence ; sequence table
        dc.l    fx_data_2_wave_ratio+2  ; Address of parameter to control


fx_data_3_fx_structure:
        dc.l    fx_data_3_animation_structure
        dc.l    fx_data_3_picture_structure
        dc.l    fx_data_3_pic_offset_controller
        dc.l    fx_data_3_pic_ratio_controller
        dc.l    fx_data_3_wave_offset_controller
        dc.l    fx_data_3_wave_ratio_controller
        dc.l    fx_data_3_pic_offset_meta
        dc.l    fx_data_3_pic_ratio_meta
        dc.l    fx_data_3_wave_offset_meta
        dc.l    fx_data_3_wave_ratio_meta

fx_data_3_animation_structure:
        dc.l    0 ; time of next animation image - offste +40
        dc.l    0 ; index of current image in sequence table
        dc.l    0 ; address of images sequence table - offset +48
        dc.l    0 ; address of images pointers - offset +52

fx_data_3_picture_structure:
fx_data_3_pic_offset:   dc.l    0       ; pic_offset
fx_data_3_wave_offset:  dc.l    0       ; wave_offset
fx_data_3_pic_ratio:    dc.l    90      ; pic_X - pic_ratio
fx_data_3_wave_ratio    dc.l    1       ; wav_X - wave_ratio
fx_data_3_phy_screen:   dc.l    0       ; physical screen address - offset +72
        dc.l    0             ; address of picture to display
        dc.l    wave_table    ; wave table address
        dc.l    100           ; pic_Y
        dc.l    100           ; wav_Y

fx_data_3_pic_offset_controller:
        dc.w    2             ; (0,1,2) inactive/linear/table
        dc.w    2             ; Linear step / 2 when word Table
        dc.w    0             ; Current value / Table index
        dc.w    2*256         ; linear/table_index modulus
fx_data_3_pic_offset_X: dc.w    150     ; X - of X/Y speed factor
        dc.w    100           ; Y - of X/Y speed factor
        dc.w    0             ; Z - of speed factor
        dc.l    fx_data_3_pic_offset    ; Address of parameter to control
        dc.l    pic_offset_table        ; Table address (if any)

fx_data_3_pic_offset_meta:
        ;; pic_offset meta contoller
        dc.w    1             ; 0/1 inactive/active
        dc.l    fx_3_pic_offset_sequence        ; sequence table
        dc.l    fx_data_3_pic_offset_X  ; parameter to control

fx_data_3_pic_ratio_controller:
        dc.w    2             ; (0,1,2) inactive/linear/table
        dc.w    2*1           ; Linear step / 2 when word Table
        dc.w    0             ; Current value / Table index
        dc.w    2*256         ; linear/table_index modulus
fx_data_3_pic_ratio_X:  dc.w    400     ; X - of X/Y speed factor
        dc.w    100           ; Y - of X/Y speed factor
        dc.w    0             ; Z - of speed factor
        dc.l    fx_data_3_pic_ratio     ; Address of parameter to control
        dc.l    pic_ratio_table         ; Table address (if any)

fx_data_3_pic_ratio_meta:
        dc.w    1             ; 0/1 inactive/active
        dc.l    fx_3_pic_ratio_sequence        ; sequence table
        dc.l    fx_data_3_pic_ratio_X   ; parameter to control

fx_data_3_wave_offset_controller:
        dc.w    0             ; (0,1,2) inactive/linear/table
        dc.w    2*1           ; Linear step / 2 when word Table
        dc.w    0             ; Current value / Table index
        dc.w    2*256         ; linear/table_index modulus
fx_data_3_wave_offset_X: dc.w   800     ; X - of X/Y speed factor
        dc.w    100           ; Y - of X/Y speed factor
        dc.w    0             ; Z - of speed factor
        dc.l    fx_data_3_wave_offset ; Address of parameter to control
        dc.l    0             ; Table address (if any)

fx_data_3_wave_offset_meta:
        dc.w    0             ; 0/1 inactive/active
        dc.l    0             ; sequence table
        dc.l    fx_data_3_wave_offset_X ; Address of parameter to control

fx_data_3_wave_ratio_controller:
        dc.w    0             ; (0,1,2) inactive/linear/table
        dc.w    2*1           ; Linear step / 2 when word Table
        dc.w    0             ; Current value / Table index
        dc.w    2*256         ; linear/table_index modulus
fx_data_3_wave_ratio_X: dc.w    200     ; X - of X/Y speed factor
        dc.w    100           ; Y - of X/Y speed factor
        dc.w    0             ; Z - of speed factor
        dc.l    fx_data_3_wave_ratio    ; Address of parameter to control
        dc.l    wave_ratio_table        ; Table address (if any)

fx_data_3_wave_ratio_meta
        dc.w    0             ; 0/1 inactive/active
        dc.l    0             ; sequence table
        dc.l    fx_data_3_wave_ratio+2  ; Address of parameter to control


fx_data_4_fx_structure:
        dc.l    fx_data_4_animation_structure
        dc.l    fx_data_4_picture_structure
        dc.l    fx_data_4_pic_offset_controller
        dc.l    fx_data_4_pic_ratio_controller
        dc.l    fx_data_4_wave_offset_controller
        dc.l    fx_data_4_wave_ratio_controller
        dc.l    fx_data_4_pic_offset_meta
        dc.l    fx_data_4_pic_ratio_meta
        dc.l    fx_data_4_wave_offset_meta
        dc.l    fx_data_4_wave_ratio_meta

fx_data_4_animation_structure:
        dc.l    0 ; time of next animation image - offste +40
        dc.l    0 ; index of current image in sequence table
        dc.l    0 ; address of images sequence table - offset +48
        dc.l    0 ; address of images pointers - offset +52

fx_data_4_picture_structure:
fx_data_4_pic_offset:   dc.l    0       ; pic_offset
fx_data_4_wave_offset:  dc.l    0       ; wave_offset
fx_data_4_pic_ratio:    dc.l    90      ; pic_X - pic_ratio
fx_data_4_wave_ratio    dc.l    1       ; wav_X - wave_ratio
fx_data_4_phy_screen:   dc.l    0       ; physical screen address - offset +72
        dc.l    0             ; address of picture to display
        dc.l    wave_table    ; wave table address
        dc.l    100           ; pic_Y
        dc.l    100           ; wav_Y

fx_data_4_pic_offset_controller:
        dc.w    0             ; (0,1,2) inactive/linear/table
        dc.w    2             ; Linear step / 2 when word Table
        dc.w    0             ; Current value / Table index
        dc.w    2*256         ; linear/table_index modulus
fx_data_4_pic_offset_X: dc.w    100     ; X - of X/Y speed factor
        dc.w    100           ; Y - of X/Y speed factor
        dc.w    0             ; Z - of speed factor
        dc.l    fx_data_4_pic_offset    ; Address of parameter to control
        dc.l    pic_offset_table        ; Table address (if any)

fx_data_4_pic_offset_meta:
        ;; pic_offset meta contoller
        dc.w    0             ; 0/1 inactive/active
        dc.l    0             ; sequence table
        dc.l    fx_data_4_pic_offset_X  ; parameter to control

fx_data_4_pic_ratio_controller:
        dc.w    2             ; (0,1,2) inactive/linear/table
        dc.w    2*1           ; Linear step / 2 when word Table
        dc.w    0             ; Current value / Table index
        dc.w    2*256         ; linear/table_index modulus
fx_data_4_pic_ratio_X:  dc.w    0       ; X - of X/Y speed factor
        dc.w    100           ; Y - of X/Y speed factor
        dc.w    0             ; Z - of speed factor
        dc.l    fx_data_4_pic_ratio     ; Address of parameter to control
        dc.l    pic_ratio_table         ; Table address (if any)

fx_data_4_pic_ratio_meta:
        dc.w    1             ; 0/1 inactive/active
        dc.l    fx_4_pic_ratio_sequence ; sequence table
        dc.l    fx_data_4_pic_ratio_X   ; parameter to control

fx_data_4_wave_offset_controller:
        dc.w    1             ; (0,1,2) inactive/linear/table
        dc.w    2             ; Linear step / 2 when word Table
        dc.w    0             ; Current value / Table index
        dc.w    2*256         ; linear/table_index modulus
fx_data_4_wave_offset_X: dc.w   800     ; X - of X/Y speed factor
        dc.w    100           ; Y - of X/Y speed factor
        dc.w    0             ; Z - of speed factor
        dc.l    fx_data_4_wave_offset ; Address of parameter to control
        dc.l    0             ; Table address (if any)

fx_data_4_wave_offset_meta:
        dc.w    1             ; 0/1 inactive/active
        dc.l    fx_4_wave_offset_sequence ; sequence table
        dc.l    fx_data_4_wave_offset_X ; Address of parameter to control

fx_data_4_wave_ratio_controller:
        dc.w    0             ; (0,1,2) inactive/linear/table
        dc.w    2*1           ; Linear step / 2 when word Table
        dc.w    0             ; Current value / Table index
        dc.w    2*256         ; linear/table_index modulus
fx_data_4_wave_ratio_X: dc.w    200     ; X - of X/Y speed factor
        dc.w    100           ; Y - of X/Y speed factor
        dc.w    0             ; Z - of speed factor
        dc.l    fx_data_4_wave_ratio    ; Address of parameter to control
        dc.l    wave_ratio_table        ; Table address (if any)

fx_data_4_wave_ratio_meta
        dc.w    1             ; 0/1 inactive/active
        dc.l    fx_4_wave_ratio_sequence ; sequence table
        dc.l    fx_data_4_wave_ratio+2  ; Address of parameter to control


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

pic_offset_table:
        dc.w $0000, $0050, $00a0, $0140, $0190, $01e0, $0230, $02d0
        dc.w $0320, $0370, $03c0, $0410, $04b0, $0500, $0550, $05a0
        dc.w $05f0, $0640, $0690, $06e0, $0780, $07d0, $0820, $0870
        dc.w $08c0, $0910, $0960, $09b0, $0a00, $0a50, $0aa0, $0aa0
        dc.w $0af0, $0b40, $0b90, $0be0, $0c30, $0c30, $0c80, $0cd0
        dc.w $0d20, $0d20, $0d70, $0dc0, $0dc0, $0e10, $0e10, $0e60
        dc.w $0e60, $0eb0, $0eb0, $0eb0, $0f00, $0f00, $0f50, $0f50
        dc.w $0f50, $0f50, $0f50, $0fa0, $0fa0, $0fa0, $0fa0, $0fa0
        dc.w $0fa0, $0fa0, $0fa0, $0fa0, $0fa0, $0fa0, $0f50, $0f50
        dc.w $0f50, $0f50, $0f50, $0f00, $0f00, $0eb0, $0eb0, $0eb0
        dc.w $0e60, $0e60, $0e10, $0e10, $0dc0, $0dc0, $0d70, $0d20
        dc.w $0d20, $0cd0, $0c80, $0c30, $0c30, $0be0, $0b90, $0b40
        dc.w $0af0, $0aa0, $0aa0, $0a50, $0a00, $09b0, $0960, $0910
        dc.w $08c0, $0870, $0820, $07d0, $0780, $06e0, $0690, $0640
        dc.w $05f0, $05a0, $0550, $0500, $04b0, $0410, $03c0, $0370
        dc.w $0320, $02d0, $0230, $01e0, $0190, $0140, $00a0, $0050
        dc.w $0000, $ffb0, $ff60, $fec0, $fe70, $fe20, $fdd0, $fd30
        dc.w $fce0, $fc90, $fc40, $fbf0, $fb50, $fb00, $fab0, $fa60
        dc.w $fa10, $f9c0, $f970, $f920, $f880, $f830, $f7e0, $f790
        dc.w $f740, $f6f0, $f6a0, $f650, $f600, $f5b0, $f560, $f560
        dc.w $f510, $f4c0, $f470, $f420, $f3d0, $f3d0, $f380, $f330
        dc.w $f2e0, $f2e0, $f290, $f240, $f240, $f1f0, $f1f0, $f1a0
        dc.w $f1a0, $f150, $f150, $f150, $f100, $f100, $f0b0, $f0b0
        dc.w $f0b0, $f0b0, $f0b0, $f060, $f060, $f060, $f060, $f060
        dc.w $f060, $f060, $f060, $f060, $f060, $f060, $f0b0, $f0b0
        dc.w $f0b0, $f0b0, $f0b0, $f100, $f100, $f150, $f150, $f150
        dc.w $f1a0, $f1a0, $f1f0, $f1f0, $f240, $f240, $f290, $f2e0
        dc.w $f2e0, $f330, $f380, $f3d0, $f3d0, $f420, $f470, $f4c0
        dc.w $f510, $f560, $f560, $f5b0, $f600, $f650, $f6a0, $f6f0
        dc.w $f740, $f790, $f7e0, $f830, $f880, $f920, $f970, $f9c0
        dc.w $fa10, $fa60, $fab0, $fb00, $fb50, $fbf0, $fc40, $fc90
        dc.w $fce0, $fd30, $fdd0, $fe20, $fe70, $fec0, $ff60, $ffb0

fx_1_pic_ratio_sequence:
        dc.w $0032, $003a, $0042, $004a, $0052, $005a, $0062, $006a
        dc.w $0072, $007a, $0082, $008a, $0092, $009a, $00a2, $00aa
        dc.w $00b2, $00ba, $00c2, $00ca, $00d2, $00da, $00e2, $00ea
        dc.w $00f2, $00fa, $0102, $010a, $0112, $011a, $0122, $012a
        dc.w $0132, $013a, $0142, $014a, $0152, $015a, $0162, $016a
        dc.w $0172, $017a, $0182, $018a, $0192, $019a, $01a2, $01aa
        dc.w $01b2, $01ba, $01c2, $01ca, $01d2, $01da, $01e2, $01ea
        dc.w $01f2, $01f4, $01f4, $01f4, $01f4, $01f4, $01f4, $01f4

fx_2_wave_ratio_sequence:
        dc.w $0000, $0006, $000c, $0012, $0018, $001e, $0024, $002a
        dc.w $0030, $0036, $003c, $0042, $0048, $004e, $0054, $005a
        dc.w $0060, $0066, $006c, $0072, $0078, $007e, $0084, $008a
        dc.w $0090, $0096, $009c, $00a2, $00a8, $00ae, $00b4, $00ba
        dc.w $00c0, $00c6, $00c8, $00c8, $00c8, $00c8, $00c8, $00c8
        dc.w $00c8, $00c8, $00c8, $00c8, $00c8, $00c8, $00c8, $00c8
        dc.w $00c8, $00c8, $00c8, $00c8, $00c8, $00c8, $00c8, $00c8
        dc.w $00c8, $00c8, $00c8, $00c8, $00c8, $00c8, $00c8, $00c8

fx_2_wave_offset_sequence:
        dc.w $0000, $0032, $0064, $0096, $00c8, $00fa, $012c, $015e
        dc.w $0190, $01c2, $01f4, $0226, $0258, $028a, $02bc, $02ee
        dc.w $0320, $0320, $0320, $0320, $0320, $0320, $0320, $0320
        dc.w $0320, $0320, $0320, $0320, $0320, $0320, $0320, $0320
        dc.w $0320, $030a, $02f4, $02de, $02c8, $02b2, $029c, $0286
        dc.w $0270, $025a, $0244, $022e, $0218, $0202, $01ec, $01d6
        dc.w $01c0, $01aa, $0194, $017e, $0168, $0152, $013c, $0126
        dc.w $0110, $00fa, $00e4, $00ce, $00b8, $00a2, $008c, $0076

fx_3_pic_offset_sequence
        dc.w $0000, $0000, $0000, $0000, $0000, $0000, $0008, $0010
        dc.w $0018, $0020, $0028, $0030, $0038, $0040, $0048, $0050
        dc.w $0058, $0060, $0068, $0070, $0078, $0080, $0088, $0090
        dc.w $0096, $0096, $0096, $0096, $0096, $0096, $0096, $0096
        dc.w $0096, $0096, $0096, $0096, $0096, $0096, $0096, $0096
        dc.w $0096, $0096, $0096, $0096, $0096, $0096, $0096, $0096
        dc.w $0096, $0096, $0096, $0096, $0096, $0096, $0096, $0096
        dc.w $0096, $0096, $0096, $0096, $0096, $0096, $0096, $0096

fx_3_pic_ratio_sequence:
        dc.w $0190, $0190, $0190, $0190, $0190, $0190, $0190, $0190
        dc.w $0190, $0190, $0190, $0190, $0190, $0190, $0190, $0190
        dc.w $0190, $0190, $0190, $0190, $0190, $0190, $0190, $0190
        dc.w $0190, $0190, $0190, $0190, $0190, $0190, $0190, $0190
        dc.w $0190, $0184, $0178, $016c, $0160, $0154, $0148, $013c
        dc.w $0130, $0124, $0118, $010c, $0100, $00f4, $00e8, $00dc
        dc.w $00d0, $00c4, $00b8, $00ac, $00a0, $0094, $0088, $007c
        dc.w $0070, $0064, $0058, $004c, $0040, $0034, $0032, $0032

fx_4_pic_ratio_sequence:
        dc.w $0000, $0000, $0000, $0000, $0000, $0032, $0032, $0032
        dc.w $0032, $0032, $0032, $0032, $0032, $0032, $0032, $0000
        dc.w $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
        dc.w $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
        dc.w $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
        dc.w $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014
        dc.w $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014
        dc.w $0014, $0014, $0014, $0014, $0014, $0014, $0014, $0014

fx_4_wave_offset_sequence:
        dc.w $0320, $0320, $0320, $0320, $0320, $0320, $0320, $0320
        dc.w $0320, $0320, $0320, $0320, $0320, $0320, $0320, $0320
        dc.w $0320, $0320, $0320, $0320, $0320, $02da, $0294, $024e
        dc.w $0208, $01c2, $017c, $0136, $00f0, $00aa, $0064, $0064
        dc.w $0064, $0064, $0064, $0064, $00aa, $00f0, $0136, $017c
        dc.w $01c2, $0208, $024e, $0294, $02da, $0320, $0320, $0320
        dc.w $0320, $0320, $0320, $0320, $0320, $0320, $0320, $0320
        dc.w $0320, $0320, $0320, $0320, $0320, $0320, $0320, $0320

fx_4_wave_ratio_sequence:
        dc.w $00c8, $00c8, $00c8, $00c8, $00c8, $00c8, $00c8, $00c8
        dc.w $00c8, $00c8, $00c8, $00c8, $00c8, $00c8, $00c8, $00c8
        dc.w $00c8, $00c8, $00c8, $00c8, $00c8, $00c8, $00c8, $00c8
        dc.w $00c8, $00c8, $00c8, $00c8, $00c8, $00c8, $00c8, $00b9
        dc.w $00aa, $009b, $008c, $007d, $006e, $005f, $0050, $0041
        dc.w $0032, $0032, $0032, $0032, $0032, $0032, $0032, $0032
        dc.w $0032, $0032, $0032, $0032, $0032, $0032, $0032, $0032
        dc.w $0032, $0032, $0032, $0032, $0032, $0032, $0032, $0032
