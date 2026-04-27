# ARM Thumb Assembly for Embedded Systems

Learn ARM Thumb assembly programming for embedded systems (Cortex-M). Includes theoretical readings and hands-on labs executable on macOS (Intel) using QEMU.

## Prerequisites

```bash
brew install arm-none-eabi-gcc qemu
```

## Structure

```
asm/
├── docs/          # Theoretical readings
├── labs/          # Lab exercises
└── common/        # Shared tools (linker, startup, script)
```

## Content

### Readings (`docs/`)
1. **01_intro_thumb_embedded.md** - Introduction, Cortex-M3 registers, vector table, toolchain
2. **02_data_ops.md** - MOV, LDR, STR, ADD, SUB, CMP and flags
3. **03_control_flow.md** - B, BL, conditionals, loops
4. **04_subroutines_stack.md** - Subroutines, PUSH/POP, AAPCS conventions
5. **05_bare_metal_io.md** - Memory-mapped I/O (UART, GPIO)

### Labs (`labs/`)
| Lab | Topic | Verification |
|-----|-------|--------------|
| 1 | Write 'A' to UART0 | Serial output in QEMU |
| 2 | Add 0x1234 + 0x5678 → RAM | QEMU monitor: `x/1wx 0x20000000` |
| 3 | Loop 0-9 → RAM array | QEMU monitor verifies array |
| 4 | Subroutine to add 5+7 | QEMU monitor verifies R0 |
| 5 | GPIO Blinky (flashing LED) | QEMU monitor verifies pin state |

## Usage

### Run a lab
```bash
./common/run_lab.sh labs/lab1/lab1.s
```

### Debug with GDB (includes DWARF debug info)
```bash
./common/run_lab.sh --debug labs/lab1/lab1.s
```

### Use per-lab Makefile
```bash
cd labs/lab1
make          # Assemble and link
make debug    # Run with GDB
make clean    # Remove generated files
```

## Notes
- All executables include debug information (`-g` flag)
- Generated files (`*.o`, `*.elf`) are in `.gitignore`
- Emulates the **lm3s6965evb** (Cortex-M3) board via QEMU
