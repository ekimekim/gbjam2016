include "macros.asm"
include "hram.asm"

LevelSize EQU 20 * 18 * 3

Section "Scenario Data", ROMX, BANK[1]

StartLevelData:
include "scenariosdata.asm"
EndLevelData:

Section "Scenario loading methods", ROM0

LevelDataSize EQU EndLevelData - StartLevelData
NumLevels EQU LevelDataSize / LevelSize
PRINTT "Got {NumLevels} scenarios\n"

IF LevelDataSize % LevelSize != 0
FAIL "Scenario data is {LevelDataSize} bytes, expected a multiple of {LevelSize}"
ENDC

; Loads a level from an address given in HL. Clobbers all except HL.
LoadScenarioHL::
	ld BC, LevelSize
	ld DE, Level
	LongCopy ; copy BC bytes from [HL] to [DE]
	ret

; Loads scenario with level index given in C. Clobbers all.
LoadScenarioNumber::
	ld DE, LevelSize
	ld HL, StartLevelData
	call Multiply ; HL += DE * C
	call LoadScenarioHL
	ret

; If level is over, load "next" level.
; We define a level as "ended" after 16 slow-update ticks have passed without any fire
; This is tracked in hRAM
CheckLevelEnd::
	; loop through all blocks, check for temp >= 64, exit early if any found
	ld HL, Level
	ld BC, 20*18
.loop
	ld A, [HL+]
	and %11000000
	jr nz, .fireFound
	inc HL
	inc HL ; we incremented HL once above, so 2 more times here for +3 each loop
	dec BC
	xor A
	cp C
	jr nz, .loop
	cp B
	jr nz, .loop

.fireNotFound
	ld A, [LevelEndTickCount]
	inc A
	ld [LevelEndTickCount], A
	cp 16 ; at 8Hz, 2sec
	ret nz ; if we haven't hit enough ticks yet, do nothing
	call Score ; end the level and do scoring
	; fall through to .fireFound to reset LevelEndTickCount

.fireFound
	xor A
	ld [LevelEndTickCount], A
	ret


LoadNextLevel::
	; determine next level
	ld A, [LevelNumber]
	inc A
	cp NumLevels
	jr nz, .noMaxLevel
	xor A ; reset level to 0
.noMaxLevel
	; load next level
	ld [LevelNumber], A
	ld C, A
	call LoadScenarioNumber
	ret
