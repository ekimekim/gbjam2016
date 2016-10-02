
INCLUDE "hram.asm"
INCLUDE "vram.asm"

Section "Working Background Grid", WRAMX

; WorkingGrid is a copy of the TileGrid in vRAM
; You should write things here for later copying to true vRAM on a VBlank
WorkingGrid::
	ds $400

Section "VBlank Drawing Routine", ROM0

; We draw a quarter of the screen at a time, that's all we have time for
; We track the current quarter in WorkingGridPartNumber
CopyWorkingGrid::
	ld A, [WorkingGridPartNumber]
	add (WorkingGrid & $ff00) >> 8 ; get upper byte of WorkingGrid + part number
	ld H, A
	ld L, $0
	ld A, [WorkingGridPartNumber]
	add (TileGrid & $ff00) >> 8 ; get upper byte of TileGrid + part number
	ld D, A
	ld E, 0

.loop
	; A modest amount of unrolling
	REPT 8
	ld A, [HL+]
	ld [DE], A
	inc E
	ENDR
	jr nz, .loop ; break when E has fully wrapped

	ld A, [WorkingGridPartNumber]
	inc A
	and %00000011
	ld [WorkingGridPartNumber], A
	ret
