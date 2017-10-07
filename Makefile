
# avoid implicit rules for clarity
.SUFFIXES: .asm .o .gb
.PHONY: run clean assets scenarios

ASMS := $(wildcard *.asm)
OBJS := $(ASMS:.asm=.o)
INCLUDES := $(wildcard include/*.asm)

MBC := 0
RAM_SIZE := 0
TITLE := "BURN"

%.o: %.asm $(INCLUDES)
	rgbasm -i include/ -v -o $@ $<

game.gb: $(OBJS)
	rgblink -n game.sym -o $@ $^
	rgbfix -j -l 51 -m $(MBC) -r $(RAM_SIZE) -t $(TITLE) -v -p 0 $@

bgb: game.gb
	bgb $<

clean:
	rm *.o *.sym game.gb

assets:
	pngtoasm -o include/assets.asm -src assets -debug red -ignore red

scenarios:
# use "-defdefault FF FF FF" to define default tile type
	scenariotoasm -o include/scenariosdata.asm -defpng scenario/defs/blocks.png -defcsv scenario/defs/blocks.csv -s scenario/scenarios -defdefault 20 18 00
	
all: game.gb
