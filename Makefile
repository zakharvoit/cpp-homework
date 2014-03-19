AS := nasm
ASFLAGS := -f elf64 -g -F dwarf

EXECUTABLES = add sub mul

all: $(EXECUTABLES)

$(EXECUTABLES): io.o longnumber.o

add: add.o 
sub: sub.o
mul: mul.o

test: $(EXECUTABLES)
	cd testing; ./stress.sh

clean:
	rm -f *.o
	rm -f testing/*.txt
	rm -f $(EXECUTABLES)

