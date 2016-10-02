include "ioregs.asm"
Section "Utilities", ROM0

SpritesBit EQU 1

EnableSprites::
	ld HL, LCDControl
	set SpritesBit, [HL]
	ret
	
DisableSprites::
	ld HL, LCDControl
	res SpritesBit, [HL]
	ret
