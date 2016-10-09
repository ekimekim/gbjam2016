include "vram.asm"
include "ioregs.asm"
include "longcalc.asm"
include "hram.asm"

Section "Fireman Working RAM", WRAM0

LastInput:
	ds 0

Section "Fireman Methods", ROM0

InputWait EQU 4
BurnAmount EQU 16
MinBurnAmount EQU 64
CoolAmount EQU 16


UpdateFireman::

	;load joy state
	call LoadDPad
	ld A, [JoyIO]
	ld E, A

	; is pos dity = false
	ld C, 0
	
	;--- START Y ---
	ld HL, WorkingSprites
	ld A, [HL]

	;--- MOVE DOWN ---
	bit 3, E
	jp nz, .moveDownFinish ; skip to end

	inc A
	inc C ; Dirty position
.moveDownFinish

	;--- MOVE UP ---
	bit 2, E
	jp nz, .moveUpFinish

	dec A
	inc C ; Dirty position
.moveUpFinish

	;--- FINISH Y ---
	ld [HL], A

	;--- START X ---
	inc HL
	ld A, [HL]

	;--- MOVE RIGHT --
	bit 0, E
	jp nz, .moveRightFinish

	inc A
	inc C ; Dirty position
.moveRightFinish

	;--- MOVE LEFT--
	bit 1, E
	jp nz, .moveLeftFinish

	dec A
	inc C ; Dirty position
.moveLeftFinish

	;--- FINISH X ---
	ld [HL], A

	;--- SET TILE INDEX ---
	inc HL

	; go to idle if no move
	ld A, C
	and A
	jp z, .useIdleTile

	; sample some amount of time
	ld A, [TimerCounterSlow]
	and A, %00000010

	jp nz, .useAltTile

	; use tile 0
	ld A, %00001110
	ld [HL], A
	jp .setTileIndexFinish

.useAltTile
	; use tile 1
	ld a, %00001111
	ld [HL], A
	jp .setTileIndexFinish

.useIdleTile
	; use tile -1
	ld a, %00001101
	ld [HL], A
	jp .setTileIndexFinish

.setTileIndexFinish

	;--- SET SPRITE FLAGS ---
	inc HL
	ld [HL], 0 ;use transparent palette

	;--- load buttons state ---
	call LoadButtons
	ld A, [JoyIO]
	
	ld HL, LastInput
	ld B, [HL]

	cp B 
	jp z, .burnFinished ; input unchanged
	
	; input changed! 
	ld [LastInput], A
	

	bit 3, A ; pressing Start button
	jp nz, .noStartButton
	ld B, A ; store Joy state for safekeeping
	ld A, [LevelNumber]
	and A
	jp nz, .noTitleScreen ; check if level is 0 (title screen)
	ld A, 1
	ld [EndTitleScreenFlag], A
.noTitleScreen
	ld A, B ; restore Joy state
.noStartButton

	bit 0, A
	jp z, .anyInputDetected ; pressing A button;
	bit 1, A
	jp z, .anyInputDetected ; pressing B button
	
	; buttons were released
	jp .burnFinished 

.anyInputDetected
	
	;--- SET BLOCKS ON FIRE ---

	;Get x pos
	ld DE, WorkingSprites
	inc DE	
	ld A, [DE]
	; divide by 8
	SRL A
	SRL A
	SRL A
	
	;remove x offset
	sub 1 
	jp c, .burnFinished ; out of bounds
	
	cp 20
	jp nc, .burnFinished ; out of bounds

	; HL = x pos
	ld H, 0
	ld L, A

	; get pixel y
	ld A, [WorkingSprites] 
	; get block y, divide by 8 
	SRL A
	SRL A
	SRL A

	; remove y offset
	sub 2 
	jp c, .burnFinished; ; out of bounds

	cp 18
	jp nc, .burnFinished ; out of bounds

	;get y block pos
	ld C, A
	
	ld DE, 20 ; size of row
	
	; HL = x pos + row size * y pos
	call Multiply
	ld D, H
	ld E, L
	; DE is now block index

	ld A, [LastInput]
		
	bit 0, A
	jp z, .buttonAInputDetected ; pressing A button
	bit 1, A
	jp z, .buttonBInputDetected ; pressing B button
	
	jp .burnFinished
	
.buttonAInputDetected
	ld C, 0
	ld A, BurnAmount
	jr .after

.buttonBInputDetected
	ld C, 1
	ld A, CoolAmount
	
.after
	ld B, A

	; If we aren't inside RunStep, apply the temp straight away
	ld A, [RunStepStateFlag]
	and A
	jr nz, .addToActionsToDo

	ld HL, Level
	REPT 3
	LongAdd H,L, D,E, H,L
	ENDR
	; HL = addr of temp of block

	ld A, C
	and A
	jr nz, .subTempDirect

.addTempDirect
	ld A, [HL]
	cp MinBurnAmount
	jp nc, .alreadyOnFire
		
	; players need to see an change, if temp < 64 set temp = 64
	ld A, MinBurnAmount
	ld [HL], A
	jr .burnFinished
.alreadyOnFire
	ld B, BurnAmount
	ld A, [HL]
	add B
	jr nc, .noOverflowAddDirect
	ld A, $ff
.noOverflowAddDirect
	ld [HL], A
	jr .burnFinished

.subTempDirect
	ld A, [HL]
	sub B
	jr nc, .noUnderflowSubDirect
	ld A, 0
.noUnderflowSubDirect
	ld [HL], A
	jr .burnFinished

.addToActionsToDo

	; convert B to signed
	ld A, C
	and A
	jr z, .noSub
	xor A
	sub B
	ld B, A ; B = -B
.noSub

	ld HL, ActionsToDo
	ld C, 4

.loopToDo
	; check if index match
	ld A, [HL+]
	cp D
	jr nz, .noMatch
	ld A, [HL]
	cp E
	jr z, .match
.noMatch
	dec HL ; reset HL to start of current entry
	; check if empty
	ld A, [HL+]
	cp $ff
	jr nz, .next
	ld A, [HL]
	cp $ff
	jr nz, .next
.empty
	dec HL
	ld [HL], D
	inc HL
	ld [HL], E ; set entry index = this block's index
.match
	inc HL
	; HL = entry value, B = signed amount to add
	ld A, [HL]
	add B ; we are assuming this won't go outside range of -128 to 127
	ld [HL], A
	jr .burnFinished
.next
	dec C
	jr nz, .loopToDo
	; if we got this far and all actions full, just discard input

.burnFinished
	ret


;----------------------------	
LoadDPad::

	ld HL, JoyIO
	ld [HL], JoySelectDPad

	ld b, InputWait
.waitStart
	dec b
	jp nz, .waitStart

	ret

;----------------------------	
LoadButtons::

	ld HL, JoyIO
	ld [HL], JoySelectButtons

	ld b, InputWait
.waitStart
	dec b
	jp nz, .waitStart

	ret


; Set the player sprite's X and Y coords to the starting position
InitFireman::
	ld A, 8*11 + 16
	ld HL, WorkingSprites
	ld [HL+], A ; Y = 11
	ld A, 8*10 + 8
	ld [HL+], A ; X = 10
	ld A, %00001101
	ld [HL+], A ; tile = idle player
	xor A
	ld [HL], A ; flags = 0
	ret
