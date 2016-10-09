include "macros.asm"
include "ioregs.asm"

Section "Title Screen Sprite Init Data", ROMX, BANK[1]

StartTitleSprites:
ds 4 ; first sprite is player, will be init elsewhere
EndTitleSprites:
TitleSpriteSize EQU EndTitleSprites - StartTitleSprites

Section "Title Screen methods", ROM0

; Copy title sprites into WorkingSprites
LoadTitleSprites::
	ld HL, StartTitleSprites
	ld DE, WorkingSprites
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
	ld HL, LCDControl
	res 7, [HL]
	REPT 3
	call CopyWorkingVars
	ENDR
	ld HL, LCDControl
	set 7, [HL]

	EI
	; --- enabled interrupts ---
	ret
