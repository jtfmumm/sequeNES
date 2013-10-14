;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Arguments for subroutines ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

arg0 = $00C0
arg1 = $00C1
arg2 = $00C2
arg3 = $00C3
arg4 = $00C4
arg5 = $00C5
arg6 = $00C6
arg7 = $00C7
arg8 = $00C8
arg9 = $00C9
argA = $00CA
argB = $00CB
argC = $00CC
argD = $00CD
argE = $00CE
argF = $00CF


;;;;;;;;;;;;;;
;Addresses
;;;;;;;;;;;;;;
mod0 = $00D0	;Modulus stored in 4 bytes
mod1 = $00D1
mod2 = $00D2
mod3 = $00D3
mult0 = $00D4	;Multiplier stored in 2 bytes
mult1 = $00D5
rand0 = $00D6	;Current rand stored in 8 bytes
rand1 = $00D7
rand2 = $00D8
rand3 = $00D9
rand4 = $00DA
rand5 = $00DB
rand6 = $00DC
rand7 = $00DD
ans0 = $00DE	;Scratch pad stored in 8 bytes
ans1 = $00DF
ans2 = $00E0
ans3 = $00E1
ans4 = $00E2
ans5 = $00E3
ans6 = $00E4
ans7 = $00E5
note0 = $00E6	;Current sequence of 16 notes
note1 = $00E7
note2 = $00E8
note3 = $00E9
note4 = $00EA
note5 = $00EB
note6 = $00EC
note7 = $00ED
note8 = $00EE
note9 = $00EF
noteA = $00F0
noteB = $00F1
noteC = $00F2
noteD = $00F3
noteE = $00F4
noteF = $00F5
seq_cur_page = #00
seq_cur_entry = #00

seq0 = $D100
seq1 = $D1FF

;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;; INITIAL VALUES ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;
	lda #$A7	;Store $41A7 as multiplier (16807);
	sta mult0
	lda #$41
	sta mult1
	lda #$FF 	;Store $3FFFFFFF as modulus (2^31 - 1)
	sta mod0
	lda #$FF
	sta mod1
	lda #$FF
	sta mod2
	lda #$3F
	sta mod3


;;;;;;;;;;;;;;;;;;;;;;;
;;;;; NOTE VALUES ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;

;Octave 1
A1 = $00
As1 = $01
Bb1 = $01
B1 = $02

;Octave 2
C2 = $03
Cs2 = $04
Db2 = $04
D2 = $05
Ds2 = $06
Eb2 = $06
E2 = $07
F2 = $08
Fs2 = $09
Gb2 = $09
G2 = $0A
Gs2 = $0B
Ab2 = $0B
A2 = $0C
As2 = $0D
Bb2 = $0D
B2 = $0E

;Octave 3
C3 = $0F
Cs3 = $10
Db3 = $10
D3 = $11
Ds3 = $12
Eb3 = $12
E3 = $13
F3 = $14
Fs3 = $15
Gb3 = $15
G3 = $16
Gs3 = $17
Ab3 = $17
A3 = $18
As3 = $19
Bb3 = $19
B3 = $1A

;Octave 4
C4 = $1B
Cs4 = $1C
Db4 = $1C
D4 = $1D
Ds4 = $1E
Eb4 = $1E
E4 = $1F
F4 = $20
Fs4 = $21
Gb4 = $21
G4 = $22
Gs4 = $23
Ab4 = $23
A4 = $24
As4 = $25
Bb4 = $25
B4 = $26

;Octave 5
C5 = $27
Cs5 = $28
Db5 = $28
D5 = $29
Ds5 = $2A
Eb5 = $2A
E5 = $2B
F5 = $2C
Fs5 = $2D
Gb5 = $2D
G5 = $2E
Gs5 = $2F
Ab5 = $2F
A5 = $30
As5 = $31
Bb5 = $31
B5 = $32

;Octave 6
C6 = $33
Cs6 = $34
Db6 = $34
D6 = $35
Ds6 = $36
Eb6 = $36
E6 = $37
F6 = $38
Fs6 = $39
Gb6 = $39
G6 = $3A
Gs6 = $3B
Ab6 = $3B
A6 = $3C
As6 = $3D
Bb6 = $3D
B6 = $3E

;Octave 7
C7 = $3F
Cs7 = $40
Db7 = $40
D7 = $41
Ds7 = $42
Eb7 = $42
E7 = $43
F7 = $44
Fs7 = $45
Gb7 = $45
G7 = $46
Gs7 = $47
Ab7 = $47
A7 = $48
As7 = $49
Bb7 = $49
B7 = $4A

;Octave 8
C8 = $4B
Cs8 = $4C
Db8 = $4C
D8 = $4D
Ds8 = $4E
Eb8 = $4E
E8 = $4F
F8 = $50
Fs8 = $51
Gb8 = $51
G8 = $52
Gs8 = $53
Ab8 = $53
A8 = $54
As8 = $55
Bb8 = $55
B8 = $56


