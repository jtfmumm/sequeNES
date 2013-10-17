;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  //  //  //////  //////  //      //////  //////  //////  //////  //////  ;;
;;  ||  ||    ||      ||    ||        ||      ||      ||    ||      ||      ;;
;;  ||  ||    ||      ||    ||        ||      ||      ||    |/////  |////|  ;;
;;  ||  ||    ||      ||    ||        ||      ||      ||    ||          ||  ;;
;;   ////     //    //////  //////  //////    //    //////  //////  //////  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.org $D000

update_boxes:
    ldx #00
-   ldy note0, x
	lda vertical_positions, y
	ldy boxes, x
    sta $0200, y     ; set colors to be the same
    inx
    cpx #16          ; Have we set all our boxes?
    bne -
    ;Restore colors
    ldy #00
    lda #01
-   ldx boxes, y
    sta $0202, x     ; set colors to be the same
    iny
    cpy #16          ; Have we set all our boxes?
    bne -
    ;;Set highlight for selected box
    ldy cur_box
    ldx boxes, y
    lda #02
    sta $0202, x
    ;;Set highlight for current note
    lda cur_note
    sec
    sbc #01
    and #$0F    
    tay
    ldx boxes, y
    lda #00
    sta $0202, x
    rts

move_up:
    ldx cur_box
    inc note0, x
    lda note0, x
	sec
	sbc #16 		;There are only 16 notes
	bne +
	lda #00 		;Wraparound to bottom
	sta note0, x
+   rts

move_down:
    ldx cur_box
    dec note0, x
    lda note0, x
	bpl +			;Did we go under?
	lda #15 		;Wraparound to top
	sta note0, x
+   rts
    
move_right:
	inc cur_box
	lda cur_box
	ldy phrase_length   ;Are we at an 8 or 16 note phrase?
    cpy #08
    bne @sixteen
@eight:
    and #$07 		;Mask down to low 8
    jmp +
@sixteen:
    and #$0F        ;Mask down to low 16
    sta cur_box
+	rts
 
move_left:
	dec cur_box
	lda cur_box
	bpl + 			    ;Are we still 0 or above?
	ldy phrase_length	;Wraparound screen
	dey 				; depending on phrase_length
	tya  		
	sta cur_box
+	rts

load_sequence:
	;Load next pre-programmed sequence
	; and reset to first step
	ldy #00 			;Countdown steps
-	ldx cur_seq_loader  ;Current step
	lda sequences, x
	sta note0, y
	inc cur_seq_loader
	iny
	tya
	sec
	sbc #16
	bne -
	lda cur_seq_loader
	sec
	sbc #$50 			;Check for end of banks
	bne +
	lda #00
	sta cur_seq_loader
+	lda #00  		;Reset to beginning of cycle
	sta cur_note
	rts

change_tempo:
	inc cur_tempo
	lda cur_tempo
	sec
	sbc #04			;Subtract length of tempi table
	bne +
	lda #00
	sta cur_tempo
+	ldx cur_tempo
    lda tempi, x
    sta song_tempo      ;The value used to calculate tempo
	rts

invert_retrogress:
	;Alternate inverting and reversing
	; but don't reset to first step
	lda inv_ret
	bne + ;@retrogress
@invert:
	ldx #16
-	lda note0, x 
	cmp #15  		;Is our note silence? 
	beq @next  		; If so, leave it alone.
	lda #14  		;Our note values range from 0-14 	
	sec 			; so subtract from 14 to get
	sbc note0, x 	; inversion (around a center line)
	sta note0, x
@next:
	dex
	bne - 
	lda #14
	sec 			; do it one last time on 0
	sbc note0, x 	
	sta note0, x
	jmp ++ ;@done
+ ;@retrogress:
	ldx #07 		;Start from middle and work out
	ldy #08 		; swapping as you go 
-	lda note0, x
	sta arg0
	lda note0, y
	sta note0, x
	lda arg0
	sta note0, y
	iny
	dex
	bne -			;On 0, swap one more time, then return
	lda note0, x
	sta arg0
	lda note0, y
	sta note0, x
	lda arg0
	sta note0, y
++ ;@done:
	lda inv_ret
	eor #$01
	sta inv_ret
	rts

change_scale:
	ldy #00
-	ldx cur_scale_loader  ;Current step
	lda scales, x
	sta cur_scale0, y
	inc cur_scale_loader
	iny
	tya
	sec
	sbc #16
	bne -	
	lda cur_scale_loader 	;Check for end of banks
	cmp #$40 ;scale_banks
	bne +
	lda #00
	sta cur_scale_loader
+	rts

get_next_seq:
	;Grab a new random sequence
	; and reset to first step
	ldx #16 					;Keep track of how many steps are left
	ldy #00 					;Keep track of where in the 16-note seq we are
@loop:
	lda #00
	cmp rand_cur_page			;Which page are we taking our notes from?
	bne @page1						;If page 1, go there
	txa							;Preserve our x
	pha
	ldx rand_cur_entry		    
	lda rand_seq0, x					;Load the value of page 0 plus our current entry
	sta note0, y 				;Store it in the next seq spot
	pla 						;Get our x back
	tax
	iny
	inc rand_cur_entry			;Did we move to the end of the page?
	lda rand_cur_entry
							;Check for wraparound
	beq @switch_page
	dex
	bne @loop						;Do we have steps left?
	lda #00  		;Reset to beginning of cycle
	sta cur_note
	rts
@page1:
    txa
	pha
	ldx rand_cur_entry
	lda rand_seq1, x				 	;See above comments
	sta note0, y
	pla							;Get our x back
	tax
	iny
	inc rand_cur_entry
	beq @switch_page
	dex
	bne @loop
	lda #00  		;Reset to beginning of cycle
	sta cur_note
	rts
@switch_page:  
	lda #00
	sta rand_cur_entry
	lda rand_cur_page			;Use eor to toggle page betw 0 and 1
	eor #$01
	sta rand_cur_page
	dex							;Check to see if we have steps left
	cpx #00
	bne -						
	rts

gen_short_xor:
	lda rand1
  	asl
  	ror rand2
  	bcc +
  	eor #$DB
+
  	asl
  	ror rand2
  	bcc +
  	eor #$DB
+
  	sta rand1
  	and #$0F
  	sta rand0
  	eor rand2  	
  	rts

populate_rands:
	lda #00
	sta rand_cur_entry
-	ldx rand_cur_entry
	jsr gen_short_xor
	lda rand0
	sta rand_seq0, x
	inc rand_cur_entry
	beq +
	jmp -
+	
-	ldx rand_cur_entry
	jsr gen_short_xor
	lda rand0
	sta rand_seq1, x
 	inc rand_cur_entry
 	beq +
 	jmp -
+	rts

delay:
    ;255^3 cycles is roughly 1 second (92.5%)... 1,789,772 cycles is one second
    ldx #$FF
    ldy #$FF
-   dex
    beq +    ;Is X zero?  Go to y counter
    jmp -
+   dey
    beq +    ;Is Y zero? Go to end
    jmp -    ;Otherwise cycle through x again
+   rts

rep_delay:
    ;arg0=count
    lda arg0
-   pha 
    jsr delay
    pla
    tax
    dex 
    txa
    bne -
    rts