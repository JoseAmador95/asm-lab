# Lecture 4: Subroutines and Stack - Deep Dive

## 4.1 Subroutine Basics
### 4.1.1 Call and Return
- `BL label`: Saves `PC + 4` to `LR` (return address), branches to `label`
- `BX LR`: Returns to the instruction after the `BL` call

Example:
```assembly
.syntax unified
.thumb
.global main
.type main, %function
.thumb_func
main:
    MOV  R0, #5
    MOV  R1, #7
    BL   add_numbers        @ LR = return address, jump to add_numbers
                            @ result in R0

    push {r0}
    ldr  r0, =msg_result
    bl   semi_write0        @ print label
    pop  {r0}
    bl   semi_print_dec     @ print "12\n"

    bl   semi_exit

add_numbers:
    ADD  R0, R0, R1         @ R0 = 5 + 7 = 12
    BX   LR                 @ Return to main

.section .rodata
msg_result:
    .asciz "add_numbers(5, 7) = "
```
Expected output:
```
add_numbers(5, 7) = 12
```

---

## 4.2 AAPCS (ARM Architecture Procedure Call Standard)
The official calling convention for ARM, mandatory for interoperating with C code.

### 4.2.1 Register Usage Rules
| Register | Role | Saved By | Description |
|----------|------|----------|-------------|
| R0-R3 | Argument/Return | Caller | Pass 1st-4th arguments, return value in R0 |
| R4-R11 | Callee-Saved | Callee | Must be pushed to stack if modified in subroutine |
| R12 | IP (Intra-Procedure) | Caller | Temporary for linker, can be clobbered |
| R13 (SP) | Stack Pointer | Callee | Must be 8-byte aligned at all times |
| R14 (LR) | Link Register | Caller | Saved by caller if subroutine calls another (`BL`) |
| R15 (PC) | Program Counter | - | Cannot be modified directly |

### 4.2.2 Argument Passing Example
Calling `add(a, b)` with a=5, b=7:
```assembly
MOV R0, #5   @ Argument 1 (a) in R0
MOV R1, #7   @ Argument 2 (b) in R1
BL add       @ Call add, result in R0
B .

add:
    ADD R0, R0, R1   @ R0 = a + b
    BX LR
```

---

## 4.3 Stack Operations
Cortex-M3 stack grows **down** (from high RAM address to low). All stack accesses must be 4-byte aligned (or 8-byte for AAPCS compliance).

### 4.3.1 PUSH/POP (Thumb-2 Instructions)
- `PUSH {reglist}`: Decrement SP by 4 * num_regs, store registers to stack
- `POP {reglist}`: Load registers from stack, increment SP by 4 * num_regs

Example: Save R4-R7 and LR before modifying them:
```assembly
subroutine:
    PUSH {R4-R7, LR}   @ Save callee-saved regs + LR (5 registers, SP -= 20)
    MOV R4, #1
    MOV R5, #2
    ; Do work...
    POP {R4-R7, LR}    @ Restore regs + LR (SP += 20)
    BX LR               @ Return (LR restored from stack)
```

### 4.3.2 Stack Alignment
AAPCS requires SP to be 8-byte aligned at all times:
- Pushing an odd number of registers (e.g., `PUSH {R4, LR}`) keeps alignment
- Pushing 3 registers (12 bytes) misaligns SP → undefined behavior

---

## 4.4 Nested Subroutine Calls
When a subroutine calls another, it must save LR to the stack (since `BL` overwrites LR):
```assembly
main:
    BL func1   @ LR = return address in main
    B .

func1:
    PUSH {LR}   @ Save LR (return address to main)
    BL func2    @ LR = return address in func1 (overwrites old LR)
    POP {LR}    @ Restore LR (return address to main)
    BX LR

func2:
    ; Do work
    BX LR        @ Return to func1
```

---

## 4.5 Stack Frame Layout (for C Interop)
A typical stack frame for a subroutine with local variables:
| High Address | Content |
|--------------|---------|
| SP + 28 | Argument 3 (R2) |
| SP + 24 | Argument 2 (R1) |
| SP + 20 | Argument 1 (R0) |
| SP + 16 | LR (return address) |
| SP + 12 | R11 (callee-saved) |
| SP + 8 | R4 (callee-saved) |
| SP + 4 | Local variable 2 |
| SP + 0 | Local variable 1 |
| Low Address (SP) | Next free stack space |

---

## 4.6 Key Takeaways
1. AAPCS defines R0-R3 for arguments, R0 for return values
2. Callee-saved registers (R4-R11) must be pushed/popped if modified
3. Always save LR when calling another subroutine from a subroutine
4. Stack must be 8-byte aligned at all times

## 4.7 Common Pitfalls
- Forgetting to pop LR in nested calls → returns to wrong address
- Clobbering R4-R11 without pushing → corrupts caller's data
- Stack overflow (no bounds checking on Cortex-M3) → HardFault

## 4.8 Next Steps
Read **Lecture 5 (Bare-Metal I/O)** then complete **Lab 4 (Subroutine Call + Semihosting Output)**.
