

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
    
.SetTimer:
    ; Placeholder for future timer interrupts
    ret
    
.AttachInterrupt:
    ; Placeholder for future timer interrupts
    ret

.DetachInterrupt:
    ; Placeholder for future timer interrupts
    ret
    