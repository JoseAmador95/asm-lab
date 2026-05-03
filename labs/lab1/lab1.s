.syntax unified
.thumb

.global main
.type main, %function
.thumb_func
main:
    ldr  r0, =msg_hello
    bl   semi_write0        @ print "Hello, Thumb2!\n"

    bl   semi_exit          @ terminate QEMU cleanly

.section .rodata
msg_hello:
    .asciz "Hello, Thumb2!\n"
