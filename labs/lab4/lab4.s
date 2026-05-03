.syntax unified
.thumb

.global main
.type main, %function
.thumb_func
main:
    MOV  R0, #5             @ First argument
    MOV  R1, #7             @ Second argument
    BL   add_numbers        @ Result in R0

    @ Store result to RAM
    LDR  R2, =0x20000000
    STR  R0, [R2]

    @ Print result
    push {r0}
    ldr  r0, =msg_result
    bl   semi_write0
    pop  {r0}
    bl   semi_print_dec

    bl   semi_exit

add_numbers:
    ADD  R0, R0, R1         @ R0 = 5 + 7 = 12
    BX   LR

.section .rodata
msg_result:
    .asciz "add_numbers(5, 7) = "
