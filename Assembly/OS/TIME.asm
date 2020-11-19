

#bank program
#bits 32

; Rename to "control flow"?
TIME:

.Halt:
    ; TODO: Output message indicating that execution is halted
    ; INPUT.WaitFull will reset the computer if the reset key is pressed 
    syscall INPUT.WaitFull
    j .Halt
    
    
.Wait_ms:
    ; TODO: a0 is amount of ms to wait
    ; loop while a0>0, each iteration (including call/ret and decrementing a0) takes 1ms. Take into account oscillator freq
    ret
    

; Halts until any key gets pressed, then continues execution normally.
; Allows the user to switch to manual or 555 clock before continuing.
.Breakpoint:
    push v0
    call INPUT.Wait
    
    ; Visual indicator that execution is about to continue
    mov v0, 0xFFFF  ; Flash all the LEDs of v0 for 3 cycles
    pop v0
    ret
    