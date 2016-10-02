
INCLUDE "vram.asm"
INCLUDE "ioregs.asm"

Section "Tile Assets", ROMX, BANK[1]

TileMapData:
INCLUDE "assets.asm"
EndTileMapData:

TileMapDataSize EQU EndTileMapData - TileMapData

Section "Tile Loading methods", ROMX, BANK[1]

; Blocks until the start of the next VBlank period
; Clobbers HL.
WaitForVBlank:
	ld HL, InterruptFlags
    res 0, [HL] ; reset VBlank flag
.wait
    bit 0, [HL] ; set zero if bit 0 of [HL] is not set
    jr z, .wait
	ret

; Copies tile data into vram. VBlank interrupt should be disabled.
LoadTileData::
	ld HL, TileMapData
	ld DE, BaseTileMap
	ld BC, TileMapDataSize

.loop
	; check if we're still in vblank
	ld A, [LCDStatus]
	and %00000011 ; get mode only
	cp $01
	jr z, .inVBlank
	push HL
	call WaitForVBlank
	pop HL
.inVBlank
	; copy a byte
	ld A, [HL+]
	ld [DE], A
	inc DE
	dec BC
	xor A
	cp C
	jr nz, .loop
	cp B
	jr nz, .loop
	ret
