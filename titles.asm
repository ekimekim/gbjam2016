include "macros.asm"
include "ioregs.asm"
include "tiledefs.asm"
include "vram.asm"

Section "Title Screen Sprite Init Data", ROMX, BANK[1]

StartTitleSprites:
; At Y=11.5, X=8.5 to 11.5, 3 tiles "A -> <medium fire house>"
db $6c, $4c, TileA, 0
db $6c, $54, TileArrow, 0
db $6c, $5c, TileMediumFire + 2, 0
; At Y=13.5, X=8.5 to 11.5, 3 tiles "B -> <burnt house>"
db $7c, $4c, TileB, 0
db $7c, $54, TileArrow, 0
db $7c, $5c, TileBurnt + 2, 0
; At Y=15.5, X=7.5 to 12.5, 5 tiles "press start"
db $8c, $44, TilePressStart+0, 0
db $8c, $4c, TilePressStart+1, 0
db $8c, $54, TilePressStart+2, 0
db $8c, $5c, TilePressStart+3, 0
db $8c, $64, TilePressStart+4, 0
EndTitleSprites:
TitleSpriteSize EQU EndTitleSprites - StartTitleSprites

Section "Title Screen methods", ROM0

; Copy title sprites into VRAM, after working sprites
LoadTitleSprites::
	ld HL, StartTitleSprites
	ld DE, SpriteTable + NumSprites * 4
	ld B, TitleSpriteSize
	Copy ; copy B bytes from [HL] to [DE]
	ret


; Show next level without a score screen
EndTitleScreen::
	; --- disabled interrupts ---
	DI

	; screen is now paused. we populate working vars

	call LoadNextLevel
	call RenderBlocks
	call ClearWorkingSprites
	call InitFireman

	; now we turn off the screen, load level data, then turn it on
	call TurnOffScreen
	call ClearSpriteData
	REPT 3
	call CopyWorkingVars
	ENDR
	ld HL, LCDControl
	set 7, [HL]

	ld HL, InterruptFlags
	res 0, [HL]

	EI
	; --- enabled interrupts ---
	ret
