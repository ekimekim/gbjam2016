
# avoid implicit rules for clarity
.SUFFIXES: .asm .o .gb

ASMS := $(wildcard *.asm)
OBJS := $(ASMS:.asm=.o)

%.o: %.asm
	rgbasm -v -o $@ $^

game.gb: $(OBJS)
	rgblink -n game.sym -o $@ $^
	rgbfix $@
