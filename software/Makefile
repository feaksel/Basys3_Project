CC = riscv64-linux-gnu-gcc
OBJCOPY = riscv64-linux-gnu-objcopy
CFLAGS = -march=rv32i -mabi=ilp32 -nostdlib -nostartfiles -static -Iinclude -T linker.ld

build/blink:
	mkdir -p build
	$(CC) $(CFLAGS) -o build/blink.elf src/start.s src/system.c src/programs/blink.c
	$(OBJCOPY) -O verilog build/blink.elf build/blink.hex

clean:
	rm -rf build/

.PHONY: clean
