# Lecture 2: Thumb Data Operations

## Data Movement
- `MOV Rd, Rm`: Copy register Rm to Rd (16-bit)
- `MOV Rd, #imm`: Load 8-bit immediate (0-255 for 16-bit Thumb)
- `LDR Rd, =value`: Load 32-bit value/address (pseudo-instruction)
- `LDR Rd, [Rn, #offset]`: Load 32-bit value from memory at Rn + offset
- `STR Rd, [Rn, #offset]`: Store 32-bit value from Rd to memory at Rn + offset

## Examples
```assembly
.syntax unified
.thumb

main:
    MOV R0, #0x12         ; R0 = 0x12 (8-bit imm)
    LDR R1, =0x12345678   ; R1 = 0x12345678 (32-bit imm)
    LDR R2, =0x20000000   ; R2 = RAM base address
    STR R0, [R2]          ; Store R0 to RAM[0x20000000]
    LDR R3, [R2]          ; R3 = RAM[0x20000000] (0x12)
```

## Arithmetic
- `ADD Rd, Rn, Rm`: Rd = Rn + Rm
- `ADD Rd, Rn, #imm`: Rd = Rn + 8-bit immediate
- `SUB Rd, Rn, Rm`: Rd = Rn - Rm
- `CMP Rn, Rm`: Compare Rn and Rm (sets flags, no result stored)

## Flags
- N (Negative): Result bit 31 set
- Z (Zero): Result is 0
- C (Carry): Unsigned overflow
- V (Overflow): Signed overflow

## Lab 2 Preview
Add 0x1234 + 0x5678, store result to RAM, verify with QEMU monitor.
