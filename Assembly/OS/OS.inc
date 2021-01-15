; Draft for a basic CESC16 OS

#ifndef _OS
#define _OS
; Include OS code only once

; Constants:
INTERRUPT_VECTOR = 0x0011
INIT_STACK = 0xFEFF ; The stack gets predecremented, so it could start at 0xFF00. However, I prefer leaving 1 extra space between stack and I/O
KEYBOARD_ADDR = 0xFF00
TERMINAL_ADDR = 0xFF40
TIMER_ADDR = 0xFF80
GPIO_3_ADDR = 0xFFC0

#bank data
HANDLERS:
.KEY_PRESSED:   #res 1  ; Address of the subroutine to be called when a key is pressed
.KEY_RELEASED:  #res 1  ; Address of the subroutine to be called when a key is released
.TMR:           #res 1  ; Address of the subroutine to be called when the timer overflows

TMR_ACTIVE:     #res 1  ; A non-zero value indicates that the timer is currently active

#include "STARTUP.asm"
#include "MEMORY.asm"
#include "MATH.asm"
#include "INPUT.asm"
; TODO: Rename to TERMINAL_OUT to OUTPUT.asm
#include "TERMINAL_OUT.asm"
#include "TIME.asm"
    
_OS_END:

#endif
