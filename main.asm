include "ioregs.asm"
include "hram.asm"

section "Main", ROM0

; Actual execution starts here
Start::
	DI ; disable interrupts until we set a few things up

	call EnableSprites
	
	; Set stack to top of internal RAM
	ld SP, StackTop

	; Initialize HRAM
	call LoadHRAMData

	; Initialize VRAM
	call LoadTileData
	call ClearSpriteData

	; Initialize game state
	call LoadTestLevel
	call RenderBlocks
	call ClearWorkingSprites

	; Initialize other settings
	; Set pallettes
	ld A, %11100100
	ld [TileGridPalette], A
	ld [SpritePalette], A
	; Set timer frequency (16kHz freq = 64Hz interrupt)
	ld A, %00000111 ; enabled, mode 4 (2^14 Hz)
	ld [TimerControl], A

	; Which interrupts we want: VBlank, Timer
	ld a, %00000101
	ld [InterruptsEnabled], a

	xor a
	ld [InterruptFlags], a ; Cancel pending VBlank so interrupt doesn't fire immediately

	; ok, we're good to go
	EI

.mainloop:
	; Reset timer and TimerFired flag
	xor A
	ld [TimerCounter], A ; reset timer
	ld [TimerFired], A ; unset "timer has fired" flag

	call Update

.timerloop
	ld A, [TimerFired]
	and A
	jr nz, .mainloop ; if timer has occurred, time for the next update
	halt ; otherwise wait until next interrupt
	jr .timerloop ; then check again if it was the interrupt we wanted


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


Update::
	call UpdateFireman
	ret
