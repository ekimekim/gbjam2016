
INCLUDE "vram.asm"
INCLUDE "ioregs.asm"

Section "Tile Assets", ROMX, BANK[1]

TileMapData:
INCLUDE "assets.asm"
EndTileMapData:

TileMapDataSize EQU EndTileMapData - TileMapData

Section "VRAM Init methods", ROMX, BANK[1]

; Blocks until the start of the next VBlank period
; Clobbers HL.
WaitForVBlank:
	ld HL, InterruptFlags
    res 0, [HL] ; reset VBlank flag
.wait
    bit 0, [HL] ; set zero if bit 0 of [HL] is not set
    jr z, .wait
	ret

; Checks that you are in vblank and waits if needed
; Clobbers A, HL
EnsureVBlank:
	; check if we're in vblank
	ld A, [LCDStatus]
	and %00000011 ; get mode only
	cp $01
	ret z
	; we're not in vblank, wait until we are then return
	call WaitForVBlank
	ret

; Copies tile data into vram. VBlank interrupt should be disabled.
LoadTileData::
	ld HL, TileMapData
	ld DE, BaseTileMap
	ld BC, TileMapDataSize

.loop
	push HL
	call EnsureVBlank
	pop HL
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

; Write zeroes to sprite data
ClearSpriteData::
	; We should be fast enough to do this in one vblank, if we start at the beginning
	ld B, 40 * 4 ; length of sprite table
	xor a
	call WaitForVBlank
	ld HL, SpriteTable
.loop
	ld [HL+], a
	dec b
	jr nz, .loop
	ret
