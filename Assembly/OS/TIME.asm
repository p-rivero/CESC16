#bank program

; Rename to "control flow"?
TIME:

.Halt:
    ; TODO: Output message indicating that execution is halted
    j .Halt
    
    
.Wait_ms:
    ; TODO: a0 is amount of ms to wait
    ; loop while a0>0, each iteration (including call/ret and decrementing a0) takes 1ms. Take into account oscillator freq
    ret
    
; Start a timer using the value stored in a0. The timer will tick (get incremented) every 16 clock cycles. Once it
; overflows, it will trigger an interrupt AND IT WILL STOP COUNTING (for perioding interrupts, the handler has to 
; call TIME.SetTimer again).
; Warning: The latency from the overflow occurring to the user interrupt being called can be as high as 55 clock cycles.
.SetTimer:
    mov [TIMER_ADDR], a0    ; Send char to timer. The timer starts counting automatically
    mov [TMR_ACTIVE], sp    ; Mark timer as active (any non-zero value means "true", and sp is guaranteed to never be 0)
    ret
    
; Cancel the current timer. Note that there is no way to stop the timer once it's started.
; However, when the cancelled timer overflows, the user handler won't be called.
.CancelTimer:
    mov [TMR_ACTIVE], zero
    ret
    
; Read the current value of the timer and store it in v0.
; The number of clock cycles that have passed since the call to TIME.SetTimer is (v0-INIT_VALUE)*16
.ReadTimer:
    mov v0, [TIMER_ADDR]
    ret
    
; Attach an interrupt handler (jump address) to a timer overflow event
; WARNING: Those syscalls make use of the stack, and so they should be called in the correct order
; as if they were push/pop instructions.
.AttachInterrupt:
    swap a0, [HANDLERS.TMR] ; Attach new interrupt and retrieve old one
    swap a0, [sp] ; Simultaneously pop return address and push old interrupt handler
    j a0    ; Jump to return address

.DetachInterrupt:
    pop a0  ; Pop return address
    pop a1  ; Pop old interrupt handler
    mov [HANDLERS.TMR], a1  ; Attach old interrupt handler
    j a0    ; Jump to return address
    
    
    
; INTERRUPT HANDLER: it gets called when the timer reaches 0xFFFF
.Timer_Handler:
    movf t0, [HANDLERS.TMR] ; Load the address of the user interrupt handler
    jnz t0  ; If it's not zero, jump to the user handler
    ret     ; If it's zero, don't do anything
    
