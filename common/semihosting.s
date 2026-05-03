.syntax unified
.thumb

@ ARM Semihosting helpers
@
@ Semihosting calling convention:
@   r0 = operation number
@   r1 = pointer to argument block
@   BKPT 0xAB triggers the host
@
@ Public API:
@   semi_write0   r0=ptr  — print null-terminated string to stdout
@   semi_print_hex r0=val — print r0 as "0x????????\n"
@   semi_print_dec r0=val — print r0 as unsigned decimal + "\n"
@   semi_exit            — terminate QEMU cleanly (exit code 0)

@ ---------------------------------------------------------------------------
@ semi_write0 — SYS_WRITE0 (0x04): print null-terminated string
@ In:  r0 = pointer to null-terminated string
@ Clobbers: r0, r1
@ ---------------------------------------------------------------------------
.global semi_write0
.type semi_write0, %function
.thumb_func
semi_write0:
    push {r1, lr}
    mov  r1, r0             @ r1 = string pointer
    mov  r0, #0x04          @ SYS_WRITE0
    bkpt 0xAB
    pop  {r1, pc}

@ ---------------------------------------------------------------------------
@ semi_print_hex — print r0 as "0x????????\n"
@ In:  r0 = 32-bit value to print
@ Clobbers: r0-r3
@ ---------------------------------------------------------------------------
.global semi_print_hex
.type semi_print_hex, %function
.thumb_func
semi_print_hex:
    push {r4, r5, lr}
    mov  r4, r0                 @ save value

    @ build "0x????????\n\0" in hex_buf (12 bytes)
    ldr  r5, =hex_buf
    mov  r0, #'0'
    strb r0, [r5]
    mov  r0, #'x'
    strb r0, [r5, #1]

    mov  r3, #7                 @ digit index 7..0
hex_loop:
    and  r0, r4, #0xF           @ low nibble
    cmp  r0, #9
    ble  hex_digit_num
    add  r0, r0, #('a' - 10)
    b    hex_digit_store
hex_digit_num:
    add  r0, r0, #'0'
hex_digit_store:
    add  r2, r5, #2             @ offset past "0x"
    add  r2, r2, r3
    strb r0, [r2]
    lsr  r4, r4, #4             @ next nibble
    subs r3, r3, #1
    bpl  hex_loop

    mov  r0, #'\n'
    strb r0, [r5, #10]
    mov  r0, #0
    strb r0, [r5, #11]

    mov  r0, r5
    bl   semi_write0
    pop  {r4, r5, pc}

@ ---------------------------------------------------------------------------
@ semi_print_dec — print r0 as unsigned decimal + "\n"
@ In:  r0 = 32-bit unsigned value
@ Clobbers: r0-r3
@ ---------------------------------------------------------------------------
.global semi_print_dec
.type semi_print_dec, %function
.thumb_func
semi_print_dec:
    push {r4, r5, r6, lr}
    mov  r4, r0                 @ value to convert

    ldr  r5, =dec_buf
    @ write digits right-to-left into dec_buf[0..10], then newline+null
    add  r6, r5, #10            @ r6 points one past last digit slot
    mov  r0, #'\n'
    strb r0, [r6]
    mov  r0, #0
    strb r0, [r6, #1]

    @ special case: value == 0
    cmp  r4, #0
    bne  dec_loop
    mov  r0, #'0'
    sub  r6, r6, #1
    strb r0, [r6]
    b    dec_print

dec_loop:
    cmp  r4, #0
    beq  dec_print
    @ r4 / 10 — use repeated subtraction via udiv emulation
    @ Thumb2 has UDIV on Cortex-M3 (requires hardware divide support)
    mov  r0, r4
    mov  r1, #10
    udiv r2, r0, r1             @ r2 = r0 / 10
    mul  r3, r2, r1             @ r3 = r2 * 10
    sub  r3, r0, r3             @ r3 = remainder (digit)
    add  r3, r3, #'0'
    sub  r6, r6, #1
    strb r3, [r6]
    mov  r4, r2
    b    dec_loop

dec_print:
    mov  r0, r6
    bl   semi_write0
    pop  {r4, r5, r6, pc}

@ ---------------------------------------------------------------------------
@ semi_exit — SYS_EXIT (0x18): terminate the QEMU session
@ In:  (none) — exits with ADP_Stopped_ApplicationExit (success)
@ ---------------------------------------------------------------------------
.global semi_exit
.type semi_exit, %function
.thumb_func
semi_exit:
    push {r1, lr}
    ldr  r1, =semi_exit_block
    mov  r0, #0x18              @ SYS_EXIT
    bkpt 0xAB
    b    .                      @ should not return

@ ---------------------------------------------------------------------------
@ Mutable scratch buffers (in .bss / .data)
@ ---------------------------------------------------------------------------
.section .bss
.align 2
hex_buf:    .space 12           @ "0x" + 8 hex digits + "\n\0"
dec_buf:    .space 12           @ up to 10 decimal digits + "\n\0"

.section .rodata
.align 2
semi_exit_block:
    .word 0x20026               @ ADP_Stopped_ApplicationExit
    .word 0                     @ exit code 0
