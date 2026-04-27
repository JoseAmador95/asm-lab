# Lecture 3: Control Flow in Thumb

## Branches
- `B label`: Unconditional branch
- `B<cond> label`: Conditional branch (BEQ, BNE, BGT, BLT, etc.)
  - Conditions depend on flags set by `CMP` or arithmetic ops.

## Loops
Example: Count 0-9, store to RAM array:
```assembly
.syntax unified
.thumb

main:
    MOV R0, #0            ; Counter
    LDR R1, =0x20000000   ; Array base
    MOV R2, #10           ; Loop limit
loop:
    STR R0, [R1], #4      ; Store R0 to [R1], increment R1 by 4
    ADD R0, R0, #1        ; Increment counter
    CMP R0, R2            ; Compare counter to limit
    BNE loop              ; Branch if counter != 10
```

## Subroutine Calls
- `BL label`: Branch with Link (saves return address to LR, branches to label)
- Return: `BX LR` (branch to LR, switch to Thumb mode if LSB set)

## Lab 3 Preview
Loop 0-9, store values to RAM array, verify with QEMU.
