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
    inc seq_cur_entry
    lda seq_cur_entry	;Check for wraparound at 16
    sec
    sbc #16
    bne +
    sta seq_cur_entry
+   rts

quick_seq:
	ldx #08
	ldy #00
-	lda seq0, y
	sta note0, y
	iny
	dex
	bne -
	rts

get_next_seq:
	ldx #16 					;Keep track of how many steps are left
	ldy #00 					;Keep track of where in the 16-note seq we are
-	lda #00
	cmp seq_cur_page			;Which page are we taking our notes from?
	bne +						;If page 1, go there
	txa							;Preserve our x
	pha
	ldx seq_cur_entry		    
	lda seq0, x					;Load the value of page 0 plus our current entry
	sta note0, y 				;Store it in the next seq spot
	pla 						;Get our x back
	tax
	iny
	inc seq_cur_entry			;Did we move to the end of the page?
	sec 						;Check for wraparound at 16
	sbc #16
	beq ++
	dex
	bne -						;Do we have steps left?
	rts
+   txa
	pha
	ldx seq_cur_entry
	lda seq1, x				 	;See above comments
	sta note0, y
	pla							;Get our x back
	tax
	iny
	inc seq_cur_entry
	sec
	sbc #16
	beq ++
	dex
	bne -
	rts
++  ;Switch page
	lda #00
	sta seq_cur_entry
	lda seq_cur_page			;Use eor to toggle page betw 0 and 1
	eor #$01
	sta seq_cur_page
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
	sta seq_cur_entry
-	ldx seq_cur_entry
	jsr gen_short_xor
	lda rand0
	sta seq0, x
	inc seq_cur_entry
	beq +
	jmp -
+	
-	ldx seq_cur_entry
	jsr gen_short_xor
	lda rand0
	sta seq1, x
 	inc seq_cur_entry
 	beq +
 	jmp -
+	rts

gen_xor_rands:
-	ldx seq_cur_entry
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
	sta seq0, x 	;Store in page 0, next entry

	inc	seq_cur_entry
	lda seq_cur_entry
	beq +			;If we've cycled around, go to page 1
	jmp -
+	;Do page 1
-	ldx seq_cur_entry
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
	sta seq1, x 	;Store in page 0, next entry
	inc seq_cur_entry
	lda seq_cur_entry
	bne - 			;If we've not cycled around, continue
	lda #00
	sta seq_cur_entry
	sta seq_cur_page
	rts



generate_rands:
	;Use multiplier stored from mult0 to mult1
	;Sequence begins at seq0 and goes to seq1 (those are pages)
	ldy #00				;Displacement from sequence start

-	tya
	pha					;Remember current displacement
	jsr multiply_rand	;First get next rand
	jsr mod_arithmetic	;Make sure it's within range
	pla					;Recall current displacement
	tay

	lda rand0			;Mask and get low four bits 
	and #$0F			; to get random values from 0-15
	sta seq0, y 		;Store value in next sequence spot
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
	sta seq1, y 		;Store value in next sequence spot
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

