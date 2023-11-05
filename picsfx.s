;;; A few pictures FXs
        xdef picscratch_fx
        xdef picgum_fx_animation

        xref wait_hz_200
        xref set_palette
        xref picstretch_d3
        xref picstretch_d4

;;; a4 - physical screen base address
;;; a5 - animation address
picgum_fx_animation:
        movem.l a1/a3/a5/d2-d5,-(sp)
        sub.l   #(256*2),sp
        move.l  sp,a1           ; storing x80 table address in a1
        sub.l   #(256*80),sp    ; Allocating RAM for padded picture

        move.l  (a5),a3         ; -> a3 palette address
        jsr     set_palette
        move.l  4(a5),a3        ; next long is address of first animation picture data

        ;; Compute x80 table
        move.w  #0,d2           ; index in table
        move.w  #0,d3           ; i*80 in d3
.table_80_loop:
        move.w  d3,(a1,d2)
        addq.w  #2,d2
        addi.w  #80,d3
        cmpi.w  #(256*2),d2
        blt     .table_80_loop

        ;; Copy padded image on the stack
        move.w  #0,d2
.copy_loop:
        move.l  (a3,d2),(sp,d2)
        addq.w  #4,d2
        cmpi    #(200*80),d2
        blt     .copy_loop
.pad_loop:
        move.l  #0,(sp,d2)
        addq.w  #4,d2
        cmpi    #(256*80),d2
        blt     .pad_loop

        move.l  sp,a5           ; sp and a5 point to padded base picture
        move.w  #600,d5
        move.w  #0,d2
.loop:
        ;; Animation parameters
        move.w  picstretch_d3,d3
        move.w  picstretch_d4,d4
        jsr     picdisplay_stretched_4colors
        addq.b  #4,d2
        dbra    d5,.loop

        add.l   #(256*80),sp
        add.l   #(256*2),sp
        movem.l (sp)+,a1/a3/a5/d2-d5
        rts

;;; Palette is set already
;;; Parameters
;;; a1 - table of multiples of 80 for [0, 256[
;;; a4 - physical screen base address
;;; a5 - base picture address
;;; d2.b - index in displacement table in [0, 256[
;;; d3,d4 - speed in the displacement table is d3/d4
;;; Uses a2,a3,a4,a6
;;; Uses d0,d1,d2,d4
picdisplay_stretched_4colors:
        movem.l a2-a6/d0/d5-d6,-(sp)     ; save d2 and a5 for further use
	move.l	a4,a6		; Save physical screen ram base in a6

        lea.l   16000(a5),a4    ; Compute end of picture in a4
        lea.l   32000(a6),a2    ; End of screen in a2

        lea.l   stretch_table,a3 ; a3 contains stretch_table address
        ;; 2 200Hz ticks for a 1 plan display loop
        ;; 3 200Hz ticks for a 2 plans display loop
        ;; 6 200Hz ticks for a 4 plans display loop

        move.w  #0,d0           ; init d0
        move.w  d4,d5           ; Using d5 as a counter
        subi.w  #1,d5
        move.b  d2,d6           ; Using d6 as offset in displacement table
.picdisplay_loop:
        ;; a5 = base picture addr
        ;; a6 = base video memory addr
        REPT 20
        move.l  REPTN*4(a5,d0),REPTN*8(a6)
        ENDR

        ;; Compute how many items to move forward in the table, i.e d3/d5
        ;; Substract d3 from d5
        sub.w   d3,d5
        ;; As long as d5 <0 increase d5 by d4 and increase d6 by 1
        bpl     .d5_positive
.d5_addloop:
        addq.b  #1,d6           ; increase line count
        add.w   d4,d5
        bmi     .d5_addloop
.d5_positive:

        add.w   #160,a6         ; write next picture line
        and.w   #$ff,d6
        move.b  (a3,d6.w),d0    ; line index on the picture in d0.b
        sub.b   d2,d0           ; Fix offset - subsctract initial displacement
        and.w   #$ff,d0         ; Now using d0.w
        asl.w   d0              ; *80
        move.w  (a1,d0.w),d0

        cmp.l   a2,a6         ; display 200 lines
        blt     .picdisplay_loop

        movem.l (sp)+,a2-a6/d0/d5-d6
        rts

picscratch_fx:
        movem.l d0-d7/a0-a7,-(sp)

        ;; Get address of video memory
	move.w	#2,-(sp)	; Physbase function call
	trap	#14		; Call XBIOS
	addq.l	#2,sp
	move.l	d0,d6		; Save physical screen ram base in d6

        move.w  #5000-1,d7      ; Rotate 5000 lines
        ;; Rotate one line
.line_loop:
	move.w	#17,-(sp)	; random
	trap	#14		; XBIOS trap
        addq.l	#2,sp
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

        section stretch_table,data
stretch_table:
	dc.b $00, $01, $03, $04, $06, $07, $09, $0a
	dc.b $0c, $0d, $0f, $10, $12, $13, $15, $16
	dc.b $18, $19, $1b, $1c, $1d, $1f, $20, $22
	dc.b $23, $25, $26, $27, $29, $2a, $2b, $2d
	dc.b $2e, $2f, $31, $32, $33, $35, $36, $37
	dc.b $39, $3a, $3b, $3c, $3e, $3f, $40, $41
	dc.b $42, $44, $45, $46, $47, $48, $49, $4b
	dc.b $4c, $4d, $4e, $4f, $50, $51, $52, $53
	dc.b $54, $55, $56, $57, $58, $59, $5a, $5b
	dc.b $5c, $5d, $5d, $5e, $5f, $60, $61, $62
	dc.b $62, $63, $64, $65, $66, $66, $67, $68
	dc.b $69, $69, $6a, $6b, $6b, $6c, $6d, $6d
	dc.b $6e, $6f, $6f, $70, $71, $71, $72, $73
	dc.b $73, $74, $74, $75, $75, $76, $77, $77
	dc.b $78, $78, $79, $79, $7a, $7a, $7b, $7b
	dc.b $7c, $7c, $7d, $7d, $7e, $7e, $7f, $7f
	dc.b $80, $81, $81, $82, $82, $83, $83, $84
	dc.b $84, $85, $85, $86, $86, $87, $87, $88
	dc.b $88, $89, $89, $8a, $8b, $8b, $8c, $8c
	dc.b $8d, $8d, $8e, $8f, $8f, $90, $91, $91
	dc.b $92, $93, $93, $94, $95, $95, $96, $97
	dc.b $97, $98, $99, $9a, $9a, $9b, $9c, $9d
	dc.b $9e, $9e, $9f, $a0, $a1, $a2, $a3, $a3
	dc.b $a4, $a5, $a6, $a7, $a8, $a9, $aa, $ab
	dc.b $ac, $ad, $ae, $af, $b0, $b1, $b2, $b3
	dc.b $b4, $b5, $b7, $b8, $b9, $ba, $bb, $bc
	dc.b $be, $bf, $c0, $c1, $c2, $c4, $c5, $c6
	dc.b $c7, $c9, $ca, $cb, $cd, $ce, $cf, $d1
	dc.b $d2, $d3, $d5, $d6, $d7, $d9, $da, $db
	dc.b $dd, $de, $e0, $e1, $e3, $e4, $e5, $e7
	dc.b $e8, $ea, $eb, $ed, $ee, $f0, $f1, $f3
	dc.b $f4, $f6, $f7, $f9, $fa, $fc, $fd, $ff
