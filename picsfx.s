;;; A few pictures FXs
        xdef picscratch_fx

picscratch_fx:
        movem.l d0-d7/a0-a7,-(sp)

        ;; Get address of video memory
        move.w  #2,-(sp)        ; Physbase function call
        trap    #14             ; Call XBIOS
        addq.l  #2,sp
        move.l  d0,d6           ; Save physical screen ram base in d6

        move.w  #5000-1,d7      ; Rotate 5000 lines
        ;; Rotate one line
.line_loop:
        move.w  #17,-(sp)       ; random
        trap    #14             ; XBIOS trap
        addq.l  #2,sp
        and.l   #$00ff,d0       ; % 256

        cmp.w   #200,d0         ; % 200
        bmi     .mod_200
        sub.w   #200,d0

.mod_200:
        asl.w   #5,d0           ; *32
        move.w  d0,a0
        asl.w   #2,d0           ; *128
        add.w   d0,a0           ; *160
        add.l   d6,a0

        jsr     line_shift_left
        dbra    d7,.line_loop   ; <- bug

        movem.l (sp)+,d0-d7/a0-a7
        rts

;;; Shifts one line to the left
;;; Address of beginning of line must be passed in a0
;;; d0,d1,a1 are used
line_shift_left:
        move.w  #2,d1
.bitplanes_loop:
        move.w  #160,a1       ; 160 bytes per line
        sub.w   d1,a1
.rotate_loop:
        roxl.w  (a0,a1)         ; Rotate video block
        suba.w  #8,a1           ; Fix deplacement without updating SR flags
        move.w  a1,d0           ; Move deplacement and test negativity
        btst.l  #15,d0          ;
        beq     .rotate_loop
        addq.w  #2,d1
        cmpi.w  #8,d1
        ble     .bitplanes_loop
        rts
