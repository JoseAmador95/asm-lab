.syntax unified
.thumb

.global main
.type main, %function
.thumb_func
main:
    LDR  R0, =0x1234        @ First operand
    LDR  R1, =0x5678        @ Second operand
    ADD  R2, R0, R1         @ R2 = 0x1234 + 0x5678 = 0x68AC

    @ Store result to RAM
    LDR  R3, =0x20000000
    STR  R2, [R3]

    @ Print result
    ldr  r0, =msg_result
    bl   semi_write0
    mov  r0, r2
    bl   semi_print_hex

    bl   semi_exit

.section .rodata
msg_result:
    .asciz "ADD result: "
