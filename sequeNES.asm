
;----------------------------------------------------------------
; iNES header
;----------------------------------------------------------------

PRG_COUNT = 1 ;1 = 16KB, 2 = 32KB
MIRRORING = %0001 ;%0000 = horizontal, %0001 = vertical, %1000 = four-screen

    .db "NES", $1a ;identification of the iNES header
    .db PRG_COUNT ;number of 16KB PRG-ROM pages
    .db $01 ;number of 8KB CHR-ROM pages
    .db $00|MIRRORING ;mapper 0 and mirroring
    .dsb 9, $00 ;clear the remaining bytes

;;;;;;;;;;;;;;;;;;
;;;; includes ;;;;
;;;;;;;;;;;;;;;;;;

.include "sequeNESconstants.asm"
.include "sequeNESprg.asm"
.include "utilities.asm"
.include "sound_engine.asm"

;;;;;;;;;;;;;;;;;;;;;;;
;; interrupt vectors ;;
;;;;;;;;;;;;;;;;;;;;;;;
   
    .org $fffa

    .dw NMI
    .dw reset
    .dw IRQ

;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;; CHR-ROM ;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;

   .incbin "sequeNESchr.asm"








