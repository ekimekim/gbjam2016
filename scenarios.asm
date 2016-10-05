
Section "Scenario Data", ROMX, BANK[1]

include "scenariosdata.asm"

Section "Scenario loading methods", ROM0

TestLevelSize EQU (20*18*3)

LoadScenarioPaletteTown::
	ld HL, ScenarioPaletteTown
	call LoadScenarioHL
	ret
	
LoadScenarioSpiral::
	ld HL, ScenarioSpiral
	call LoadScenarioHL
	ret

LoadScenarioSouthVillage::
	ld HL, ScenarioSouthVillage
	call LoadScenarioHL
	ret

; Loads a level from an addres given in HL. Clobbers all.
LoadScenarioHL::
	ld BC, TestLevelSize
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

