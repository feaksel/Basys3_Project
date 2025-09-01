# Toolchain
CC = riscv64-linux-gnu-gcc
OBJCOPY = riscv64-linux-gnu-objcopy
OBJDUMP = riscv64-linux-gnu-objdump

# Target
TARGET = blink
BUILD_DIR = build

# Source files
SRCS = src/start.s src/main.c
OBJS = $(BUILD_DIR)/start.o $(BUILD_DIR)/main.o

# Compiler flags
CFLAGS = -march=rv32i -mabi=ilp32 -nostdlib -fno-builtin -Wall -O1
CFLAGS += -fno-PIC -fno-pie -mno-relax -fno-jump-tables -fno-tree-switch-conversion
ASFLAGS = -march=rv32i -mabi=ilp32
LDFLAGS = -T linker.ld -nostdlib -static -Wl,--no-relax -Wl,--gc-sections

# Build rules
all: $(BUILD_DIR)/$(TARGET).hex

$(BUILD_DIR)/$(TARGET).elf: $(OBJS) linker.ld
	$(CC) $(CFLAGS) $(LDFLAGS) $(OBJS) -o $@

$(BUILD_DIR)/$(TARGET).bin: $(BUILD_DIR)/$(TARGET).elf
	$(OBJCOPY) -O binary --only-section=.text $< $@

$(BUILD_DIR)/$(TARGET).hex: $(BUILD_DIR)/$(TARGET).bin
	hexdump -v -e '1/4 "%08X\n"' $< > $@

$(BUILD_DIR)/start.o: src/start.s
	@mkdir -p $(BUILD_DIR)
	$(CC) $(ASFLAGS) -c -o $@ $<

$(BUILD_DIR)/main.o: src/main.c
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) -c -o $@ $<

# Disassembly for debugging
disasm: $(BUILD_DIR)/$(TARGET).elf
	$(OBJDUMP) -d $<

# Clean
clean:
	rm -rf $(BUILD_DIR)

.PHONY: all clean disasm
