include "ioregs.asm"
include "hram.asm"

section "Main", ROM0

; Actual execution starts here
Start::
	DI ; disable interrupts until we set a few things up

	; Set stack to top of internal RAM
	ld SP, StackTop

	; Initialize HRAM
	call LoadHRAMData

	; Initialize game state
	call LoadScenarioSpiral
	call RenderBlocks
	call ClearWorkingSprites

	; Disable background while we're fucking with vram
	xor A
	ld [LCDControl], A

	; Initialize VRAM
	call LoadTileData
	call ClearSpriteData
	; We have to call vblank update routine 3 times since it only does a third each time
	; (since under normal circumstances it has to fit in VBlank)
	call CopyWorkingVars
	call CopyWorkingVars
	call CopyWorkingVars

	; Initialize other settings
	; Set pallettes
	ld A, %11100100
	ld [TileGridPalette], A
	ld [SpritePaletteTransparent], A
	ld [SpritePaletteSolid], A

	; Set up display
	ld A, %10010011 ; window off, background and sprites on, use signed tile map
	ld [LCDControl], A
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

	; run simulation step at 8Hz (slow counter updates at 64hz, so we look for the 3 lowest bits = 0)
	ld A, [TimerCounterSlow]
	and %00000111
	jr nz, .skipRunStep
	call RunStep
	call RenderBlocks
.skipRunStep

	ret
