include "vram.asm"
include "sprites.asm"


section "Main", ROM0

Start::
	; Actual execution starts here

	; Set stack to top of internal RAM
	ld SP, StackTop
	ld HL, BaseTileMap ; test includes
	
	stop
	call ClearScreen;
	
	
	jp HaltForever

	
	
ClearScreen::
	; Set stack to top of internal RAM
	ld SP, StackTop
	
	
	
	ld HL, BaseTileMap
	ld B, 156 ;
	;FOREACH TILE IN 156
.forTile

		ld C, 16
		;FOREACH BYTE IN 16
.forTileByte
			;;Clear sprites
			ld [HL], SpriteBackground
			inc HL
			ld [HL], SpriteBackground
			inc HL
			
			dec C
		jp nz, .forTileByte
		dec B
	jp nz, .forTile

	;Every frame hack
	stop
	jp ClearScreen