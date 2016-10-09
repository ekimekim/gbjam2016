include "longcalc.asm"
include "ioregs.asm"
include "tiledefs.asm"
include "hram.asm"

Section "Scoring methods", ROM0

; Sets a flag telling input routine / fast update loop not to run, blanks screen and WorkingGrid
; Should not be called while any interrupts are running, ie. should be called
; only from the main thread.
DisableGameplay::
	; --- disabled interrupts ---
	DI

	ld A, 1
	ld [TimerUpdateLock], A ; disable fast update calls

	; zero WorkingGrid and sprites
	ld B, 18 ; we're going to unroll 10x to do 20 bytes = 1 row at a time
	ld HL, SP+0
	; SP goes in AC for safekeeping
	ld A, H
	ld C, L
	ld D, 0
	ld E, 0
	ld SP, WorkingGrid + (18*20); SP = top of WorkingGrid
.clearGridLoop
	REPT 10 ; repeat 10x, do 2 bytes each loop = 20 bytes = 1 row
	push DE ; sets next 2 bytes to 00
	ENDR
	dec B
	jr nz, .clearGridLoop
	; restore SP from AC
	ld H, A
	ld L, C
	ld SP, HL

	call ClearWorkingSprites

	ld HL, LCDControl
	res 7, [HL] ; turn off screen!

	; force update VRAM and clear sprites
	REPT 3
	call CopyWorkingVars
	ENDR

	ld HL, LCDControl
	set 7, [HL] ; everything's zeroed, safe to turn screen back on

	EI
	; --- enabled interrupts ---
	ret


; Reverses effects of DisableGameplay: Refreshes WorkingGrid from level data, loads it into VRAM,
; then enables fast update loop.
EnableGameplay::
	; --- disabled interrupts ---
	DI

	call RenderBlocks
	call ClearWorkingSprites

	call InitFireman

	ld HL, LCDControl
	res 7, [HL] ; turn off screen!
	REPT 3
	call CopyWorkingVars ; update vram
	ENDR
	ld HL, LCDControl

	; if we're opening the title screen, init title screen stuff
	ld A, [LevelNumber]
	and A
	jr nz, .notTitleScreen
	call LoadTitleSprites
	xor A
	ld [EndTitleScreenFlag], A ; reset title screen end flag
.notTitleScreen

	set 7, [HL] ; turn on screen

	xor A
	ld [TimerUpdateLock], A ; enable fast update calls

	EI
	; --- enabled interrupts ---
	ret


; Call at end of level to score based on data in Level
Score::
	call DisableGameplay

	; Count various aspects of the level:
	; D: Number of unburnt buildings
	; E: Number of unburnt trees
	ld HL, Level+1
	ld BC, 20*18
	ld D, 0
	ld E, 0
.countLoop
	; HL = addr of fuel of block
	ld A, [HL+] ; HL = addr of flags of block
	and %11110000 ; sets zero flag if A < 16, ie. is burnt
	jr z, .countNext
	ld A, [HL]
	and %00000011 ; get type bits only
	cp 1 ; is it a tree?
	jr z, .countTree
	cp 2 ; is it a building?
	jr nz, .countNext
.countBuilding
	inc D
	jr .countNext
.countTree
	inc E
.countNext
	inc HL
	inc HL ; set HL to next block's fuel
	dec BC
	xor A
	cp C
	jr nz, .countLoop
	cp B
	jr nz, .countLoop

	; check for too many tiles to display (D+E > 252)
	; my solution here is a cop-out but probably will never be reached: pretend count is less
	ld A, 252
	sub D
	jr nc, .notTooManyBldg
.tooManyBldg
	ld D, 252
	jr .afterTooMany
.notTooManyBldg
	sub E
	jr nc, .afterTooMany
	add E
	ld E, A ; E = small enough that D+E = 252
.afterTooMany

	; BC = Score
	ld BC, 0

	push DE ; save counts
	call DisplayScore

	pop DE
	push DE ; restore and re-save counts

	; For each building/tree, add some amount to score
	; D = number of current thing to display
	; HL = position in working grid to place next tile in
	; E = X position of HL (should be between 1-18) (one blank space either side)
	ld E, 1
	ld HL, WorkingGrid + (3 * 20) + 1 ; start at (3,1)

	; Macro to help define two near-identical sections below
_DisplayLoop: MACRO ; args \1 = score to add, \2 = tile to display
	; Special case, D = 0 to begin with
	ld A, D
	and A
	jr z, .skipAll\@
.displayLoop\@
	push BC
	call WaitForScoreDelay
	pop BC
	ld [HL], \2 ; display tile
	LongAdd B,C, 0,\1, B,C ; score += score to add
	push BC
	push DE
	push HL
	call DisplayScore
	pop HL
	pop DE
	pop BC
	inc HL ; next actual position
	inc E ; next X position
	ld A, E
	cp 19 ; reached the end of our row space?
	jr nz, .noNextRow\@
	inc HL
	inc HL ; HL += 2 to go from X=19 to X=1 of next row
	ld E, 1
.noNextRow\@
	dec D ; one less thing to display
	jr nz, .displayLoop\@
.skipAll\@
	ENDM

	_DisplayLoop 10, TileNormal + 2 ; normal building variant 1
	ld A, E ; save current X pos
	pop DE ; restore counts
	ld D, E ; count trees this time instead
	ld E, A ; restore X pos
	_DisplayLoop 1, TileNormal + 1 ; normal tree variant 1

	; Wait for A press
.waitForPress
	call LoadButtons
	ld A, [JoyIO]
	bit 0, A ; check for A button == 0 (pressed)
	jr z, .gotPress
	halt ; this will get interrputed by 64Hz timer, which is good enough for a polling interval
	jr .waitForPress
.gotPress

	call LoadNextLevel ; populate Level with new data
	call EnableGameplay ; turn on input, etc and refresh screen

	; Re-sync slow update loop so the first proper tick of the level is 1/8th of a sec
	; from now.
	ld A, [TimerCounterSlow]
	and %11111000
	ld [LastSlowTickNumber], A

	ret


; Displays the number stored in BC in 5 decimal digits at tile position Y=1, X=7 to 11
DisplayScore::

	; I stole this binary -> BCD algo from the internet
	; Simplified example of 8 bits -> 3 digits. Algo is:
	; digits all start at 0 and are 4-bit binary numbers
	; repeat 8 times:
	;   for each digit:
	;     if digit >= 5, digit += 3
	;   shift left, in order, with carry between them:
	;	  binary number, ones digit, tens digit, hundreds digit
	; each 4-bit digit is now a BCD digit

	; in our case, we're going from 16 bits to 5 digits
	; our input is BC. for our digits, let's use DEL (note: only lower half of D is used)
	; (num bits) loop var is H
	ld H, 16
	ld D, 0
	ld E, 0
	ld L, 0

.loop

; args \1 register, \2 is either 0 or 4 (0 to check lower half, 4 to check upper)
; clobbers B!
_Check5: MACRO
	ld A, \1
	and $0f << \2
	cp 5 << \2
	jr c, .lessThan5\@
	add 3 << \2
	ld B, A
	ld A, \1
	and $0f << (4 - \2) ; get opposite half
	or B ; combine with new value for this half
	ld \1, A
.lessThan5\@
	ENDM

	; for each half of each reg D,E,L, check if >= 5 and if so add 3
	push BC
	_Check5 L, 0
	_Check5 L, 4
	_Check5 E, 0
	_Check5 E, 4
	_Check5 D, 0
	pop BC

	; now do a massive left shift across DELBC
	sla C
	rl B
	rl L
	rl E
	rl D

	ld A, H
	dec A
	ld H, A
	jr nz, .loop

	ld C, L ; C is now more convenient than L from here, we want to use HL

	; Now actually display digits in DEC
	ld HL, WorkingGrid + 1*20 + 7 ; start at Y=1, X=7

_DisplayDigit: MACRO ; args \1 register, \2 is either 0 or 1 for lower or upper half
	ld A, \1
IF \2 == 1
	swap A
ENDC
	and $0f ; A = 0-9
	add TileDigits ; A = tile of digit
	ld [HL+], A
	ENDM

	_DisplayDigit D, 0
	_DisplayDigit E, 1
	_DisplayDigit E, 0
	_DisplayDigit C, 1
	_DisplayDigit C, 0

	ret


SCORE_DELAY_MASK EQU %11110000 ; 4Hz
; Wait until a "score delay" time has passed.
; Clobbers A, B
WaitForScoreDelay:
	ld A, [TimerCounterSlow]
	and SCORE_DELAY_MASK
	ld B, A ; B contains old value
.wait
	halt ; pause until timer or something has fired
	; until the slow counter & that mask changes
	ld A, [TimerCounterSlow]
	and SCORE_DELAY_MASK
	cp B
	jr z, .wait ; if they still match, keep waiting
	ret
