
INCLUDE "vram.asm"
INCLUDE "tiledefs.asm"

; Block structure:
; uint8 fuel
; uint8 temperature
; uint8 flags:
;   0-1: Type:
;        0: Grass
;        1: Tree
;        2: Building
;   2-3: Variant (used for tile selection)

section "Level data", WRAM0
; Level is array of 32x32 blocks, each block is 3 bytes
; Total of 1024 blocks = 3072 bytes = $c00 bytes
Level::
	ds $c00
; for testing, let's define our own vram so we don't need to think about vblank

section "test tile grid", WRAMX
TestTileGrid::
	ds $400

; note on tile layout:
; TileHighFire: HighFire
; TileMediumFire: GrassMediumFire, TreeMediumFire, BuildingMediumFire
; TileLowFire or TileBurnt or TileNormal or TileLush:
;   16-len array where index %sstt is for tile with type t and variant s

section "Block methods", ROM0

; Lookup table from type to lush threshold
LushThresholdTable:
	db $20, $80, $c0

; Determine the tile to render for a given block
; Inputs: HL = block address
; Outputs: A = tile index, HL = block address + 2
BlockToTile::
	ld A, [HL+] ; temperature (since it's A and HL, we can make a micro-optimization to inc at the same time)
	ld B, [HL] ; fuel
	inc HL
	ld C, [HL] ; flags
	and $c0 ; get first 2 bits of temp
	cp $c0 ; is fire level 11
	jr nz, .medium
	ld A, TileHighFire
	ret
.medium
	cp $80 ; is fire level 10
	jr nz, .low
	ld A, C
	and $03 ; get type bits
	add TileMediumFire
	ret
.low
	ld D, TileLowFire
	cp $40 ; is fire level 01
	jr z, .addStyle
.nofire
	ld D, TileBurnt
	ld A, B ; load fuel
	; fuel < 8?
	and %11111000 ; sets the zero flag if the result is zero, ie. A < 8
	jr z, .addStyle ; if < 8, it's burnt
.notburnt
	ld DE, LushThresholdTable
	ld A, C
	and $03 ; get type bits
	; DE += A
	add E ; sets carry
	ld E, A
	ld A, D
	adc $0 ; add 0 with carry
	ld D, A
	; DE now equals DE + A
	ld A, [DE] ; get lush threshold
	ld D, TileNormal
	; compare threshold to fuel
	sub B ; A = (threshold - fuel)
	and %10000000 ; examine top bit: 0 is positive, 1 is negative
	jr z, .addStyle ; if negative, threshold < fuel, so lush
.lush
	ld D, TileLush
.addStyle
	ld A, C ; load flags
	and $0f ; get style + type
	add D ; add tile base
	ret


; for each block in level; write appropriate tile to TileGrid
RenderBlocks::
	ld BC, $0000
	ld HL, Level
.loop
	ld DE, TestTileGrid
	; DE = TileGrid + BC to get index into tilegrid
	ld A, TestTileGrid & $ff ; lower byte
	add C ; possibly set carry
	ld E, A
	ld A, (TestTileGrid & $ff00) >> 8 ; higher byte
	adc B ; A = TileGrid upper + B + carry
	ld D, A
	push BC
	push DE
	call BlockToTile ; put result in A and HL += 2
	pop DE
	pop BC
	ld [DE], A ; write to TileGrid
	inc HL
	inc BC
	xor A ; A = 0
	cp C
	jr nz, .loop ; is C == 0?
	ld A, $04
	cp B
	jr nz, .loop ; is B == 4
	; BC = $0400, we're done
	ret
