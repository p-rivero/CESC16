; =====================
;  Timer/Delay Library
; =====================

#bank data
start_value: #res 1

#bank program

; Rename to "control flow"?
TIME:

; CONSTANTS
; Value of the timer when the count ends
.END_COUNT = 0xF000    ; TODO: Once the hardware bug is fixed, change to 0x0000

._STR:
..invalid_count: str("SetTimer: Invalid tick amount")
#align 32


.Halt:
    ; TODO: Output message indicating that execution is halted
    jmp pc
    
    
.Wait_ms:
    ; TODO: a0 is amount of ms to wait
    ; loop while a0>0, each iteration (including call/ret and decrementing a0) takes 1ms. Take into account oscillator freq
    ret
    
; Start a timer: a0 contains the amount of ticks to wait (1 tick = 16 clock cycles).
; When the timer ends, it will trigger an interrupt AND IT WILL STOP COUNTING.
; For periodic interrupts, the handler has to call TIME.SetTimer again).
; Warning: The latency from the overflow occurring to the user interrupt being called can be as high as 55 clock 
; cycles. Also, no assumptions can be made about the time it will take to return to the main program, since
; I/O handlers could also be called.
.SetTimer:
    sub a0, zero, a0        ; Timer counts up until END_COUNT, if we want to count a0 ticks,
    add a0, a0, .END_COUNT  ; the starting value is: a0 = END_COUNT - a0
    jnc ..error
    ; Todo: When END_COUNT is 0x0000, all values are valid. Remove the ADD and JNC instructions.
    
    mov [TIMER_ADDR], a0    ; The timer starts counting automatically
    mov [TMR_ACTIVE], 1     ; Mark timer as active
    mov [start_value], a0   ; Store the used start value for ReadTimer
    ret
..error:
    call .CancelTimer
    mov a0, ._STR.invalid_count
    syscall OUTPUT.error
    
; Cancel the current timer. Note that there is no way to stop the timer once it's started.
; However, when the cancelled timer ends, the user handler won't be called.
.CancelTimer:
    mov [TMR_ACTIVE], zero
    ret
    
; Read how many ticks have passed since SetTimer was called (1 tick = 16 clock cycles).
; Returns the result in a0.
.ReadTimer:
    mov a0, [TIMER_ADDR]
    sub a0, a0, [start_value]
    ret
    
; Attach an interrupt handler (jump address) to a timer overflow event
; WARNING: Those syscalls make use of the stack, and so they should be called in the correct order
; as if they were push/pop instructions.
.AttachInterrupt:
    swap a0, [HANDLERS.TMR] ; Attach new interrupt and retrieve old one
    swap a0, [sp] ; Simultaneously pop return address and push old interrupt handler
    jmp a0  ; Jump to return address

.DetachInterrupt:
    pop a0  ; Pop return address
    pop a1  ; Pop old interrupt handler
    mov [HANDLERS.TMR], a1  ; Attach old interrupt handler
    jmp a0  ; Jump to return address
    
    
    
; INTERRUPT HANDLER: it gets called when the timer reaches 0xFFFF
.Timer_Handler:
    movf t0, [HANDLERS.TMR] ; Load the address of the user interrupt handler
    jnz t0  ; If it's not zero, jump to the user handler
    ret     ; If it's zero, don't do anything

