include "vram.asm"
include "ioregs.asm"

include "hram.asm"

section "Fireman", ROM0

;E used for joypad
;HL sprite
;A sprite changes
UpdateFireman::

	call LoadDPad
	
	;load joy data
	ld A, [JoyIO]
	ld E, A 
	
	;HACK DOWN AND RIGHT ARE PRESSED
	;x3, Down, Up, Left, Right
	;ld E, %0001010
	
	;check joypad
	bit 4, E
	ret nz ; no joy
	
	;--- START Y ---
	ld HL, WorkingSprites 
	ld A, [HL]
	
	;--- MOVE DOWN ---
	bit 3, E
	jp nz, .moveDownFinish ; skip to end
	
	inc A
.moveDownFinish

	;--- MOVE UP ---
	bit 2, E
	jp nz, .moveUpFinish
	
	dec A	
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
.moveRightFinish

	;--- MOVE LEFT--
	bit 1, E
	jp nz, .moveLeftFinish
	
	dec A
.moveLeftFinish
	
	;--- FINISH X ---
	ld [HL], A
	
	;--- SET TILE INDEX ---
	inc HL 
	ld [HL], $0E
	
	;--- SET SPRITE FLAGS ---
	inc HL 
	ld [HL], 0
	
	ret
	
LoadDPad::

	ld HL, JoyIO
	ld [HL], JoySelectDPad

	ld b, 16
.waitStart
	dec b
	jp nz, .waitStart
	
	ret
