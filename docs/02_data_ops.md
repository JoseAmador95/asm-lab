# Lecture 2: Thumb Data Operations - Deep Dive

## 2.1 Instruction Set Basics
### Thumb vs Thumb-2
- Original Thumb (ARMv6-M, Cortex-M0): Only 16-bit instructions, limited immediate support
- Thumb-2 (ARMv7-M, Cortex-M3/M4): Mixed 16/32-bit instructions, full 32-bit immediate support
- All code here uses **Thumb-2** via `.syntax unified` (enables mixed 16/32-bit ops)

### Why `.syntax unified`?
- Old Thumb syntax required separate 16/32-bit mnemonics
- Unified syntax auto-selects 16-bit (if possible) or 32-bit instructions
- *Always* include `.syntax unified` and `.thumb` at the top of your files

---

## 2.2 Data Movement Instructions
### 2.2.1 Register-to-Register: `MOV`, `MVN`
| Instruction | Syntax | Description | Flag Impact |
|-------------|---------|-------------|-------------|
| `MOV` | `MOV Rd, Rm` / `MOV Rd, #imm` | Copy Rm to Rd, or load 8-bit immediate (0-255) | No flags modified |
| `MVN` | `MVN Rd, Rm` | Move *negated* Rm to Rd (bitwise NOT) | No flags modified |

Example:
```assembly
.syntax unified
.thumb
MOV R0, #0x12       @ R0 = 0x12 (8-bit immediate, 16-bit instruction)
MOV R1, R0          @ R1 = R0 = 0x12
MVN R2, R1          @ R2 = ~0x12 = 0xFFFFFFED (32-bit instruction)
```

### 2.2.2 Load Immediate: `LDR Rd, =imm` (Pseudo-Instruction)
- `MOV` only supports 8-bit immediates (0-255)
- `LDR =` loads *any* 32-bit value by placing it in a **literal pool** (constant data in flash)
- The assembler automatically generates the literal pool unless you specify otherwise

Example:
```assembly
LDR R0, =0x12345678 @ R0 = 0x12345678 (32-bit, uses literal pool)
LDR R1, =my_label   @ R1 = address of my_label (for accessing global variables)
```

### 2.2.3 Memory Access: `LDR`/`STR` (Load/Store)
Cortex-M3 uses a **load-store architecture**: all arithmetic operates on registers, only `LDR`/`STR` access memory.

| Instruction | Syntax | Description | Alignment Rule |
|-------------|---------|-------------|-----------------|
| `LDR` | `LDR Rd, [Rn, #offset]` | Load 32-bit word from Rn+offset to Rd | Must be 4-byte aligned |
| `STR` | `STR Rd, [Rn, #offset]` | Store 32-bit word from Rd to Rn+offset | Must be 4-byte aligned |
| `LDRB`/`STRB` | `LDRB Rd, [Rn]` | Load/store 8-bit byte | No alignment needed |
| `LDRH`/`STRH` | `LDRH Rd, [Rn]` | Load/store 16-bit halfword | 2-byte aligned |

Literal Pool Note: The assembler places literal pools at the end of sections. If you get a "literal pool overflow" error, add a `.ltorg` directive to force a pool earlier.

Example:
```assembly
LDR R0, =0x20000000   @ R0 = RAM base address (0x20000000)
MOV R1, #0x1234       @ R1 = 0x1234
STR R1, [R0]          @ RAM[0x20000000] = 0x1234
LDR R2, [R0]          @ R2 = RAM[0x20000000] = 0x1234
```

---

## 2.4 Lab 2 — Arithmetic and Output
Lab 2 adds two values and prints the result via semihosting:
```assembly
LDR  R0, =0x1234        @ First operand
LDR  R1, =0x5678        @ Second operand
ADD  R2, R0, R1         @ R2 = 0x68AC

LDR  R3, =0x20000000
STR  R2, [R3]           @ also store result to RAM

ldr  r0, =msg_result
bl   semi_write0        @ print label
mov  r0, r2
bl   semi_print_hex     @ print "0x000068ac\n"

bl   semi_exit

.section .rodata
msg_result:
    .asciz "ADD result: "
```
Expected output:
```
ADD result: 0x000068ac
```
1. **Alignment**: 32-bit `LDR`/`STR` require 4-byte aligned addresses (last 2 bits of address = 0)
   - Misaligned access triggers a `HardFault` exception
2. **Load-Store Only**: No direct memory-to-memory operations (e.g., `ADD [R0], [R1]` is invalid)
3. **Endianness**: Cortex-M3 is little-endian by default (least significant byte at lowest address)

---

## 2.5 Key Takeaways
1. Use `LDR =` for 32-bit immediates, `MOV` for 8-bit immediates
2. All arithmetic operates on registers, use `LDR`/`STR` for memory
3. `CMP` sets flags for conditional branches, no result stored
4. Always align 32-bit memory accesses to 4 bytes

## 2.6 Common Pitfalls
- Using `MOV R0, #0x1234` (0x1234 > 255) → assembler error
- Forgetting `.syntax unified` → 32-bit `LDR =` may not work
- Misaligned `LDR`/`STR` → HardFault on Cortex-M3

## 2.7 Next Steps
Read **Lecture 3 (Control Flow)** then complete **Lab 2 (Arithmetic + Semihosting Output)**.
