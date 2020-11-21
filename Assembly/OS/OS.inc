; Draft for a basic CESC16 OS

#ifndef _OS
#define _OS
; Include OS code only once

; Constants:
KEYBOARD_ADDR = 0xFF00
TERMINAL_ADDR = 0xFF40
GPIO_2_ADDR = 0xFF80
GPIO_3_ADDR = 0xFFC0

#include "STARTUP.asm"
#include "MATH.asm"
#include "KEYBOARD_IN.asm"
#include "TERMINAL_OUT.asm"
#include "TIME.asm"
    
_OS_END:

#endif
