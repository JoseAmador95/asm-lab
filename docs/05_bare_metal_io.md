# Lecture 5: Bare-Metal I/O (UART/GPIO)

## Memory-Mapped I/O
- Peripherals (UART, GPIO) are accessed as memory addresses in the Cortex-M map.
- lm3s6965evb UART0 registers:
  - Base: 0x4000C000
  - UARTDR (Data): 0x4000C000 (write to send, read to receive)
  - UARTFR (Flag): 0x4000C018 (bit 5: TX FIFO full, bit 7: RX FIFO empty)

## UART Write Example
```assembly
.syntax unified
.thumb

main:
    LDR R0, =0x4000C000   ; UART0 base
    MOV R1, #'A'          ; ASCII 'A' = 0x41
wait_tx:
    LDR R2, [R0, #0x18]   ; UARTFR
    TST R2, #(1 << 5)     ; Check TX FIFO full
    BNE wait_tx           ; Wait if full
    STR R1, [R0]          ; Send character
    B .
```

## GPIO Blinky (lm3s6965evb Port F)
- Port F base: 0x40025000
- Pin 2 (0b100) for LED
- GPIODIR (0x40025400): Set pin as output
- GPIODEN (0x4002551C): Enable digital function
- GPIODATA masked (0x400253FC): Write pin value

## Lab 5 Preview
Blinky LED with GPIO, verify with QEMU monitor.
