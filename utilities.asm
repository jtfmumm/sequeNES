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
    rts

get_next_seq:
	lda #00
	ldx #16 					;Keep track of how many steps are left
	ldy #00 					;Keep track of where in the 16-note seq we are
-	cmp seq_cur_page			;Which page are we taking our notes from?
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
	beq ++
	dex
	bne -
	rts
++  ;Switch page
	lda seq_cur_page			;Use eor to toggle page betw 0 and 1
	eor #$01
	sta seq_cur_page
	dex							;Check to see if we have steps left
	cpx #00
	bne -						
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
	sta (seq0), y 		;Store value in next sequence spot
	iny
	beq @next			;Did we get to end of page?
	jmp -				; If not repeat for next y 
@next:
-	tya
	pha					;Remember current displacement
	jsr multiply_rand	;First get next rand
	jsr mod_arithmetic	;Make sure it's within range
	pla					;Recall current displacement
	tay

	lda rand0			;Mask and get low four bits 
	and #$0F			; to get random values from 0-15
	sta (seq1), y 		;Store value in next sequence spot
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
	ldx #24		;load bit count for multiplier
--	;Loop
	lsr #00		;grab next bit of multiplier (but its two high bytes are zero)
	ror mult1	 
	ror mult0
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
	rts


mod_arithmetic:
	;Is current value greater than modulus?
	;	Then subtract modulus to get new value
	;We're dealing with a six byte number here

	lda #00		;Modulus is only 4 bytes
				; so test bytes 4-7 of rand first
	cmp rand7
	bne @greater
	cmp rand6
	bne @greater
	cmp rand5
	bne @greater
	cmp rand4
	bne @greater

	sec			;Subtract from low to high byte	
	lda mod0
	sbc rand0
	lda mod1
	sbc rand1
	lda mod2
	sbc rand2
	lda mod3
	sbc rand3
	bcc @greater ;Check if rand is larger than modulus
	rts 		 ; If not, we're done
@greater:		 ; If so, subtract modulus from rand 
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

