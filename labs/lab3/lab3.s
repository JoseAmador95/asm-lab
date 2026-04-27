.syntax unified
.thumb

.global main
.type main, %function
.thumb_func
main:
    MOV R0, #0             @ Counter
    LDR R1, =0x20000000    @ Array base
    MOV R2, #10            @ Loop limit (0-9)
loop:
    STR R0, [R1], #4       @ Store counter to [R1], increment R1 by 4
    ADD R0, R0, #1         @ Increment counter
    CMP R0, R2             @ Compare to limit
    BNE loop               @ Branch if not equal
    B .                    @ Loop forever
