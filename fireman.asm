include "vram.asm"
include "ioregs.asm"
include "longcalc.asm"
include "hram.asm"

section "Fireman", ROM0

;E used for joypad
;HL sprite
;A sprite changes
;C position dirty
UpdateFireman::

	;load joy state
	call LoadDPad
	ld A, [JoyIO]
	ld E, A

	;;HACK DOWN AND RIGHT ARE PRESSED
	;;x3, Down, Up, Left, Right
	;ld E, %0001010
	;;HACK - PRESS DOWN RIGHT
	;;ld E, %0110000

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
	ld [HL+], A ; also reposition HL to point to X

	;--- START X ---
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
	ld [HL+], A ; also reposition HL to point to tile index

	;--- SET TILE INDEX ---

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
	ld [HL+], A
	jp .setTileIndexFinish

.useAltTile
	; use tile 1
	ld a, %00001111
	ld [HL+], A
	jp .setTileIndexFinish

.useIdleTile
	; use tile -1
	ld a, %00001101
	ld [HL+], A
	jp .setTileIndexFinish

.setTileIndexFinish
	; note that HL is incremented in one of the 3 paths above, and now points to sprite flags

	;--- SET SPRITE FLAGS ---
	ld [HL], 0 ;use transparent palette

	;--- load buttons state ---
	call LoadButtons
	ld A, [JoyIO]
	ld E, A

	;;HACK - PRESS A
	;;ld E, %0111010
	
	; flame amount
	ld C, 0
	
	;--- PRESS A ---
	bit 0, E
	jp nz, .pressAFinish ; skip to end

	inc C
	inc C
	inc C
	
.pressAFinish
	
	;--- PRESS B ---
	bit 1, E
	jp nz, .pressBFinish ; skip to end

	dec C
	dec C
	dec C
.pressBFinish
	
	
	;--- SET BLOCKS ON FIRE ---
	; abcdehl
	
	jp .dondebug
.dondebug
	
	; upper bounds check
	ld A, [WorkingSprites] ;get y pos
	; divide by 8
	SRL A
	SRL A
	SRL A
	
	sub 2 ;removed y offset
	jp c, .burnFinished; ;within bounds?
	
	cp 18
	jp nc, .burnFinished ;within bounds?
	
	;stash delta burn
	ld B, C 
	
	;get y block pos
	ld C, A
	
	ld HL, Level ; level start
	ld DE, 20 * 3 ; size of row
	
	; HL = Level + row size * y pos
	call Multiply
	; HL is now start of target row
	
	; restore delta burn
	ld C, B
	
	; Get x pos
	ld DE, WorkingSprites
	inc DE	
	ld A, [DE]
	; divide by 8
	SRL A
	SRL A
	SRL A
	
	sub 1 ;removed x offset
	jp c, .burnFinished; ;within bounds?
	
	cp 20
	jp nc, .burnFinished ;within bounds?

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

	;--- apply fire ---
	ld A, [HL]
	add C
	jr nc, .applySuccess

	; we either overflowed (if C > 0) or underflowed (if C < 0)
	; C < 0 if the top bit is set
	ld A, C
	and %10000000
	jr z, .overflow
.underflow
	; cap to 0
	ld A, 0
	jr .applySuccess
.overflow
	; cap to 255
	ld A, $ff
.applySuccess
	ld [HL], A

.burnFinished
	ret


;----------------------------	
LoadDPad::

	ld HL, JoyIO
	ld [HL], JoySelectDPad

	ld b, 16
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
