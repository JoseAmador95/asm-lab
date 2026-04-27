AS = arm-none-eabi-as
LD = arm-none-eabi-ld
GDB = arm-none-eabi-gdb

AFLAGS = -mcpu=cortex-m3 -mthumb -g
LDFLAGS = -T ../../common/linker.ld

COMMON_DIR = ../../common
OBJ_FILES = lab5.o $(COMMON_DIR)/startup.o

all: lab5.elf

%.o: %.s
	$(AS) $(AFLAGS) -o $@ $<

$(COMMON_DIR)/startup.o: $(COMMON_DIR)/startup.s
	$(AS) $(AFLAGS) -o $@ $<

lab5.elf: $(OBJ_FILES)
	$(LD) $(LDFLAGS) -o $@ $^

debug: lab5.elf
	qemu-system-arm -machine lm3s6965evb -cpu cortex-m3 -kernel lab5.elf -nographic -s -S &
	sleep 1
	$(GDB) -ex "target remote localhost:1234" -ex "file lab5.elf" -ex "break Reset_Handler" -ex "continue"

clean:
	rm -f *.o *.elf

.PHONY: all debug clean
