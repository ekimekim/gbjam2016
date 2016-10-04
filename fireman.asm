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
	ld E, A

	;;HACK - PRESS A
	;;ld E, %0111010
	
	; flame amount
	ld C, 0
	
	;--- PRESS A ---
	bit 0, E
	jp nz, .pressAFinish ; skip to end

	inc C ; Dirty position
.pressAFinish
	
	;--- PRESS B ---
	bit 1, E
	jp nz, .pressBFinish ; skip to end

	dec C ; Dirty position
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
	
	ld HL, 0 ; clear
	ld DE, 60 ;size of row
	
	;60 * y pos
	call Multiply
	
	; HL is now size
	ld DE, Level ; DL is level addr
	; Level + yOffset
	LongAdd H,L, D,E, H,L
	
	;pop delta burn
	ld C, B 
	
	;Get x pos
	ld DE, WorkingSprites
	inc DE	
	ld A, [DE]
	; divide by 8
	SRL A
	SRL A
	SRL A
	
	sub 1 ;removed x offset
	jp c, .burnFinished; ;within bounds?
	
	cp 18
	jp nc, .burnFinished ;within bounds?

	;--- offset x --
	; todo: multiply
.forX
	inc HL
	inc HL
	inc HL
	dec A
	jp nz, .forX

	;--- apply fire ---
	ld A, [HL]
	add C
	
	jp z, .capAt255
	jp .applySuccess
	
.capAt255
	;If went over
	ld A, 255
	jp .applySuccess

.applySuccess

	ld [HL], A

	inc HL
	inc HL
	inc HL

	
.burnFinished
	
	

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