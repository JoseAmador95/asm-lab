.syntax unified
.thumb

.global main
.type main, %function
.thumb_func
main:
    MOV R0, #5             @ First argument
    MOV R1, #7             @ Second argument
    BL add_numbers         @ Call subroutine, result in R0
    LDR R2, =0x20000000    @ RAM base
    STR R0, [R2]           @ Store result
    B .

add_numbers:
    ADD R0, R0, R1         @ R0 = 5 + 7 = 12
    BX LR                  @ Return
