
Section "test level", ROM0

TestLevel:
include "scenarios.asm"
EndTestLevel::
TestLevelSize EQU EndTestLevel - TestLevel

LoadTestLevel::
	ld BC, TestLevelSize
	ld HL, TestLevel
	ld DE, Level
.loop
	ld A, [HL+] ; also increments HL
	ld [DE], A
	inc DE
	dec BC
	xor A
	cp C
	jr nz, .loop
	cp B
	jr nz, .loop
	ret
