include "ioregs.asm"
Section "Utilities", ROM0

SpritesFlag EQU %00000010

EnableSprites::
	ld A, [LCDControl]
	ld B, SpritesFlag;
	or B
	ld [LCDControl], A
	
	ret
	
DisableSprites::
	ld A, [LCDControl]
	ld B, SpritesFlag;
	xor B
	ld [LCDControl], A
	
	ret
