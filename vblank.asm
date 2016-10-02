
INCLUDE "hram.asm"
INCLUDE "vram.asm"

Section "Working Background Grid", WRAMX

; WorkingGrid is a 20x18 grid of tile indices, a subsection of the TileGrid
; You should write things here for later copying to true vRAM on a VBlank
WorkingGrid::
	ds 20*18

Section "VBlank Drawing Routine", ROM0

; We draw a quarter of the screen at a time, that's all we have time for
; We track the current quarter in WorkingGridPartNumber
CopyWorkingGrid::
	ld HL, SP+0
	ld B, H
	ld C, L ; save SP in BC

	; for each count in PartNumber, we add 256 to the TileGrid, ie. 8 rows
	; however, 8 rows in the WorkingGrid is only 8*20 = 160 = $a0
	; so we need to set HL = base + n * $a0
	ld A, [WorkingGridPartNumber]
	ld D, A
	ld HL, WorkingGrid
	; pass immediately if A = 0
	and A
	jr z, .afterpartloop
.partloop
	ld A, L
	add $a0 ; possibly carry
	ld L, A
	ld A, H
	adc $0 ; add if carry
	ld H, A
	dec D
	jr nz, .partloop
.afterpartloop
	ld SP, HL ; stack pointer = source

	; since we're multiplying by $100 here, we can cheat by adding to upper byte
	ld A, [WorkingGridPartNumber]
	add (TileGrid & $ff00) >> 8 ; get upper byte of TileGrid + part number
	ld H, A
	ld L, 0 ; HL = dest

.loop
	; We use a hack here: use SP as source pointer, so pop DE becomes "ld DE, [SP+]"
	; We only need to worry about the first 20 bytes of each row of 32 bytes
	REPT 9
	pop DE
	ld [HL], E
	inc L
	ld [HL], D
	inc L
	ENDR
	; do one loop too few then explicitly copy the last loop so we can roll the final inc l into the add
	pop DE
	ld [HL], E
	inc L
	ld [HL], D
	; skip remaining 12 bytes of 32-byte row
	ld a, 13
	add l
	ld l, a
	jr nz, .loop ; break when L has fully wrapped

	ld H, B
	ld L, C
	ld SP, HL

	ld A, [WorkingGridPartNumber]
	inc A
	; if A = 3, reset A
	cp $03
	jr nz, .next
	xor A
.next
	ld [WorkingGridPartNumber], A
	ret
