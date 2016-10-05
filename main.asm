include "ioregs.asm"
include "hram.asm"

Section "Stack", WRAM0

StackBottom::
	ds 128
StackTop::

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

	ld B, $00 ; initial setup counts as frame 0, wait for next 8Hz step before doing first step.

.wait:

	halt ; sleep until next interrupt, which means we might be ready to actually do something

.mainloop:

	; run simulation at 8Hz = top 5 bits of TimerCounterSlow, which updates at 64Hz.
	; we have a "last step number" in B which we're waiting for TimerCounterSlow to not equal.

	ld A, [TimerCounterSlow]
	and %11111000 ; get 8Hz "step number" counter
	cp B ; compare to previous step number
	jr z, .wait ; if equal to previous step, sleep until it may have changed

	call UpdateSlow
	jp .mainloop


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


; Called on a timer interrupt at 64Hz. May still be interrupted by VBlank.
Update::
	call UpdateFireman
	ret


; Called at 8Hz by the main loop.
UpdateSlow::
	call RunStep
	call RenderBlocks
	ret
