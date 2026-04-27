.syntax unified
.thumb

.section .isr_vector, "a", %progbits
.align 2

.global _stack_top
.word _stack_top
.word Reset_Handler
.word NMI_Handler
.word HardFault_Handler
.word MemManage_Handler
.word BusFault_Handler
.word UsageFault_Handler
.word 0
.word 0
.word 0
.word 0
.word SVC_Handler
.word DebugMon_Handler
.word 0
.word PendSV_Handler
.word SysTick_Handler

.weak NMI_Handler
.thumb_set NMI_Handler, Default_Handler
.weak HardFault_Handler
.thumb_set HardFault_Handler, Default_Handler
.weak MemManage_Handler
.thumb_set MemManage_Handler, Default_Handler
.weak BusFault_Handler
.thumb_set BusFault_Handler, Default_Handler
.weak UsageFault_Handler
.thumb_set UsageFault_Handler, Default_Handler
.weak SVC_Handler
.thumb_set SVC_Handler, Default_Handler
.weak DebugMon_Handler
.thumb_set DebugMon_Handler, Default_Handler
.weak PendSV_Handler
.thumb_set PendSV_Handler, Default_Handler
.weak SysTick_Handler
.thumb_set SysTick_Handler, Default_Handler

.global Default_Handler
.type Default_Handler, %function
.thumb_func
Default_Handler:
    b Default_Handler

.global Reset_Handler
.type Reset_Handler, %function
.thumb_func
Reset_Handler:
    ldr r0, =_sidata
    ldr r1, =_sdata
    ldr r2, =_edata
    cmp r1, r2
    beq copy_done
copy_loop:
    ldr r3, [r0], #4
    str r3, [r1], #4
    cmp r1, r2
    bne copy_loop
copy_done:

    ldr r0, =_sbss
    ldr r1, =_ebss
    cmp r0, r1
    beq zero_done
    mov r2, #0
zero_loop:
    str r2, [r0], #4
    cmp r0, r1
    bne zero_loop
zero_done:

    bl main
    b Default_Handler
