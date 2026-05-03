.syntax unified
.thumb

.global main
.type main, %function
.thumb_func
main:
    MOV  R0, #0             @ Counter
    LDR  R1, =0x20008000    @ Array base (well above .bss)
    MOV  R2, #10            @ Loop limit (0-9)
loop:
    STR  R0, [R1], #4       @ Store counter, post-increment R1
    ADD  R0, R0, #1
    CMP  R0, R2
    BNE  loop

    @ Print the array values
    ldr  r0, =msg_array
    bl   semi_write0

    LDR  R1, =0x20008000    @ Reset to array base
    MOV  R2, #10            @ 10 elements
    MOV  R3, #0             @ index
print_loop:
    CMP  R3, R2
    BGE  done
    LDR  R0, [R1]           @ load element at current position
    push {r1, r2, r3}
    bl   semi_print_dec
    pop  {r1, r2, r3}
    ADD  R1, R1, #4         @ advance pointer
    ADD  R3, R3, #1
    B    print_loop

done:
    bl   semi_exit

.section .rodata
msg_array:
    .asciz "Array contents (0-9):\n"
