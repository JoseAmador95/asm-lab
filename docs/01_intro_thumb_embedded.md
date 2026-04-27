# Lecture 1: ARM Thumb for Embedded Systems - Deep Dive

## 1.1 Architecture Choice: Why Thumb for Embedded?
### ARM vs x86: Core Differences
| Feature | ARM Thumb/Thumb-2 | x86 (PCs/Servers) |
|---------|-------------------|-------------------|
| Instruction Set | RISC (Reduced Instruction Set Computer) | CISC (Complex Instruction Set Computer) |
| Instruction Size | Mixed 16/32-bit (Thumb-2) | Variable 1-15 bytes |
| Code Density | High (16-bit Thumb ops reduce binary size by ~30% vs ARM mode) | Low (complex instructions lead to larger binaries) |
| Power Consumption | Low (fewer memory accesses, simpler decode) | High (complex decode logic, more transistors) |
| Embedded Use | **Exclusive standard** for Cortex-M (IoT, MCUs, automotive) | Rare (only for industrial PCs, not MCUs) |

### Critical Note: Cortex-M3 Only Runs Thumb-2
- Classic ARM mode (32-bit only) is *not supported* on Cortex-M3/Cortex-M4
- Thumb-2 extends original 16-bit Thumb with 32-bit instructions for complex operations (e.g., `LDR R0, =0x12345678`)
- All code in this course targets **Thumb-2** for Cortex-M3 (emulated by QEMU `lm3s6965evb`)

---

## 1.2 Cortex-M3 Register Set (Full Breakdown)
All registers are 32-bit unless specified:
| Register | Name | Purpose | Notes |
|----------|------|---------|-------|
| R0-R3 | Argument/Scratch | Pass function arguments (R0-R3), return values (R0) | Caller-saved: subroutines can clobber freely |
| R4-R11 | Callee-Saved | Preserve across subroutine calls | Must be pushed to stack if modified in subroutines |
| R12 | Intra-Procedure Call | Temporary for linker/veneers | Rarely used in bare-metal |
| R13 | SP (Stack Pointer) | Main Stack Pointer (MSP) by default | Grows *down* (high→low address), 8-byte aligned |
| R14 | LR (Link Register) | Stores return address for `BL` calls | `BX LR` returns from subroutines |
| R15 | PC (Program Counter) | Points to current instruction + 4 (pipeline) | LSB must be 1 for Thumb mode (handled automatically) |
| xPSR | Program Status Register | N/Z/C/V flags + exception state | Updated by arithmetic/compare ops |
| PRIMASK | Priority Mask | Disables all interrupts (1=disable, 0=enable) | Used for critical sections |
| FAULTMASK | Fault Mask | Disables faults (harder to recover) | Rare in basic embedded |
| BASEPRI | Base Priority | Masks interrupts below a priority threshold | Advanced use |

---

## 1.3 Vector Table Deep Dive
The vector table is the first 16 words (64 bytes) of flash memory at `0x00000000`. It tells the Cortex-M where to find exception handlers.

### Table Structure (lm3s6965evb Cortex-M3)
| Offset | Name | Description |
|--------|------|-------------|
| 0x00 | Initial MSP | Stack pointer initial value (top of RAM, defined in `linker.ld`) |
| 0x04 | Reset_Handler | Entry point after power-on/reset (our `Reset_Handler` in `startup.s`) |
| 0x08 | NMI_Handler | Non-Maskable Interrupt (hardware faults, cannot be disabled) |
| 0x0C | HardFault_Handler | Catches all unhandled exceptions/faults |
| 0x10-0x2C | Fault Handlers | MemManage, BusFault, UsageFault (advanced fault handling) |
| 0x30-0x44 | System Handlers | SVC, DebugMon, PendSV, SysTick (RTOS/periodic timer) |

### Why Weak Handlers?
In `startup.s`, we define default handlers as `.weak`:
```assembly
.weak NMI_Handler
.thumb_set NMI_Handler, Default_Handler
```
- `.weak` allows you to override the handler in your own code (e.g., define a custom `NMI_Handler` in `labX.s`)
- `Default_Handler` is an infinite loop (`b Default_Handler`) to catch unhandled exceptions safely

---

## 1.4 Toolchain Detailed Reference
All tools are from the `arm-none-eabi-gcc` Homebrew package, targeting bare-metal ARM (no OS).

### 1.4.1 Assembler: `arm-none-eabi-as`
Converts `.s` assembly files to object files (`.o`):
```bash
arm-none-eabi-as -mcpu=cortex-m3 -mthumb -g -o output.o input.s
```
| Flag | Purpose |
|------|---------|
| `-mcpu=cortex-m3` | Target Cortex-M3 (enables Thumb-2 instructions) |
| `-mthumb` | Force Thumb mode (redundant for Cortex-M3 but explicit) |
| `-g` | Generate DWARF debug info for GDB |
| `-o` | Output file name |

### 1.4.2 Linker: `arm-none-eabi-ld`
Combines object files with a linker script to produce a bare-metal executable (`.elf`):
```bash
arm-none-eabi-ld -T common/linker.ld -o output.elf startup.o labX.o
```
- `-T common/linker.ld`: Uses our custom memory map (flash @ 0x00000000, RAM @ 0x20000000)
- `.elf` format includes debug info, memory sections, and symbol tables

### 1.4.3 Debug Info Tools
- Check debug sections: `arm-none-eabi-readelf -S labX.elf | grep debug`
- Disassemble with source: `arm-none-eabi-objdump -dS labX.elf` (shows source lines if `-g` used)

### 1.4.4 QEMU: `qemu-system-arm`
Emulates the `lm3s6965evb` Cortex-M3 board:
```bash
qemu-system-arm -machine lm3s6965evb -cpu cortex-m3 -kernel labX.elf -nographic
```
| Flag | Purpose |
|------|---------|
| `-machine lm3s6965evb` | Emulate Texas Instruments Stellaris LM3S6965 (Cortex-M3) |
| `-cpu cortex-m3` | Explicit CPU (redundant but clear) |
| `-kernel labX.elf` | Load bare-metal ELF directly |
| `-nographic` | Use serial output (no GUI) |
| `-s` | Start GDB stub on TCP port 1234 |
| `-S` | Freeze CPU at startup (wait for GDB `continue`) |

---

## 1.5 Debugging Walkthrough (GDB + QEMU)
Example session for Lab 1:
1. Start QEMU in debug mode:
   ```bash
   qemu-system-arm -machine lm3s6965evb -cpu cortex-m3 -kernel lab1.elf -nographic -s -S
   ```
2. Connect GDB in another terminal:
   ```bash
   arm-none-eabi-gdb lab1.elf
   (gdb) target remote localhost:1234
   (gdb) break Reset_Handler   # Break at startup
   (gdb) continue             # Run to breakpoint
   (gdb) stepi                # Execute 1 instruction
   (gdb) info registers       # Show all registers
   (gdb) x/10xw 0x20000000   # Inspect 10 words of RAM starting at 0x20000000
   (gdb) monitor info registers  # QEMU monitor: show emulated CPU state
   ```

---

## 1.6 Key Takeaways
1. Thumb-2 is the only assembly dialect for modern ARM embedded systems (Cortex-M)
2. Cortex-M3 uses a load-store architecture: no direct memory-to-memory operations
3. All vectors in the table must have LSB=1 (Thumb mode), handled by `.thumb_func`
4. Debug info (`-g`) is critical for stepping through assembly in GDB

## 1.7 Common Pitfalls
- Forgetting `.thumb_func` before labels referenced in the vector table → invalid instruction exceptions
- Using `;` for comments instead of `@` in GAS (GNU Assembler) → syntax errors
- Mixing ARM and Thumb instructions → undefined behavior on Cortex-M

## 1.8 Next Steps
Read **Lecture 2 (Data Operations)** then complete **Lab 1 (UART Output)**.
