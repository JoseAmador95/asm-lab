# Lecture 5: Bare-Metal I/O (GPIO) - Deep Dive

## 5.1 Memory-Mapped I/O Principles
- Peripherals (UART, GPIO, timers) are accessed as *memory addresses* in the Cortex-M address space
- Reads/writes to peripheral addresses trigger hardware actions (not RAM access)
- lm3s6965evb Peripheral Base Addresses:
  | Peripheral | Base Address | Description |
  |-------------|--------------|-------------|
  | UART0 | 0x4000C000 | Serial communication |
  | GPIO Port F | 0x40025000 | Onboard LED (Pin 2 = Green LED) |
  | System Control | 0x400FE000 | Clock/power management |

---

## 5.2 GPIO (General Purpose I/O)
### 5.2.1 lm3s6965evb GPIO Port F (Onboard LED)
- Port F Base: `0x40025000`
- Pin 2 (`0b100`): Green LED (active high)
- Pin 3 (`0b1000`): Blue LED (active high)

### 5.2.2 Key GPIO Registers (Offsets from Port Base)
| Offset | Name | Description | Access |
|--------|------|-------------|--------|
| 0x400 | GPIODIR | Direction (1=output, 0=input) | R/W |
| 0x51C | GPIODEN | Digital Enable (1=digital function) | R/W |
| 0x420 | GPIOAFSEL | Alternate Function Select (1=peripheral) | R/W |
| 0x52C | GPIOPCTL | Peripheral Mux Control (which peripheral) | R/W |
| 0x3FC | GPIODATA (Masked) | Data Register (write=set pin, read=read pin) | R/W |

### 5.2.3 GPIO Masked Access (GPIODATA)
- To access pin N, use address `PortBase + (0x3FC | (1 << (N+2)))`
- For Pin 2: `0x40025000 + 0x3FC = 0x400253FC` (full mask 0x3FC enables all pins)
- Writing `0x04` to `0x400253FC` sets Pin 2 high, writing `0x00` sets it low

### 5.2.4 GPIO Output Init Sequence
1. Configure Pin 2 as output (`GPIODIR |= 0x04`)
2. Enable digital function (`GPIODEN |= 0x04`)
3. Write to GPIODATA to set/clear pin

---

## 5.3 Lab 5 — GPIO Blinky with Semihosting Output
Lab 5 toggles the GPIO LED 5 times and prints each state transition to the terminal via semihosting:
```assembly
.syntax unified
.thumb
.global main
.type main, %function
.thumb_func
main:
    LDR  R0, =0x40025000    @ GPIO Port F base
    MOV  R1, #0x04          @ Pin 2

    STR  R1, [R0, #0x400]   @ GPIODIR: set pin 2 as output
    STR  R1, [R0, #0x51C]   @ GPIODEN: enable digital function

    MOV  R4, #5             @ blink 5 times
loop:
    CMP  R4, #0
    BEQ  done

    STR  R1, [R0, #0x3FC]   @ LED on
    push {r0, r1, r4}
    ldr  r0, =msg_on
    bl   semi_write0
    pop  {r0, r1, r4}
    BL   delay

    MOV  R2, #0
    STR  R2, [R0, #0x3FC]   @ LED off
    push {r0, r1, r4}
    ldr  r0, =msg_off
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
msg_on:  .asciz "LED on\n"
msg_off: .asciz "LED off\n"
msg_done:.asciz "Blink done.\n"
```
Expected output:
```
LED on
LED off
LED on
LED off
LED on
LED off
LED on
LED off
LED on
LED off
Blink done.
```

### Why save/restore R0, R1, R4 around `semi_write0`?
`semi_write0` (and any semihosting call) follows AAPCS and may clobber `r0`–`r3`. Since `R0` holds the GPIO base address and `R1`/`R4` hold the pin mask and loop counter, they must be preserved with `push`/`pop` around the call.

---

## 5.4 UART0 Reference (Not used in labs — for reference only)
The lm3s6965evb also emulates a full UART0. While the labs use semihosting for output, here are the key registers for completeness:

### 5.4.1 Key Registers (Offsets from 0x4000C000)
| Offset | Name | Description | Access |
|--------|------|-------------|--------|
| 0x000 | UARTDR | Data Register (write = send, read = receive) | R/W |
| 0x018 | UARTFR | Flag Register (status bits) | Read Only |
| 0x024 | UARTIBRD | Integer Baud Rate Divisor | R/W |
| 0x028 | UARTFBRD | Fractional Baud Rate Divisor | R/W |
| 0x02C | UARTLCRH | Line Control (8-bit, parity, stop bits) | R/W |
| 0x030 | UARTCTL | Control Register (enable UART, TX/RX) | R/W |

### 5.4.2 UARTFR Flag Bits
| Bit | Name | Description |
|-----|------|-------------|
| 7 | RXFE | RX FIFO Empty (1 = no data to receive) |
| 5 | TXFF | TX FIFO Full (1 = cannot send more data) |
| 3 | BUSY | UART busy (1 = transmitting data) |

---

## 5.5 QEMU Peripheral Emulation Notes
- lm3s6965evb in QEMU fully emulates UART0 and GPIO Port F
- QEMU monitor commands to inspect peripherals:
  ```bash
  (qemu) info registers       @ Show CPU registers
  (qemu) x/1xw 0x4000C000   @ Read UARTDR
  (qemu) x/1xw 0x400253FC   @ Read GPIO Pin 2 state
  ```

---

## 5.6 Key Takeaways
1. Peripherals are memory-mapped — use `LDR`/`STR` to access them
2. GPIO requires direction and digital-enable registers configured before use
3. Caller-saved registers (`r0`–`r3`) must be preserved around any `BL` call, including semihosting helpers
4. Semihosting is the practical way to produce output in bare-metal QEMU emulation

## 5.7 Common Pitfalls
- Forgetting to enable peripheral clocks (`RCGC`) → writes to peripheral registers ignored
- Using wrong GPIO masked address → pin not toggling
- Not preserving `r0`–`r3` around semihosting calls → corrupted register state

## 5.8 Next Steps
Complete **Lab 5 (GPIO Blinky)** to finish all labs.

## 5.1 Memory-Mapped I/O Principles
- Peripherals (UART, GPIO, timers) are accessed as *memory addresses* in the Cortex-M address space
- Reads/writes to peripheral addresses trigger hardware actions (not RAM access)
- lm3s6965evb Peripheral Base Addresses:
  | Peripheral | Base Address | Description |
  |-------------|--------------|-------------|
  | UART0 | 0x4000C000 | Serial communication |
  | GPIO Port F | 0x40025000 | Onboard LED (Pin 2 = Green LED) |
  | System Control | 0x400FE000 | Clock/power management |

---

## 5.2 UART0 (Serial Communication)
### 5.2.1 Key Registers (Offsets from 0x4000C000)
| Offset | Name | Description | Access |
|--------|------|-------------|--------|
| 0x000 | UARTDR | Data Register (write = send, read = receive) | R/W |
| 0x018 | UARTFR | Flag Register (status bits) | Read Only |
| 0x024 | UARTIBRD | Integer Baud Rate Divisor | R/W |
| 0x028 | UARTFBRD | Fractional Baud Rate Divisor | R/W |
| 0x02C | UARTLCRH | Line Control (8-bit, parity, stop bits) | R/W |
| 0x030 | UARTCTL | Control Register (enable UART, TX/RX) | R/W |

### 5.2.2 UARTFR Flag Bits
| Bit | Name | Description |
|-----|------|-------------|
| 7 | RXFE | RX FIFO Empty (1 = no data to receive) |
| 5 | TXFF | TX FIFO Full (1 = cannot send more data) |
| 3 | BUSY | UART busy (1 = transmitting data) |

### 5.2.3 Baud Rate Calculation (Cortex-M3 16MHz Clock)
Baud Rate = 16MHz / (16 * (UARTIBRD + UARTFBRD/64))
For 115200 baud:
- 16MHz / (16 * 115200) = 8.68 → UARTIBRD = 8
- 0.68 * 64 = 43.52 → UARTFBRD = 44 (rounded)

### 5.2.4 UART Init Sequence (Lab 1)
1. Enable UART0 clock in System Control (RCGCUART)
2. Enable GPIO Port A clock (RCGCGPIO, UART0 uses PA0/PA1)
3. Configure PA0/PA1 as alternate function (UART)
4. Disable UART0 (clear UARTEN in UARTCTL)
5. Set baud rate (UARTIBRD=8, UARTFBRD=44)
6. Configure 8-bit, no parity, 1 stop bit (UARTLCRH=0x60)
7. Enable UART0, TX, RX (UARTCTL=0x0301)

Example Send Char:
```assembly
LDR R0, =0x4000C000   @ UART0 base
MOV R1, #'A'          @ ASCII 'A' = 0x41
wait_tx:
    LDR R2, [R0, #0x18]   @ UARTFR
    TST R2, #(1 << 5)     @ Check TXFF (bit 5)
    BNE wait_tx           @ Wait if TX FIFO full
    STR R1, [R0]          @ Send character
```

---

## 5.3 GPIO (General Purpose I/O)
### 5.3.1 lm3s6965evb GPIO Port F (Onboard LED)
- Port F Base: 0x40025000
- Pin 2 (0b100): Green LED (active high)
- Pin 3 (0b1000): Blue LED (active high)

### 5.3.2 Key GPIO Registers (Offsets from Port Base)
| Offset | Name | Description | Access |
|--------|------|-------------|--------|
| 0x400 | GPIODIR | Direction (1=output, 0=input) | R/W |
| 0x51C | GPIODEN | Digital Enable (1=digital function) | R/W |
| 0x420 | GPIOAFSEL | Alternate Function Select (1=peripheral) | R/W |
| 0x52C | GPIOPCTL | Peripheral Mux Control (which peripheral) | R/W |
| 0x3FC | GPIODATA (Masked) | Data Register (write=set pin, read=read pin) | R/W |

### 5.3.3 GPIO Masked Access (GPIODATA)
- To access pin N, use address `PortBase + (0x3FC | (1 << (N+2)))`
- For Pin 2: `0x40025000 + 0x3FC = 0x400253FC` (full mask 0x3FC enables all pins)
- Writing 0x04 to 0x400253FC sets Pin 2 high, writing 0x00 sets it low

### 5.3.4 GPIO Output Init Sequence (Lab 5)
1. Enable GPIO Port F clock (RCGCGPIO)
2. Configure Pin 2 as output (GPIODIR |= 0x04)
3. Enable digital function (GPIODEN |= 0x04)
4. Write to GPIODATA to set/clear pin

Example Blinky:
```assembly
LDR R0, =0x40025000   @ Port F base
MOV R1, #0x04          @ Pin 2 (LED)
STR R1, [R0, #0x400]  @ GPIODIR = output
STR R1, [R0, #0x51C]  @ GPIODEN = enable
loop:
    STR R1, [R0, #0x3FC]  @ LED on
    BL delay
    MOV R2, #0
    STR R2, [R0, #0x3FC]  @ LED off
    BL delay
    B loop
delay:
    MOV R3, #0x10000
delay_loop:
    SUB R3, R3, #1
    CMP R3, #0
    BNE delay_loop
    BX LR
```

---

## 5.4 QEMU Peripheral Emulation Notes
- lm3s6965evb in QEMU fully emulates UART0 and GPIO Port F
- QEMU monitor commands to inspect peripherals:
  ```bash
  (qemu) info registers       @ Show CPU registers
  (qemu) x/1xw 0x4000C000   @ Read UARTDR
  (qemu) x/1xw 0x400253FC   @ Read GPIO Pin 2 state
  ```

---

## 5.5 Key Takeaways
1. Peripherals are memory-mapped, use `LDR`/`STR` to access
2. UART requires clock enable, GPIO config, and baud rate setup before use
3. GPIO masked access simplifies pin toggling
4. QEMU emulates lm3s6965evb peripherals accurately for testing

## 5.6 Common Pitfalls
- Forgetting to enable peripheral clocks (RCGC) → writes to peripheral registers ignored
- Using wrong GPIO masked address → pin not toggling
- Not waiting for UART TX ready → characters dropped

## 5.7 Next Steps
Complete **Lab 5 (GPIO Blinky)** to finish all labs.
