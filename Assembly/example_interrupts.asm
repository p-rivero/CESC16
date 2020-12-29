; ======================
;   INTERRUPTS EXAMPLE
; ======================
; This example shows how to attach and detach interrupt handlers for different interrupt events

; Include definition and libraries
#include "CESC16.cpu"
#include "OS/OS.inc"

#bank data
Sync:   #res 1

#bank program

; User program entry point
MAIN_PROGRAM:
.main:
    mov (Sync), zero ; Initialize variables
    
    ; Attach interrupt handlers (defined below). The old handlers get stored in the stack
    mov a0, .KeyP_Handler
    syscall INPUT.AttachInterrupt.Pressed
    
    mov a0, .KeyR_Handler
    syscall INPUT.AttachInterrupt.Released
    
    mov a0, .TMR_Handler
    syscall TIME.AttachInterrupt
    
    
    ; Start timer
    mov a0, 0x1234
    syscall TIME.SetTimer
    
..wait:             ; Wait until the timer overflows and Sync gets set to 1.
    test (Sync)     ; Even if main program is halted, keystrokes will still trigger
    jz ..wait       ; interrupts and call PRINT.Char
    
    ; Remember to pop the old handlers in the correct order (stack = LIFO)
    syscall TIME.DetachInterrupt
    syscall INPUT.DetachInterrupt.Released
    syscall INPUT.DetachInterrupt.Pressed
    
    ret
    
    
; INTERRUPT HANDLERS:
; Routine that will get called whenever a key is pressed down. The ASCII is stored in a0
.KeyP_Handler:
    add a0, a0, 2
    syscall PRINT.Char
    ret
    
; Routine that will get called whenever a key is released. The ASCII is stored in a0
.KeyR_Handler:
    sub a0, a0, 2
    syscall PRINT.Char
    ret
   
; Routine that will get called whenever the timer overflows.
.TMR_Handler:
    mov t0, 1
    mov (Sync), t0  ; The global variable Sync signals the main program to exit the loop
    ret
    
