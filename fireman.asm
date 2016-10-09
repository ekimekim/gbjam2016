include "vram.asm"
include "ioregs.asm"
include "longcalc.asm"
include "hram.asm"

;Section "Fireman Working RAM", WRAM0

; Stores the new temperature values while calculating a step
;LastInput:
;	ds 0

Section "Fireman Methods", ROM0

BurnAmount EQU 2
MinBurnAmount EQU 60
CoolAmount EQU 10

;E used for joypad
;HL sprite
;A sprite changes
;C position dirty
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
;	ld A, [JoyIO]
	
;	ld HL, LastInput
;	ld B, [HL]

;	xor B
	
;	bit 0, A
;	jp z, .burnFinished ; input unchanged
;	bit 1, A
;	jp z, .burnFinished ; input unchanged

	; input changed! 
	ld A, [JoyIO]

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
	
	ld HL, Level ; level start
	ld DE, 20 * 3 ; size of row
	
	; HL = Level + row size * y pos
	call Multiply
	; HL is now start of target row
	
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

	;--- offset x --
	ld B, A
	sla B ; B = offset x * 2
	add B ; A = offset x + offset x * 2 = offset x * 3. we know this won't carry, offset x too small
	; HL += 3 * offset x
	add L ; maybe set carry
	ld L, A
	ld A, H
	adc 0 ; add 1 if carry set
	ld H, A

	;--- apply fire to HL ---
	ld A, [JoyIO]
		
	bit 0, A
	jp z, .buttonAInputDetected ; pressing A button
	bit 1, A
	jp z, .buttonBInputDetected ; pressing B button

	; was IO modified in interrupt?
	jp .burnFinished
	
.buttonAInputDetected
	ld A, [HL]
	cp MinBurnAmount
	jp nc, .alreadyOnFire
		
	;players need to see an change
	ld A, MinBurnAmount
	
.alreadyOnFire
	
	ld B, BurnAmount
	add B
	
	jp nc, .applyAToHL ; added fire
	; too much fire
	ld A, 255
	
	jp .applyAToHL ; done

.buttonBInputDetected
	ld A, [HL]
	ld B, CoolAmount
	sub B
	
	jp nc, .applyAToHL ; added cool
	; too much cool
	ld A, 0
	
	; done
	
.applyAToHL
	ld [HL], A
	
.burnFinished
	ret


;----------------------------	
LoadDPad::

	ld HL, JoyIO
	ld [HL], JoySelectDPad

	ld b, 8
.waitStart
	dec b
	jp nz, .waitStart

	ret

;----------------------------	
LoadButtons::

	ld HL, JoyIO
	ld [HL], JoySelectButtons

	ld b, 16
.waitStart
	dec b
	jp nz, .waitStart

	ret


; Set the player sprite's X and Y coords to the starting position
InitFireman::
	ld A, 8*11
	ld HL, WorkingSprites
	ld [HL+], A ; Y = 11
	ld A, 8*10
	ld [HL+], A ; X = 10
	ld A, %00001101
	ld [HL+], A ; tile = idle player
	xor A
	ld [HL], A ; flags = 0
	ret
