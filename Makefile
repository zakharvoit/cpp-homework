AS := nasm
ASFLAGS := -f elf64 -g -F dwarf

EXECUTABLES = add sub mul

all: $(EXECUTABLES)

$(EXECUTABLES): io.o longnumber.o

add: add.o 
sub: sub.o
mul: mul.o

clean:
	rm -f *.o
	rm -f *.txt
	rm -f $(EXECUTABLES)

