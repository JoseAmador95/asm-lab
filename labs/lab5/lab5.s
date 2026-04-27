.syntax unified
.thumb

.global main
.type main, %function
.thumb_func
main:
    LDR R0, =0x40025000    ; GPIO Port F base (lm3s6965evb)
    MOV R1, #0x04          @ Pin 2 (0b100)

    @ Set pin 2 as output (GPIODIR offset 0x400)
    STR R1, [R0, #0x400]
    @ Enable digital function (GPIODEN offset 0x51C)
    STR R1, [R0, #0x51C]

loop:
    @ Set pin high (GPIODATA masked offset 0x3FC)
    STR R1, [R0, #0x3FC]
    BL delay
    @ Set pin low
    MOV R2, #0
    STR R2, [R0, #0x3FC]
    BL delay
    B loop

delay:
    MOV R3, #0x10000       @ Delay counter
delay_loop:
    SUB R3, R3, #1
    CMP R3, #0
    BNE delay_loop
    BX LR
