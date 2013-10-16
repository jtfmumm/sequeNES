

;----------------------------------------------------------------
; variables
;----------------------------------------------------------------

    .enum $0000

    joypad1 .dsb 1           ;button states for the current frame
    joypad1_old .dsb 1       ;last frame's button states
    joypad1_pressed .dsb 1   ;current frame's off_to_on transitions
    sleeping .dsb 1          ;main program sets this and waits for the NMI to clear it.  Ensures the main program is run only once per frame.  
                        ;   for more information, see Disch's document: http://nesdevhandbook.googlepages.com/theframe.html
    ;needdraw .rs 1          ;drawing flag.
    ;dbuffer_index .rs 1     ;current position in the drawing buffer
    ptr1 .dsb 2              ;a pointer

   ;NOTE: declare variables using the DSB and DSW directives, like this:

   ;MyVariable0 .dsb 1
   ;MyVariable1 .dsb 3

   .ende

   ;NOTE: you can also split the variable declarations into individual pages, like this:

   ;.enum $0100
   ;.ende

   ;.enum $0200
   ;.ende
     
;----------------------------------------------------------------
; program bank(s)
;----------------------------------------------------------------

    .base $10000-(PRG_COUNT*$4000)  ;$C000 for one page, $8000 for two pages
 

;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;; SCALES/SYSTEMS ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;

c_range:
	.db C3, D3, E3, F3, G3, A3, B3, C4, D4, E4, F4, G4, A4, B4, C5, D5

sequences:
    .db $00,$03,$00,$04,$00,$07,$06,$07,$06,$02,$03,$02,$03,$04,$07,$09 
    .db $00,$04,$07,$0B,$0E,$0B,$07,$04,$00,$01,$05,$07,$09,$0C,$07,$05 
    .db $00,$00,$05,$07,$09,$00,$05,$02,$05,$02,$07,$09,$0B,$02,$07,$04 
    .db $00,$01,$02,$03,$01,$02,$03,$04,$05,$0B,$0A,$09,$08,$07,$06,$04 
    .db $00,$02,$04,$07,$09,$0B,$0E,$00,$0E,$0B,$09,$07,$04,$02,$00,$0E 

tempi:
    .db $25,$20,$1B,$0B,$08


;    .org $C000

   ;;Start init-code
reset:
    sei        ;; ignore IRQs
    cld        ;; disable decimal mode
    ldx #$40
    stx $4017  ;; disable APU frame IRQ
    ldx #$ff
    txs        ;; Set up stack
    inx        ;; now X = 0
    stx $2000  ;; disable NMI
    stx $2001  ;; disable rendering
    stx $4010  ;; disable DMC IRQs
 
    ;; Optional (omitted):
    ;; Set up mapper and jmp to further init code here.
 
    ;; Clear the vblank flag, so we know that we are waiting for the
    ;; start of a vertical blank and not powering on with the
    ;; vblank flag spuriously set
    bit $2002
 
    ;; First of two waits for vertical blank to make sure that the
    ;; PPU has stabilized
vblankwait1: 
    bit $2002
    bpl vblankwait1
 
    ;; We now have about 30,000 cycles to burn before the PPU stabilizes.
    ;; One thing we can do with this time is put RAM in a known state.
    ;; Here we fill it with $00, which matches what (say) a C compiler
    ;; expects for BSS.  Conveniently, X is still 0.
    txa
clrmem:
    sta $000,x
    sta $100,x
    sta $300,x
    sta $400,x
    sta $500,x
    sta $600,x
    sta $700,x  ;; Remove this if you're storing reset-persistent data
 
    ;; We skipped $200,x on purpose.  Usually, RAM page 2 is used for the
    ;; display list to be copied to OAM.  OAM needs to be initialized to
    ;; $EF-$FF, not 0, or you'll get a bunch of garbage sprites at (0, 0).
 
    inx
    bne clrmem
 
    ;; Other things you can do between vblank waits are set up audio
    ;; or set up other mapper registers.
    
vblankwait2:
    bit $2002
    bpl vblankwait2

;Enable sound channels
    jsr sound_init
    
    ;jsr sound_load
    
    lda #$88
    sta $2000   ;enable NMIs
    lda #$18
    sta $2001   ;turn PPU on


;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;; INITIAL VALUES ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda #$A7    ;Store $41A7 as multiplier (16807);
    sta mult0 ;mult0
    lda #$41
    sta mult1 ;mult1
    lda #$FF    ;Store $3FFFFFFF as modulus (2^31 - 1)
    sta mod0 ;mod0
    lda #$FF
    sta mod1 ;mod1
    lda #$FF
    sta mod2 ;mod2
    lda #$3F
    sta mod3 ;mod3

    lda #$A4    ;Load a seed into the random number generator
    sta rand0
    lda #$5B
    sta rand1
    lda #$23 
    sta rand2

    lda #00
    sta seeding     ;Start seeding

    lda #00             ;Initialize pointers 
    sta rand_cur_entry
    sta rand_cur_page
    sta cur_note        ;Our spot in the 16 note sequence
    sta cur_seq_loader  ;Current spot in preprogrammed sequences

    lda #02
    sta cur_tempo       ;Start at entry 3 in tempi table
    ldx cur_tempo
    lda tempi, x
    sta song_tempo      ;The value used to calculate tempo

    lda #07             ;
    sta cur_box

    jsr load_palette
    jsr init_sprites
    jsr load_sprites
    jsr load_background
    jsr load_attribute
    
    ;jsr test_audio
seed_it:
    lda seeding             ;This is wasteful.. move this to first screen logic
    bne +
    jsr read_joypad
@check_start
    lda joypad1_pressed
    and #$10
    beq @keep_seeding
    jsr sound_load
    lda #01
    sta seeding
@keep_seeding
    jsr gen_short_xor
    jmp seed_it
 
+   jsr populate_rands
    jsr get_next_seq

;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; MAIN LOOP ;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;
forever:
    inc sleeping ;go to sleep (wait for NMI).
-
    lda sleeping
    bne - ;wait for NMI to clear the sleeping flag and wake us up
    
    ;when NMI wakes us up, handle input, fill the drawing buffer and go back to sleep
+   jsr read_joypad
    jsr handle_input
    jsr sound_play_frame
    ;jsr prepare_dbuffer
    jmp forever ;go back to sleep

;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;NMI;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;
NMI:
    pha     ;save registers
    txa
    pha
    tya
    pha

    lda #$00
    sta $2003  ; set the low byte (00) of the RAM address
    lda #$02
    sta $4014  ; set the high byte (02) of the RAM address, start the transfer

    lda #$00
    sta sleeping            ;wake up the main program

    jsr sound_play_frame
    
    pla     ;restore registers
    tay
    pla
    tax
    pla
    rti

;----------------------------
; read_joypad will capture the current button state and store it in joypad1.  
;       Off-to-on transitions will be stored in joypad1_pressed
read_joypad:
    lda joypad1
    sta joypad1_old ;save last frame's joypad button states
    
    lda #$01
    sta $4016
    lda #$00
    sta $4016
    
    ldx #$08
@loop:    
    lda $4016
    lsr a
    rol joypad1  ;A, B, select, start, up, down, left, right
    dex
    bne @loop
    
    lda joypad1_old ;what was pressed last frame.  EOR to flip all the bits to find ...
    eor #$FF    ;what was not pressed last frame
    and joypad1 ;what is pressed this frame
    sta joypad1_pressed ;stores off-to-on transitions
    
    rts

;---------------------
; handle_input will perform actions based on input:
;   A - play sound
;   B - init sound engine
;   Start - disable sound engine
handle_input:
@check_A:
    lda joypad1_pressed
    and #$80
    beq @check_B
    jsr load_sequence
@check_B:
    lda joypad1_pressed
    and #$40
    beq @check_select
    jsr invert_retrogress
@check_select:
    lda joypad1_pressed
    and #$20
    beq @check_start
    jsr get_next_seq
@check_start:
    lda joypad1_pressed
    and #$10
    beq @check_up
    jsr sound_load
@check_up:
    lda joypad1_pressed
    and #$08
    beq @check_down
    jsr move_up
@check_down:
    lda joypad1_pressed
    and #$04
    beq @check_left
    jsr move_down
@check_left:
    lda joypad1_pressed
    and #$02
    beq @check_right
    jsr move_left
@check_right:
    lda joypad1_pressed
    and #$01
    beq +
    jsr move_right
+
    rts
    
      
;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;


IRQ:

   ;NOTE: IRQ code goes here
   rti



;Background
background:
    ;lda #%10000000   ;intensify blues
    ;sta $2001
    lda #$A0
    sta $3F10
    lda #01
    sta arg0   ;My variable for rep_delay count
    jsr rep_delay
    ;lda #%01000000
    ;sta $2001
    lda #$A0
    sta $3F10
    lda #06
    sta arg0
    jsr rep_delay
    jmp background


;BORROWED SUBROUTINES
load_palette:
    lda $2002    ; read PPU status to reset the high/low latch
    lda #$3F
    sta $2006    ; write the high byte of $3F00 address
    lda #$00
    sta $2006    ; write the low byte of $3F00 address
    ldx #$00
-   lda palette, x        ;load palette byte
    sta $2007             ;write to PPU
    inx                   ;set index to next byte
    cpx #$20            
    bne -     ;if x = $20, 32 bytes copied, all done
    rts

load_sprites:
    ldx #$00              ; start at 0
-   lda sprites, x        ; load data from address (sprites +  x)
    sta $0200, x          ; store into RAM address ($0200 + x)
    inx                   ; X = X + 1
    cpx #$20              ; Compare X to hex $20, decimal 32
    bne -               ; Branch to - if compare was Not Equal to zero
                        ; if compare was equal to 32, keep going down
    
    lda #%10000000   ; enable NMI, sprites from Pattern Table 1
    sta $2000

    lda #%00010000   ; enable sprites
    sta $2001
    rts

init_sprites:
    lda #$80
    sta $0200        ; put sprite 0 in center ($80) of screen vert
    sta $0203        ; put sprite 0 in center ($80) of screen horiz
    ;sta $0204
    ;lda #$90
    ;sta $0207

    lda #$00
    sta $0201        ; tile number = 0
    sta $0202        ; color = 0, no flipping

    lda #%10000000   ; enable NMI, sprites from Pattern Table 0
    sta $2000

    lda #%00010000   ; enable sprites
    sta $2001
    rts    

load_background:
    LDA $2002             ; read PPU status to reset the high/low latch
    LDA #$20
    STA $2006             ; write the high byte of $2000 address
    LDA #$00
    STA $2006             ; write the low byte of $2000 address
    LDX #$00              ; start out at 0
-   LDA background, x     ; load data from address (background + the value in x)
    STA $2007             ; write to PPU
    INX                   ; X = X + 1
    CPX #$80              ; Compare X to hex $80, decimal 128 - copying 128 bytes
    BNE -  ; Branch to LoadBackgroundLoop if compare was Not Equal to zero
                        ; if compare was equal to 128, keep going 
    rts

                          
load_attribute:
    LDA $2002             ; read PPU status to reset the high/low latch
    LDA #$23
    STA $2006             ; write the high byte of $23C0 address
    LDA #$C0
    STA $2006             ; write the low byte of $23C0 address
    LDX #$00              ; start out at 0
-   LDA attribute, x      ; load data from address (attribute + the value in x)
    STA $2007             ; write to PPU
    INX                   ; X = X + 1
    CPX #$08              ; Compare X to hex $08, decimal 8 - copying 8 bytes
    BNE -  ; Branch to LoadAttributeLoop if compare was Not Equal to zero
                        ; if compare was equal to 128, keep going down
                    
    LDA #%10010000   ; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
    STA $2000

    LDA #%00011110   ; enable sprites, enable background, no clipping on left side
    STA $2001
    rts

; palette data
palette:
    .db $0F,$31,$32,$33,$0F,$35,$36,$37,$0F,$39,$3A,$3B,$0F,$3D,$3E,$0F  ;background palette data
    .db $0F,$1C,$15,$14,$0F,$02,$38,$3C,$0F,$1C,$15,$14,$0F,$02,$38,$3C  ;sprite palette data

sprites:
    ;vert tile attr horiz
    .db $80, $32, $00, $80   ;sprite 0
    .db $80, $33, $00, $88   ;sprite 1
    .db $88, $34, $00, $80   ;sprite 2
    .db $88, $35, $00, $88   ;sprite 3

attribute:
    .db %00000000, %00001000, %01010000, %00010000, %00000000, %00000000, %00000000, %00110000

    ;Note: octaves in music traditionally start from C, not A.  
;      I've adjusted my octave numbers to reflect this.
note_table:
    .word                                                                $07F1, $0780, $0713 ; A1-B1 ($00-$02)
    .word $06AD, $064D, $05F3, $059D, $054D, $0500, $04B8, $0475, $0435, $03F8, $03BF, $0389 ; C2-B2 ($03-$0E)
    .word $0356, $0326, $02F9, $02CE, $02A6, $027F, $025C, $023A, $021A, $01FB, $01DF, $01C4 ; C3-B3 ($0F-$1A)
    .word $01AB, $0193, $017C, $0167, $0151, $013F, $012D, $011C, $010C, $00FD, $00EF, $00E2 ; C4-B4 ($1B-$26)
    .word $00D2, $00C9, $00BD, $00B3, $00A9, $009F, $0096, $008E, $0086, $007E, $0077, $0070 ; C5-B5 ($27-$32)
    .word $006A, $0064, $005E, $0059, $0054, $004F, $004B, $0046, $0042, $003F, $003B, $0038 ; C6-B6 ($33-$3E)
    .word $0034, $0031, $002F, $002C, $0029, $0027, $0025, $0023, $0021, $001F, $001D, $001B ; C7-B7 ($3F-$4A)
    .word $001A, $0018, $0017, $0015, $0014, $0013, $0012, $0011, $0010, $000F, $000E, $000D ; C8-B8 ($4B-$56)
    .word $000C, $000C, $000B, $000A, $000A, $0009, $0008                                    ; C9-F#9 ($57-$5D)




latch_controller:
    LDA #$01
    STA $4016
    LDA #$00
    STA $4016       ; tell both the controllers to latch buttons

read_a: 
    LDA $4016       ; player 1 - A
    AND #%00000001  ; only look at bit 0
    BEQ read_a_done   ; branch to ReadADone if button is NOT pressed (0)
                  ; add instructions here to do something when button IS pressed (1)
    LDA $0203       ; load sprite X position
    CLC             ; make sure the carry flag is clear
    ADC #$01        ; A = A + 1
    STA $0203       ; save sprite X position
read_a_done:        ; handling this button is done
  

read_b: 
    LDA $4016       ; player 1 - B
    AND #%00000001  ; only look at bit 0
    BEQ read_b_done   ; branch to ReadBDone if button is NOT pressed (0)
                  ; add instructions here to do something when button IS pressed (1)
    LDA $0203       ; load sprite X position
    SEC             ; make sure carry flag is set
    SBC #$01        ; A = A - 1
    STA $0203       ; save sprite X position
read_b_done:        ; handling this button is done

    ;;This is the PPU clean up section, so rendering the next frame starts properly.
    lda #%10010000   ; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
    sta $2000
    lda #%00011110   ; enable sprites, enable background, no clipping on left side
    sta $2001
    lda #$00        ;;tell the ppu there is no background scrolling
    sta $2005
    sta $2005

    rti        