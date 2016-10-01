
; Block structure:
; uint8 fuel
; uint8 temperature
; uint8 flags:
;   0-1: Type:
;        0: Grass
;        1: Tree
;        2: Building
;   2-3: Variant (used for tile selection)

section "Level data", "WRAM0"
; Level is array of 32x32 blocks, each block is 3 bytes
; Total of 1024 blocks = 3072 bytes = $c00 bytes
Level::
	ds $c00

; note on tile layout:
; TileHighFire: HighFire
; TileMediumFire: GrassMediumFire, TreeMediumFire, BuildingMediumFire
; TileLowFire or TileBurnt or TileNormal or TileLush:
;   16-len array where index %sstt is for tile with type t and variant s

section "Block methods", "ROM0"

; Lookup table from type to lush threshold
LushThresholdTable:
	db $21, $81, $c1

; Determine the tile to render for a given block
; Inputs: HL = block address
; Outputs: A = tile index, HL = block address + 2
BlockToTile::
	ld A, [HL] ; temperature
	inc HL
	ld B, [HL] ; fuel
	inc HL
	ld C, [HL] ; flags
	and $c0 ; get first 2 bits of temp
	cp $c0 ; is fire level 11
	jr nz .medium
	ld A, TileHighFire
	ret
.medium
	cp $80 ; is fire level 10
	jr nz .low
	ld A, C
	and $03 ; get type bits
	add TileMediumFire
	ret
.low
	ld D, TileLowFire
	cp $40 ; is fire level 01
	jr z .addStyle
.nofire
	ld D, TileBurnt
	ld A, B ; load fuel
	cp $09 ; <= 8 is burnt
	jr s .addStyle ; if negative, it's burnt
.notburnt
	ld D, TileNormal
	push HL
	ld HL, LushThresholdTable
	ld A, C
	and $03 ; get type bits
	ld D, 0
	ld E, A
	add HL, DE ; look up type in LushThresholdTable
	ld A, [HL] ; get lush threshold
	pop HL
	cp B ; compare to fuel
	jr s .addStyle ; if negative, not lush
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
	push BC
	call BlockToTile ; put result in A and HL += 2
	pop BC
	ld DE, HL
	ld HL, TileGrid
	add HL, BC ; get index into TileGrid
	ld [HL], A ; write to TileGrid
	ld HL, DE
	inc HL
	inc BC
	xor A ; A = 0
	cp C
	jr nz .loop ; is C == 0?
	ld A, $04
	cp B
	jr nz .loop ; is B == 4
	; BC = $0400, we're done
	ret
