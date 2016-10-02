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

	; Initialize game state
	call LoadTestLevel

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
	call CopyWorkingGrid ; this part is vblank-sensitive
	ret
