# Lecture 3: Control Flow in Thumb - Deep Dive

## 3.1 Branch Instruction Family
All control flow instructions are Thumb/Thumb-2 only (no ARM mode equivalents on Cortex-M3).

### 3.1.1 Unconditional Branch: `B`
Transfers execution to a label, no return address saved:
```assembly
B label   @ Jump to label unconditionally
B .       @ Infinite loop (branch to current address)
```
- 16-bit instruction, range: ±2KB (use `B.W` for 32-bit wide range if needed)

### 3.1.2 Subroutine Call: `BL` (Branch with Link)
Saves return address to `LR` (R14), then branches to label:
```assembly
BL subroutine   @ LR = PC + 4 (return address), jump to subroutine
```
- Return from subroutine with `BX LR` (branch to address in LR, switch to Thumb mode)

### 3.1.3 Return: `BX` (Branch and Exchange)
Switches instruction set if LSB of target is 1 (always true for Thumb):
```assembly
BX LR   @ Return from subroutine (LR holds return address)
BX R0   @ Jump to address in R0 (LSB=1 for Thumb)
```

---

## 3.2 Conditional Branches
All conditional branches check flags (N/Z/C/V) set by `CMP`/arithmetic ops. Format: `B<cond> label`

### 3.2.1 Condition Suffixes (Full List)
| Suffix | Name | Flags Checked | Meaning (for CMP Rn, Rm) |
|--------|------|---------------|---------------------------|
| EQ | Equal | Z=1 | Rn == Rm |
| NE | Not Equal | Z=0 | Rn != Rm |
| CS/HS | Carry Set/Unsigned Higher/Same | C=1 | Rn >= Rm (unsigned) |
| CC/LO | Carry Clear/Unsigned Lower | C=0 | Rn < Rm (unsigned) |
| MI | Minus | N=1 | Result negative |
| PL | Plus | N=0 | Result positive/zero |
| VS | Overflow Set | V=1 | Signed overflow occurred |
| VC | Overflow Clear | V=0 | No signed overflow |
| HI | Unsigned Higher | C=1 and Z=0 | Rn > Rm (unsigned) |
| LS | Unsigned Lower/Same | C=0 or Z=1 | Rn <= Rm (unsigned) |
| GE | Signed Greater/Equal | N == V | Rn >= Rm (signed) |
| LT | Signed Less Than | N != V | Rn < Rm (signed) |
| GT | Signed Greater Than | Z=0 and N == V | Rn > Rm (signed) |
| LE | Signed Less/Equal | Z=1 or N != V | Rn <= Rm (signed) |
| AL | Always (default) | None | Unconditional (same as `B`) |

Example:
```assembly
MOV R0, #5
MOV R1, #3
CMP R0, R1       @ Set flags: C=1 (5>3 unsigned), Z=0, N=0, V=0
BEQ equal        @ Not taken (Z=0)
BGT greater      @ Taken (N=0 == V=0, 5>3 signed)
```

---

## 3.3 Loop Patterns
### 3.3.1 Increment Loop (Lab 3 Style)
Count up from 0 to N-1, store values to RAM array, then print each value:
```assembly
.syntax unified
.thumb
.global main
.type main, %function
.thumb_func
main:
    MOV  R0, #0             @ Counter = 0
    LDR  R1, =0x20008000    @ RAM array base (above .bss to avoid collision)
    MOV  R2, #10            @ Loop limit = 10 (0-9)
loop:
    STR  R0, [R1], #4       @ Store counter to [R1], increment R1 by 4
    ADD  R0, R0, #1         @ Counter++
    CMP  R0, R2             @ Compare counter to limit
    BNE  loop               @ Branch if counter != 10

    @ Print each stored value
    ldr  r0, =msg_array
    bl   semi_write0
    LDR  R1, =0x20008000    @ Reset to array base
    MOV  R2, #10
    MOV  R3, #0             @ Index
print_loop:
    CMP  R3, R2
    BGE  done
    LDR  R0, [R1]           @ Load element
    push {r1, r2, r3}
    bl   semi_print_dec     @ Print value
    pop  {r1, r2, r3}
    ADD  R1, R1, #4
    ADD  R3, R3, #1
    B    print_loop
done:
    bl   semi_exit

.section .rodata
msg_array:
    .asciz "Array contents (0-9):\n"
```
Expected output:
```
Array contents (0-9):
0
1
2
...
9
```

### 3.3.2 Decrement Loop (More Efficient)
Count down to 0, avoids `CMP` with limit (uses zero flag directly):
```assembly
MOV R0, #10           @ Counter = 10
LDR R1, =array_base
loop:
    SUB R0, R0, #1     @ Counter--
    STR R0, [R1], #4
    CMP R0, #0
    BNE loop           @ Branch if counter != 0
```

---

## 3.4 If-Else in Assembly
Implement `if (a > b) { c = 1; } else { c = 0; }`:
```assembly
MOV R0, #5   @ a = 5
MOV R1, #3   @ b = 3
CMP R0, R1   @ Compare a and b
BLE else     @ Branch if a <= b (signed, N!=V)
MOV R2, #1   @ c = 1
B end_if
else:
    MOV R2, #0   @ c = 0
end_if:
    B .         @ Infinite loop
```

---

## 3.5 Thumb-2 IT (If-Then) Block
For executing 1-4 instructions conditionally without branching (more efficient):
```assembly
LDR R0, =0x20000000
LDR R1, [R0]
CMP R1, #10
IT GT          @ If-Then: Next 1 instruction is conditional (GT)
MOVGT R1, #0  @ Only executed if R1 > 10
STR R1, [R0]
```
- `IT` syntax: `IT<c> [<cond1> [<cond2> [<cond3>]]]` (max 4 instructions)
- Suffixes: `T` (Then), `E` (Else) for each subsequent instruction

---

## 3.6 Key Takeaways
1. `BL` saves return address to LR, `BX LR` returns from subroutines
2. Conditional branches check flags set by `CMP`/arithmetic
3. Decrement loops are more efficient (no limit comparison)
4. IT blocks avoid branching for short conditional sequences

## 3.7 Common Pitfalls
- Forgetting `BX LR` after `BL` → infinite loop or crash
- Using wrong condition suffix (e.g., `BGT` for unsigned comparison) → logic errors
- Overusing IT blocks → hard to read code for beginners

## 3.8 Next Steps
Read **Lecture 4 (Subroutines/Stack)** then complete **Lab 3 (Loop + Array + Semihosting Output)**.
