
Section "Scenarios", ROM0

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

LoadScenarioHL::
	;HL should be set to target level
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


include "scenariosdata.asm"