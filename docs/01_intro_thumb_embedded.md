# Lecture 1: ARM Thumb for Embedded Systems

## Why Thumb?
- Thumb is a 16-bit compressed instruction set for ARM, extended to Thumb-2 (mixed 16/32-bit) in Cortex-M.
- **x86 vs Thumb**: x86 is for PCs (complex, variable instruction length); Thumb is embedded standard (Cortex-M, IoT, microcontrollers).
- Cortex-M3 (used in QEMU lm3s6965evb) only supports Thumb/Thumb-2.

## Cortex-M3 Registers
- 13 general purpose: R0-R12 (32-bit)
- R13: SP (Stack Pointer, MSP for main, PSP for process)
- R14: LR (Link Register, stores subroutine return address)
- R15: PC (Program Counter)
- xPSR (program status), PRIMASK (interrupt control)

## Vector Table
- First 2 words in flash (0x00000000):
  1. Initial MSP (Main Stack Pointer) value
  2. Reset Handler address (LSB set to 1 for Thumb mode)
- Defined in `common/startup.s` as `.isr_vector` section.

## Toolchain Check
Verify installed tools:
```bash
arm-none-eabi-as --version
qemu-system-arm --version
```

## Debugging Basics
- Use `-g` flag when assembling to include DWARF debug info.
- Use `arm-none-eabi-gdb` with QEMU's GDB stub (`-s` flag, port 1234).
- Common GDB commands: `break Reset_Handler`, `stepi`, `info registers`, `x/10xw 0x20000000` (inspect RAM).
