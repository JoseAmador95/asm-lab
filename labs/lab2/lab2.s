.syntax unified
.thumb

.global main
.type main, %function
.thumb_func
main:
    LDR R0, =0x1234        @ First operand
    LDR R1, =0x5678        @ Second operand
    ADD R2, R0, R1         @ R2 = 0x1234 + 0x5678 = 0x68AC
    LDR R3, =0x20000000    @ RAM base address
    STR R2, [R3]           @ Store result to RAM[0x20000000]
    B .                    @ Infinite loop
