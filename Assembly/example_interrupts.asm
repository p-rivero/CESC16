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

str_done: str("DONE!\n")
#align 32
str_input: str("Got input: ")
#align 32


; User program entry point
MAIN_PROGRAM:
.main:
    mov [Sync], zero ; Initialize variables
    
    ; Attach interrupt handlers (defined below). The old handlers get stored in the stack
    mov a0, .Key_Handler
    syscall INPUT.AttachInterrupt
    
    mov a0, .TMR_Handler
    syscall TIME.AttachInterrupt
    
    
    ; Start timer
    mov a0, 0x1234
    syscall TIME.SetTimer
    
..wait:             ; Wait until the timer overflows and Sync gets set to 1.
    test [Sync]     ; Even if main program is halted, keystrokes will still trigger
    jz ..wait       ; interrupts and call OUTPUT.char
    
    mov a0, str_done
    syscall OUTPUT.string_ROM
    
    ; Stay on an endless loop after finishing, comment out this line if you wish to detach the handlers and return
    jmp pc
    
    ; Remember to pop the old handlers in the correct order (stack = LIFO)
    syscall TIME.DetachInterrupt
    syscall INPUT.DetachInterrupt
    
    ret
    
    
; INTERRUPT HANDLERS:
; Routine that will get called whenever a key is pressed down. The ASCII is stored in a0
.Key_Handler:
    mov t0, a0      ; Store the ASCII of the key
    mov a0, str_input
    syscall OUTPUT.string_ROM
    mov a0, t0      ; Restore the ASCII of the key
    syscall OUTPUT.char
    mov a0, "\n"    ; Print an endline
    syscall OUTPUT.char
    ret
   
; Routine that will get called whenever the timer overflows.
.TMR_Handler:
    mov t0, 1
    mov [Sync], t0  ; The global variable Sync signals the main program to exit the loop
    ret
    
