include "vram.asm"
include "ioregs.asm"

section "Main", ROM0

; Actual execution starts here
Start::
	DI ; disable interrupts until we set a few things up

	; Set stack to top of internal RAM
	ld SP, StackTop

	; Wait for first vblank
	ld HL, InterrputFlags
.waitForVBlank
	bit 0, [HL] ; set zero if bit 0 of [HL] is not set
	jr z, .waitForVBlank

	; Initialize VRAM
	call LoadTileData

	; Initialize game state
	call LoadTestLevel

	; ok, we're good to go
	EI

	jp HaltForever


; Called upon vblank
Draw::
	call RenderBlocks
	ret
