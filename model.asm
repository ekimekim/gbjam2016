
include "longcalc.asm"


Section "Model Working RAM", WRAM0

; Stores the new temperature values while calculating a step
NewTemps:
	ds 20*18


Section "Model methods", ROM0


; HL = HL + DE * C
; Multiply DE by C and *add* the result to HL. Does not clobber A, B or C. Clobbers DE.
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

; local macro for Modulo5
_Modulo5Part: MACRO
	sub \1
	jr nc, .noUnderflow\@
	add \1 ; A < \1, revert the subtract
.noUnderflow\@
	ENDM

; A = A mod 5
; NOTE: This function assumes A < 90, since 360/4 = 90 so this is the max value assuming you're
; dividing a block index by 20.
Modulo5:
	; our strategy here is to do A = A - X if A > X for a list of Xs which are multiples of 5,
	; until the result is < 5. By picking X >= max(A)/2, we ensure the result A < X.
	; For example, when max(A) is 45, picking 25 gives us either A was already < 25, or 25 <= A < 45
	; so afterwards 0 <= A < 20, so between the two options we conclude A < 25.
	; This is, essentially, a binary search.
	_Modulo5Part 45 ; A < 45
	_Modulo5Part 25 ; A < 25
	; towards the end, we're basically just scanning linearly. But meh.
	_Modulo5Part 15 ; A < 15
	_Modulo5Part 10 ; A < 10
	; special final case to shave an instruction
	sub 5
	ret nc ; A was 5 <= A < 10, so now 0 <= A < 5 and we're done
	add 5 ; A was 0 <= A < 5, so restore it and we're done
	ret


; Run simulation step for block with index DE
; Here is the algorithm for each block as currently coded:
; If temp > 64, the block burns:
;   Burn rate = temp * (fuel + 16) / 3072
;   If burn rate > fuel, burn rate = fuel
;   New fuel = fuel - burn rate
;   New temp = temp + burn rate * 3
RunStepOneBlock:
	; As a test, all we do here is set new temp to be temp + fuel/16

	; get block addr, put it in HL
	ld HL, Level
	push DE ; We're about to modify DE, save block index for later
	; Need to get index*3 as blocks are 3 bytes
	LongAdd H,L, D,E, H,L ; HL = Level + index
	LongShiftL D,E ; DE = 2*index
	LongAdd H,L, D,E, H,L ; HL = Level + 3*index

	; get temp and fuel
	ld B, [HL] ; temp
	inc HL
	ld C, [HL] ; fuel

	; do we burn? (temp >= 64)
	ld A, B
	and %11000000
	jr z, .noburn

	; calculate burn rate: temp * (fuel + 16) / 3072
	ld A, C
	add $10 ; fuel + 16
	jr nc, .fuelAddNoOverflow
	ld A, $ff ; overflow, cap at 255
.fuelAddNoOverflow
	push HL ; save block fuel address for later
	push BC ; save temp and fuel for later
	ld C, A ; C = fuel+16
	ld HL, $0000
	; DE = 00 temp
	ld D, $00
	ld E, B
	call Multiply ; HL = temp * (fuel+16)
	; divide by 3072. Break 3072 down into 256 * 4 * 3 and divide by each seperately.
	ld A, H ; only take high byte, effectively dividing by 256
	ld D, $00
	ld E, A ; See below, this is an optimization for the later divide. We're setting DE = 00 (undivided burn rate/256)
	srl A
	srl A ; divide by 4 by shifting right twice

	; Divide by 3. This is the hard part.
	; Our approach here is to do (x/3) * (256/256), rearrange to (x * (256/3)) / 256
	; Now we're dividing a constant. 256/3 = 85 = %01010101
	; So now we just do x * 85 and take the higher byte of the result
	; However, due to rounding weirdness, this causes eg. x=3 to come out as $00ff not $0100,
	; so we also do proper rounding here by adding 127 to the lower byte and adding one if it carries.

	; We could just use Multiply for this, but hard-coding the known bits of 85 makes it faster
	ld H, 0
	ld L, A ; HL = x
	; We saved the original value of (undivided burn rate / 256) in E above, we reuse it now
	; to save us doing a multiply by 4
	ld A, E
	; add 00 A to HL
	add L ; possibly set carry
	ld L, A
	ld A, H
	adc $00 ; if carry set, add 1
	ld H, A
	; Our current state: HL = 5*x, DE = 4*x
	LongShiftL D,E
	LongShiftL D,E ; DE = 16*x
	LongAdd H,L, D,E, H,L ; HL = 21*x
	LongShiftL D,E
	LongShiftL D,E ; DE = 64*x
	LongAdd H,L, D,E, H,L ; HL = 85*x
	ld A, L
	add $7f ; set carry flag if L > 128
	ld A, H
	adc $0 ; add 1 to result if carry flag set
	; A now contains final burn rate. Phew!

	pop BC ; restore B = temp, C = fuel
	pop HL ; restore HL = block's fuel address
	ld D, A ; save burn rate in D
	ld A, C
	sub D ; fuel = fuel - burn rate. set carry if it goes negative
	jr nc, .enoughFuel
	; fuel went negative, ie. we don't have enough fuel for that burn rate. So set burn rate to remaining fuel.
	ld D, C
	ld A, 0 ; we're burning all the remaining fuel, new fuel = 0
.enoughFuel
	ld [HL], A ; set new fuel level

	; Add 3 * burn rate to temp
	ld A, B ; A = temp
	add D ; A = temp + burn rate
	jr c, .maxTemp ; check for overflow
	sla D ; D = burn rate * 2
	add D ; A = temp + burn rate * 3
	jr nc, .noMaxTemp ; check for overflow again
.maxTemp
	; we exceeded 255, so cap to 255
	ld A, $ff
.noMaxTemp

	; we don't need fuel anymore, let's put new temp so far into C
	ld C, A
	jp .afterburn

.noburn
	ld C, B ; temp so far = old temp
.afterburn

	; calculate how much heat transfer as temperature / 32
	REPT 5
	srl B
	ENDR

	; get it working now, fast later!

	pop DE
	push BC ; save transfer and new temp so far
	push DE ; restore and re-save block index

	ld C, 4 ; we'll use this flag to count our neighbors

	; upper neighbor
	ld A, D
	and A
	jr nz, .upperNeighbor
	ld A, E
	cp 20 ; if we borrow (carry), DE < 20 and so we're in the first row
	jr c, .noUpperNeighbor
.upperNeighbor
	LongSub D,E, 0,20, D,E
	call TransferNeighbor
	dec C

.noUpperNeighbor
	pop DE
	push DE ; restore and re-save block index

	LongAdd D,E, 0,20, D,E
	ld A, D
	cp $01
	jr nz, .lowerNeighbor ; if D != 1, we definitely have a lower neighbor
	ld A, E
	cp $68
	jr nc, .noLowerNeighbor ; if D == 1 and E >= $68, we're off the end, no lower neighbor
.lowerNeighbor
	call TransferNeighbor
	dec C

.noLowerNeighbor

	; Check for side neighbors by checking if index % 20 == 0 or 19
	; We start by looking at index % 4. If 1 or 2, we're done (index % 20 can't be 0 or 19).
	; Else, we move on to calculating index/4 % 5. If index % 4 == 0 and index/4 % 5 == 0, index % 20 == 0.
	; If index % 4 == 3 and index/4 % 5 == 4, index % 20 == 19.

	pop DE
	push DE ; restore and re-save block index

	; mod 4 is very easy - take the last two bits
	ld A, E
	and %00000011
	jr z, .checkMod5Zero ; note that A = 0, so we're looking to compare (index/4)%5 to 0 at .checkMod5Zero
	cp $03
	jr nz, .hasBothSideNeighbors
.checkMod5Four
	ld A, $04 ; we're looking to compare (index/4)%5 to 4
.checkMod5Zero
	; divide index by 4
	LongShiftR D,E
	srl E ; since max index is $167, (max index)/2 = $b3, which fits in 8 bits, so D must be 0.
	ld D, A ; save target modulo in D
	ld A, E
	call Modulo5 ; A = (index/4) % 5
	cp D ; compare (index/4) % 5 to target, set Z if equal
	jr nz, .hasBothSideNeighbors
	and A ; set Z if A = 0. This means A = 0 and D = 0 (or else we would've jumped above) and we have no left neighbor
	jr z, .hasRightNeighborOnly
	; otherwise this means A = 4 and D = 4, so we have no right neighbor

.hasLeftNeighborOnly
	pop DE
	push DE ; restore and re-save block index
	dec DE ; left neighbor = index - 1
	call TransferNeighbor
	dec C
	inc DE ; make sure block index is set correctly again
	jp .afterNeighbors

.hasBothSideNeighbors
	pop DE
	push DE ; restore and re-save block index
	dec DE ; left neighbor = index - 1
	call TransferNeighbor
	dec C

.hasRightNeighborOnly
	; DE might not be set yet, so we have to do this again
	pop DE
	push DE ; restore and re-save block index
	inc DE ; right neighbor = index + 1
	call TransferNeighbor
	dec C
	dec DE ; make sure block index is set correctly again

.afterNeighbors
	; all code paths above lead to DE = block index here.
	; TODO upto check side neighbors, check value of C, subtract temp

WhenYouSeeThisCShouldHaveNeighbors:
	nop
	nop
	nop

	; calculate NewTemps address
	ld HL, NewTemps
	pop DE ; restore block index
	LongAdd H,L, D,E, H,L

	pop BC ; restore new temp to C

	; add final temp to NewTemps
	ld A, [HL]
	add C
	jr nc, .noMaxTemp2 ; check overflow
	; exceeded 255, cap to 255
	ld A, $ff
.noMaxTemp2
	ld [HL], A

	ret


; DE = neighbor's block index, B = amount to transfer
; Clobbers A, HL.
TransferNeighbor:
	ld HL, NewTemps
	LongAdd H,L, D,E, H,L
	ld A, [HL]
	add B
	jr nc, .noOverflow
	ld A, $ff
.noOverflow
	ld [HL], A
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

	; call RunStepOneBlock for each index
	ld DE, 20*18 - 1
.steploop
	push DE ; save it since RunStepOneBlock will clobber everything
	call RunStepOneBlock
	pop DE
	dec DE
	xor A
	cp E
	jr nz, .steploop
	cp D
	jr nz, .steploop
	call RunStepOneBlock ; one last call with index 0

	; now update temperatures according to NewTemps
	ld BC, 20*18
	ld HL, NewTemps
	ld DE, Level
.updateloop
	ld A, [HL+]
	ld [DE], A
	; DE += 3 - 3 incs is faster than a 16-bit add
	REPT 3
	inc DE
	ENDR
	dec BC
	xor A
	cp C
	jr nz, .updateloop
	cp B
	jr nz, .updateloop

	ret
