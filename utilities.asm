;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  //  //  //////  //////  //      //////  //////  //////  //////  //////  ;;
;;  ||  ||    ||      ||    ||        ||      ||      ||    ||      ||      ;;
;;  ||  ||    ||      ||    ||        ||      ||      ||    |/////  |////|  ;;
;;  ||  ||    ||      ||    ||        ||      ||      ||    ||          ||  ;;
;;   ////     //    //////  //////  //////    //    //////  //////  //////  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.org $D000

play_note:
	ldx this_note
	lda c_range, x
    asl a               ;multiply by 2 because we are indexing into a table of words
    tay
    lda note_table, y   ;read the low byte of the period
    sta $4002           ;write to SQ1_LO
    lda note_table+1, y ;read the high byte of the period
    sta $4003           ;write to SQ1_HI
    inc rand_cur_entry
    lda rand_cur_entry	;Check for wraparound at 16
    sec
    sbc #16
    bne +
    sta rand_cur_entry
+   rts

move_up:
	;Move box
    lda $0200       ; load sprite Y position
    sec             
    sbc #$08        ; A = A - 1
    sta $0200       ; save sprite Y position
    ;Change note
    ldx cur_box
    inc note0, x
    lda note0, x
	sec
	sbc #16 		;There are only 16 notes
	bne +
	lda #00 		;Wraparound to bottom
	sta note0, x
	lda $0200 		;Now wrap box!
	sec
	sbc #128
	sta $0200
+   rts

move_down:
	;Move box
    lda $0200       ; load sprite Y position
    clc             
    adc #$08        ; A = A + 1
    sta $0200       ; save sprite Y position
    ;Change note
    ldx cur_box
    dec note0, x
    lda note0, x
	bpl +			;Did we go under?
	lda #15 		;Wraparound to top
	sta note0, x
	lda $0200 		;Now wrap box!
	clc
	adc #128
	sta $0200
+   rts
    
move_right:
	inc cur_box
	lda cur_box
	sec
	sbc #16 		;There are only 16 boxes
	bne +
	lda #00 		;Wraparound screen
	sta cur_box
+	rts
 
move_left:
	dec cur_box
	lda cur_box
	bpl + 			;Are we still 0 or above?
	lda #15 		;Wraparound screen
	sta cur_box
+	rts

load_sequence:
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
+	rts

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

quick_seq:
	ldx #08
	ldy #00
-	lda rand_seq0, y
	sta note0, y
	iny
	dex
	bne -
	rts

get_next_seq:
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

;;;;;
	lda rand0
	lsr rand0
	bcc +
	eor #$B4
+	rts

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

gen_xor_rands:
-	ldx rand_cur_entry
	ror rand0		;Use two numbers
					;8-bit rand0 (clc to clear rotate bit)
	bcc +			;Wrap around the last bit
	lda rand0
	ora #$80
	sta rand0
	;clc
+	ror rand2		;16-bit rand1/rand2
	ror rand1		
	bcc + 			;Wrap around the last bit
	lda rand2
	ora #$80
	sta rand2
	lda rand1		;Update rands with xoring
	eor #$95
	sta rand1
	lda rand2
	eor #$D2
	sta rand2	
	lda rand0
	eor #$36
	sta rand0

	lda rand0		;xor the lower 8 bits of our two numbers
	eor rand1		;store the lowest four bits in rand3
	and #$0F
	sta rand3
	sta rand_seq0, x 	;Store in page 0, next entry

	inc	rand_cur_entry
	lda rand_cur_entry
	beq +			;If we've cycled around, go to page 1
	jmp -
+	;Do page 1
-	ldx rand_cur_entry
	ror rand0		;Use two numbers
	bcc + 			;Wrap around the last bit
	lda rand0
	ora #$80
	sta rand0		;8-bit rand0 (clc to clear rotate bit)
+	;clc
	ror rand2		;16-bit rand1/rand2
	ror rand1
	bcc + 			;Wrap around the last bit
	lda rand2
	ora #$80
	sta rand2		

	lda rand1		;Update rands with xoring
	eor #$95
	sta rand1
	lda rand2
	eor #$D2
	ora #$80		
	sta rand2	
	lda rand0
	eor #$36
	sta rand0

	lda rand0		;xor the lower 8 bits of our two numbers
	eor rand1		;store the lowest four bits in rand3
	and #$0F
	sta rand3
	sta rand_seq1, x 	;Store in page 0, next entry
	inc rand_cur_entry
	lda rand_cur_entry
	bne - 			;If we've not cycled around, continue
	lda #00
	sta rand_cur_entry
	sta rand_cur_page
	rts



generate_rands:
	;Use multiplier stored from mult0 to mult1
	;Sequence begins at rand_seq0 and goes to rand_seq1 (those are pages)
	ldy #00				;Displacement from sequence start

-	tya
	pha					;Remember current displacement
	jsr multiply_rand	;First get next rand
	jsr mod_arithmetic	;Make sure it's within range
	pla					;Recall current displacement
	tay

	lda rand0			;Mask and get low four bits 
	and #$0F			; to get random values from 0-15
	sta rand_seq0, y 		;Store value in next sequence spot
	iny
	beq +				;Did we get to end of page?
	jmp -				; If not repeat for next y 
+
-	tya
	pha					;Remember current displacement
	jsr multiply_rand	;First get next rand
	jsr mod_arithmetic	;Make sure it's within range
	pla					;Recall current displacement
	tay

	lda rand0			;Mask and get low four bits 
	and #$0F			; to get random values from 0-15
	sta rand_seq1, y 		;Store value in next sequence spot
	iny
	beq @end			;Did we get to end of page?
	jmp -				; If not repeat for next y 
@end:
	rts
	

multiply_rand:
	;Multipying two 4 byte numbers
	;Temp asnwer is in ans0 (high) to ans7 (low)
	;Multiplier from from mult0 to mult2 (msby to lsby) - mult2 is $00
	;Current rand is in rand0 to rand5, but we only use rand0 to rand2 for mult
	lda #00		;First set answer to zero
	sta ans5
	sta ans4
	sta ans3
	sta ans2
	sta ans1
	sta ans0
	lda mult0	;Store multiplier where it can be rotated
	sta arg0
	lda mult1
	sta arg1
	ldx #24		;load bit count for multiplier
--	;Loop
	lsr #00		;grab next bit of multiplier (but its two high bytes are zero)
	ror arg1	 
	ror arg0
	bcc +	    ;Is there a 1?
	lda ans0	; Yes. Load up low bit of product
	clc
	adc rand0	;Add low bit of multiplicand
	sta ans0	;Store in answer
	lda ans1	;Now successively add higher bits
	adc rand1
	sta ans1
	lda ans2
	adc rand2
	sta ans2
	lda ans3
	adc rand3
	sta ans3
	lda ans4
	adc rand4
	sta ans4
	lda ans5
	adc rand5
	sta ans5
	lda ans6
	adc rand6
	sta ans6
	lda ans7
	adc rand7
	sta ans7
+	ror a 		;Before storing msby, rotate right to align
				; If jumped here, then accumulator still contains ans5
	sta ans7	;Rightmost bit is still saved in carry flag
	ror ans6	;Rotate the rest of the bytes right
	ror ans5
	ror ans4
	ror ans3
	ror ans2
	ror ans1
	ror ans0
	dex			;Decrement multiplier byte count
	bne --

	lda ans7	;Store new rand
	sta rand7
	lda ans6
	sta rand6
	lda ans5
	sta rand5
	lda ans4
	sta rand4
	lda ans3
	sta rand3
	lda ans2
	sta rand2
	lda ans1
	sta rand1
	lda ans0
	sta rand0
	lda rand0
	cmp #00
	bne +
	lda #$FF
	sta rand0
+	rts


mod_arithmetic:
	;Is current value greater than modulus?
	;	Then subtract modulus to get new value
	;We're dealing with a six byte number here

	lda #00		;Modulus is only 4 bytes
				; so test bytes 4-7 of rand first
	cmp rand7
	bne +
	cmp rand6
	bne +
	cmp rand5
	bne +
	cmp rand4
	bne +

	sec			;Subtract from low to high byte	
	lda mod0
	sbc rand0
	lda mod1
	sbc rand1
	lda mod2
	sbc rand2
	lda mod3
	sbc rand3
	bcc +		 ;Check if rand is larger than modulus
	rts 		 ; If not, we're done
+				 ; If so, subtract modulus from rand 
	sec			 ;  using 6 byte subtraction 
    lda rand0
    sbc mod0
    sta rand0
    lda rand1
    sbc mod1
    sta rand1
    lda rand2
    sbc mod2
    sta rand2
    lda rand3
    sbc mod3
    sta rand3
    lda rand4
    sbc #00		;Modulus only has 4 bytes
    sta rand4
    lda rand5
    sbc #00
    sta rand5
    lda rand6
    sbc #00
    sta rand6
    lda rand7
    sbc #00
    sta rand7
    jmp mod_arithmetic	;Make sure we're now in range


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