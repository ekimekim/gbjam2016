
# avoid implicit rules for clarity
.SUFFIXES: .asm .o .gb
.PHONY: run clean

ASMS := $(wildcard *.asm)
OBJS := $(ASMS:.asm=.o)

%.o: %.asm
	rgbasm -v -o $@ $^

game.gb: $(OBJS)
	rgblink -n game.sym -o $@ $^
	rgbfix -v -p 0 $@

run: game.gb
	bgb $<

clean:
	rm *.o *.sym game.gb

all: game.gb
