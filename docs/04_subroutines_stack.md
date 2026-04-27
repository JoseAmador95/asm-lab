# Lecture 4: Subroutines and Stack

## Stack Operations
- `PUSH {reglist}`: Push registers to stack (SP decrements by 4 * num registers)
- `POP {reglist}`: Pop registers from stack (SP increments)
- Cortex-M stack grows down (high to low address).

## AAPCS Calling Conventions
- Arguments passed in R0-R3
- Return value in R0
- Preserve R4-R11 across calls (push/pop if modified)

## Subroutine Example
```assembly
.syntax unified
.thumb

main:
    MOV R0, #5
    MOV R1, #7
    BL add_numbers   ; Call subroutine, result in R0
    B .

add_numbers:
    ADD R0, R0, R1   ; R0 = 5 + 7 = 12
    BX LR            ; Return
```

## Nested Calls
```assembly
foo:
    PUSH {LR}        ; Save return address
    BL bar
    POP {LR}         ; Restore
    BX LR

bar:
    PUSH {R4, LR}    ; Save R4 and LR
    ; Do work
    POP {R4, LR}     ; Restore
    BX LR
```

## Lab 4 Preview
Call subroutine to add 5+7, return result in R0, verify with GDB/QEMU.
