
include "longcalc.asm"


Section "Model Working RAM", WRAM0

; Stores the new temperature values while calculating a step
NewTemps:
	ds 20*18


Section "Model methods", ROM0


; HL = HL + DE * C
; Multiply DE by C and *add* the result to HL. Clobbers all others.
; If you care about speed and both your numbers are 8 bit, put the one that is probably small in C.
Multiply:
	; fully unrolled for speed. god knows it's slow enough.
	bit 0, C
	jr z, .next0
	LongAdd H,L, D,E, H,L
.next0
	LongShiftL D,E
	bit 1, C
	jr z, .next1
	LongAdd H,L, D,E, H,L
.next1
	LongShiftL D,E
	bit 2, C
	jr z, .next2
	LongAdd H,L, D,E, H,L
.next2
	LongShiftL D,E
	bit 3, C
	jr z, .next3
	LongAdd H,L, D,E, H,L
.next3
	LongShiftL D,E
	bit 4, C
	jr z, .next4
	LongAdd H,L, D,E, H,L
.next4
	LongShiftL D,E
	bit 5, C
	jr z, .next5
	LongAdd H,L, D,E, H,L
.next5
	LongShiftL D,E
	bit 6, C
	jr z, .next6
	LongAdd H,L, D,E, H,L
.next6
	LongShiftL D,E
	bit 7, C
	ret z
	LongAdd H,L, D,E, H,L
	ret


; Run simulation step for block with index DE
RunStepOneBlock:
	; As a test, all we do here is set new temp to be temp + fuel/16

	; get block addr, put it in HL
	ld HL, Level
	; Need to get index*3 as blocks are 3 bytes. so inefficient...
	LongAdd H,L, D,E, H,L
	LongAdd H,L, D,E, H,L
	LongAdd H,L, D,E, H,L

	; get temp
	ld B, [HL]
	inc HL
	; get fuel
	ld A, [HL]

	; fuel/16
	and $f0
	swap a
	; add temp
	add B
	ld B, A ; put it in B for safekeeping

	; get new temp addr
	ld HL, NewTemps
	LongAdd H,L, D,E, H,L ; note clobbers A
	; set new temp
	ld [HL], B
	ret


; Zero the NewTemps region
ClearNewTemps:
	ld HL, NewTemps
	ld B, 20*18/8 ; how many loops of 8 to do
	xor A
.loop
	REPT 8
	ld [HL+], A
	ENDR
	dec B
	jr nz, .loop
	ret


; Run a step of the simulation
RunStep::
	call ClearNewTemps
	ld DE, 20*18 - 1
.loop
	push DE ; save it since RunStepOneBlock will clobber everything
	call RunStepOneBlock
	pop DE
	dec DE
	xor A
	cp E
	jr nz, .loop
	cp D
	jr nz, .loop
	call RunStepOneBlock ; one last call with index 0

	; TODO update blocks with newtemps
	ret
