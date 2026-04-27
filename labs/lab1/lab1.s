.syntax unified
.thumb

.global main
.type main, %function
.thumb_func
main:
    @ Enable UART0 and PORTA clock
    LDR R0, =0x400FE000
    LDR R1, [R0, #0x618]   @ RCGCUART
    ORR R1, R1, #0x01       @ Enable UART0
    STR R1, [R0, #0x618]
    LDR R1, [R0, #0x608]   @ RCGCGPIO
    ORR R1, R1, #0x01       @ Enable PORTA
    STR R1, [R0, #0x608]

    @ Configure PA0/PA1 as UART
    LDR R0, =0x40004000     @ PORTA base
    LDR R1, [R0, #0x420]   @ GPIOAFSEL
    ORR R1, R1, #0x03       @ PA0/PA1 alternate function
    STR R1, [R0, #0x420]
    LDR R1, [R0, #0x52C]   @ GPIOPCTL
    ORR R1, R1, #0x11       @ PA0/PA1 = UART (0x1 for each)
    STR R1, [R0, #0x52C]

    @ Disable UART0 to configure
    LDR R0, =0x4000C000     @ UART0 base
    LDR R1, [R0, #0x30]    @ UARTCTL
    BIC R1, R1, #0x01       @ Clear UARTEN
    STR R1, [R0, #0x30]

    @ Set baud rate 115200 (16MHz clock: IBRD=8, FBRD=44)
    MOV R1, #8
    STR R1, [R0, #0x24]    @ UARTIBRD
    MOV R1, #44
    STR R1, [R0, #0x28]    @ UARTFBRD

    @ Configure 8-bit, no parity, 1 stop bit
    MOV R1, #0x60           @ WLEN 8-bit
    STR R1, [R0, #0x2C]    @ UARTLCRH

    @ Enable UART, TX, RX
    MOV R1, #0x0301         @ UARTEN | TXE | RXE
    STR R1, [R0, #0x30]    @ UARTCTL

    @ Send 'A'
    MOV R1, #'A'
wait_tx:
    LDR R2, [R0, #0x18]   @ UARTFR
    TST R2, #(1 << 5)     @ Check TX FIFO full
    BNE wait_tx           @ Wait if full
    STR R1, [R0]          @ Send 'A'
    B .                    @ Loop forever
