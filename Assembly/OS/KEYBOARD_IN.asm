; ========================
;  Keyboard Input library
; ========================

; WARNING: THIS LIBRARY IS OBSOLETE

#bank program

INPUT:

; Constants:
.MASK_BREAK = 0x4000  ; From Keyboard Interface
.MASK_ENTER = 0x2000  ; From Keyboard Interface

.INSERT = 22      ; From PS2Keyboard.h
.HOME = 23        ; From PS2Keyboard.h
.PAGEUP = 25      ; From PS2Keyboard.h
.PAGEDOWN = 26    ; From PS2Keyboard.h


; ----------------
; WAIT UNTIL INPUT
; ----------------

; Halts the program until a keyboard input (press down or lift up) is available and returns the input.
; WARNING: INPUT.Wait doesn't remove the "lift up" version of its input. When calling INPUT.WaitFull after having 
; called INPUT.Wait, the first detected input will probably be the remnants of the last INPUT.Wait call.
.WaitFull:
    movf v0, (KEYBOARD_ADDR)    ; Read from keyboard
    jz .WaitFull                ; Poll until it's not 0
    mov (KEYBOARD_ADDR), zero   ; Acknowledge input
    
    ; Search for special values:
    
    ; If HOME key was released, reset computer
    cmp v0, .HOME | .MASK_BREAK
    jeq STARTUP.Reset ; Jump to reset vector
    
    ; More keys can be checked here
    
    ; No special key detected, return the input
    ret
    
    
; Halts the program until a keyboard input (only press down) is available and returns the input.
.Wait:
    call .WaitFull          ; Get both make and break inputs
    mask v0, .MASK_BREAK    ; Detect if the input was break
    jnz .Wait               ; If it was, keep waiting
    
    ret
    

; -----------------------
; GET CURRENT INPUT STATE
; -----------------------

; Checks if a keyboard input (press down or lift up) is available. 
; If it is, returns the input. If it isn't, returns 0.
; WARNING: INPUT.Get doesn't remove the "lift up" version of its input. When calling INPUT.GetFull after having 
; called INPUT.Get, the first detected input will probably be the remnants of the last INPUT.Get call.
.GetFull:
    movf v0, (KEYBOARD_ADDR)    ; Read from keyboard
    jz ..return                 ; If there was no input, return 0
    mov (KEYBOARD_ADDR), zero   ; Else acknowledge input

    ; There was input, search special values
    
    ; If HOME key was released, reset computer
    cmp v0, .HOME | .MASK_BREAK
    jeq STARTUP.Reset ; Jump to reset vector
    
    ; More keys can be checked here
    
..return:
    ; No special key detected, return the input
    ret
 
 
; Checks if a keyboard input (only press down) is available.
; If it is, returns the input. If it isn't, returns 0.
.Get:
    call .GetFull           ; Get both make and break inputs
    mask v0, .MASK_BREAK    ; Detect if the input was break
    jz ..return             ; If it wasn't, return the value
    mov v0, 0               ; If it was, return 0
    
..return:
    ret
