; Draft for a basic CESC16 OS

#ifndef _OS
#define _OS
; Include OS code only once

; Constants:
KEYBOARD_ADDR = 0xFF00
TERMINAL_ADDR = 0xFF01
IO_DEV_2_ADDR = 0xFF02
IO_DEV_3_ADDR = 0xFF03

#include "STARTUP.asm16"
#include "MATH.asm16"
#include "KEYBOARD_IN.asm16"
#include "TERMINAL_OUT.asm16"
#include "TIME.asm16"
    
_OS_END:

#endif