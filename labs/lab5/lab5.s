.syntax unified
.thumb

.global main
.type main, %function
.thumb_func
main:
    LDR  R0, =0x40025000    @ GPIO Port F base (lm3s6965evb)
    MOV  R1, #0x04          @ Pin 2 (0b100)

    @ Set pin 2 as output (GPIODIR offset 0x400)
    STR  R1, [R0, #0x400]
    @ Enable digital function (GPIODEN offset 0x51C)
    STR  R1, [R0, #0x51C]

    MOV  R4, #5             @ blink 5 times then exit
loop:
    CMP  R4, #0
    BEQ  done

    @ Set pin high
    STR  R1, [R0, #0x3FC]
    ldr  r5, =msg_on
    push {r0, r1, r4}
    mov  r0, r5
    bl   semi_write0
    pop  {r0, r1, r4}
    BL   delay

    @ Set pin low
    MOV  R2, #0
    STR  R2, [R0, #0x3FC]
    ldr  r5, =msg_off
    push {r0, r1, r4}
    mov  r0, r5
    bl   semi_write0
    pop  {r0, r1, r4}
    BL   delay

    SUB  R4, R4, #1
    B    loop

done:
    ldr  r0, =msg_done
    bl   semi_write0
    bl   semi_exit

delay:
    MOV  R3, #0x10000
delay_loop:
    SUB  R3, R3, #1
    CMP  R3, #0
    BNE  delay_loop
    BX   LR

.section .rodata
msg_on:
    .asciz "LED on\n"
msg_off:
    .asciz "LED off\n"
msg_done:
    .asciz "Blink done.\n"
