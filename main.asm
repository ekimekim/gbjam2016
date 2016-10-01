include "vram.asm"


section "Main", ROM0

Start::
	; Actual execution starts here

	; Set stack to top of internal RAM
	ld SP, StackTop

	call LoadTestLevel

	jp HaltForever
