
# avoid implicit rules for clarity
.SUFFIXES: .asm .o .gb
.PHONY: run clean assets

ASMS := $(wildcard *.asm)
OBJS := $(ASMS:.asm=.o)
INCLUDES := $(wildcard include/*.asm)

%.o: %.asm $(INCLUDES)
	rgbasm -i include/ -v -o $@ $<

game.gb: $(OBJS)
	rgblink -n game.sym -o $@ $^
	rgbfix -v -p 0 $@

bgb: game.gb
	bgb $<

clean:
	rm *.o *.sym game.gb

assets:
	pngtoasm -o include/assets.asm -dir assets -paint 

all: game.gb
