include "vram.asm"
include "ioregs.asm"

section "Main", ROM0

; Actual execution starts here
Start::
	DI ; disable interrupts until we set a few things up

	; Set stack to top of internal RAM
	ld SP, StackTop

	; Initialize HRAM
	call LoadHRAMData

	; Initialize VRAM
	call LoadTileData
	; Set pallettes
	ld A, %11100100
	ld [TileGridPalette], A
	ld [SpritePalette], A

	; Initialize game state
	call LoadTestLevel
	call RenderBlocks

	; Which interrupts we want: Only VBlank
	ld a, %00000001
	ld [InterruptsEnabled], a

	xor a
	ld [InterruptFlags], a ; Cancel pending VBlank so interrupt doesn't fire immediately

	; ok, we're good to go
	EI

	jp HaltForever


; Called upon vblank
Draw::
	push AF
	push BC
	push DE
	push HL
	call CopyWorkingVars; this part is vblank-sensitive
	pop HL
	pop DE
	pop BC
	pop AF
	reti
