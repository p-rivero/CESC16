
// Using Arduino Nano or Uno
#ifndef __AVR_ATmega328P__
#define __AVR_ATmega328P__ 
#endif

#include <Arduino.h>
#include <SoftwareSerial.h>
#include "PS2Keyboard.h"

// CONSTANTS

const unsigned long BAUDRATE = 19200;

// Constants for the keyboard interface
const byte CPU_ACK = 0x06;
const byte CPU_RDY = 0x07;

namespace PINS {
    // OUTPUT
    // Bits 0..5 are pins A0..A5 (bits 0..5 of PORTC)
    const byte OUT_6 = 13;  // Output bit 6 of the data
    const byte SEND = 12;   // Send the data
    //! The arduino won't be able to receive serial data (Pin 0 = RX)
    const byte IRQ = 0;     // Interrupt the CPU
    
    // INPUT
    // Bits 0..2 are pins D5..D7 (bits 5..7 of PORTD)
    // Bits 3..6 are pins D8..D11 (bits 0..3 of PORTB)
    const byte CLEAR = 2;   // Clear the input register 
    
    // PS/2 Keyboard
    const byte PS2_DATA = 4;    // Data from the PS/2 keyboard
    const byte PS2_CLK = 3;     // Clock from the PS/2 keyboard
}

// Character map for translating scancodes (from a spanish keyboard with non-standard layout)
// into ascii characters (all non-ascii characters have been removed)
const PROGMEM PS2Keymap_t PS2Keymap_CustomSpanish = {
  // without shift
    {0, PS2_F9, 0, PS2_F5, PS2_F3, PS2_F1, PS2_F2, PS2_F12,
    0, PS2_F10, PS2_F8, PS2_F6, PS2_F4, PS2_TAB, 0 /*'º'*/, 0,
    0, 0 /*Lalt*/, 0 /*Lshift*/, 0, 0 /*Lctrl*/, 'q', '1', 0,
    0, 0, 'z', 's', 'a', 'w', '2', 0,
    0, 'c', 'x', 'd', 'e', '4', '3', 0,
    0, ' ', 'v', 'f', 't', 'r', '5', 0,
    0, 'n', 'b', 'h', 'g', 'y', '6', 0,
    0, 0, 'm', 'j', 'u', '7', '8', 0,
    0, ',', 'k', 'i', 'o', '0', '9', 0,
    0, '.', '-', 'l', 0 /*PS2_n_TILDE*/, 'p', '\'', 0,
    0, 0, 0/*'´'*/, 0, '`', 0/*'¡'*/, 0, 0,
    0 /*CapsLock*/, 0 /*Rshift*/, PS2_ENTER /*Enter*/, '+', 0, 0 /*PS2_c_CEDILLA*/, 0, 0,
    0, '<', 0, 0, 0, 0, PS2_BACKSPACE, 0,
    0, '1', 0, '4', '7', 0, 0, 0,
    '0', '.', '2', '5', '6', '8', PS2_ESC, 0 /*NumLock*/,
    PS2_F11, '+', '3', '-', '*', '9', PS2_SCROLL, 0,
    0, 0, 0, PS2_F7 },
  // with shift
    {0, PS2_F9, 0, PS2_F5, PS2_F3, PS2_F1, PS2_F2, PS2_F12,
    0, PS2_F10, PS2_F8, PS2_F6, PS2_F4, PS2_TAB, 0 /*'ª'*/, 0,
    0, 0 /*Lalt*/, 0 /*Lshift*/, 0, 0 /*Lctrl*/, 'Q', '!', 0,
    0, 0, 'Z', 'S', 'A', 'W', '"', 0,
    0, 'C', 'X', 'D', 'E', '$', 0 /*'·'*/, 0,
    0, ' ', 'V', 'F', 'T', 'R', '%', 0,
    0, 'N', 'B', 'H', 'G', 'Y', '&', 0,
    0, 0, 'M', 'J', 'U', '/', '(', 0,
    0, ';', 'K', 'I', 'O', '=', ')', 0,
    0, ':', '_', 'L', 0 /*PS2_N_TILDE*/, 'P', '?', 0,
    0, 0, 0 /*'¨'*/, 0, '^', 0 /*'¿'*/, 0, 0,
    0 /*CapsLock*/, 0 /*Rshift*/, PS2_ENTER /*Enter*/, '*', 0, 0 /*PS2_C_CEDILLA*/, 0, 0,
    0, '>', 0, 0, 0, 0, PS2_BACKSPACE, 0,
    0, '1', 0, '4', '7', 0, 0, 0,
    '0', '.', '2', '5', '6', '8', PS2_ESC, 0 /*NumLock*/,
    PS2_F11, '+', '3', '-', '*', '9', PS2_SCROLL, 0,
    0, 0, 0, PS2_F7 },
    1,
  // with altgr
    {0, PS2_F9, 0, PS2_F5, PS2_F3, PS2_F1, PS2_F2, PS2_F12,
    0, PS2_F10, PS2_F8, PS2_F6, PS2_F4, PS2_TAB, '\\', 0,
    0, 0 /*Lalt*/, 0 /*Lshift*/, 0, 0 /*Lctrl*/, 0, '|', 0,
    0, 0, 0, 0, 0, 0, '@', 0,
    0, 0, 0, 0, 0, '~', '#', 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0 /*'¬'*/, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, '{', 0, '[', 0, 0, 0,
    0 /*CapsLock*/, 0 /*Rshift*/, PS2_ENTER /*Enter*/, ']', 0, '}', 0, 0,
    0, 0, 0, 0, 0, 0, PS2_BACKSPACE, 0,
    0, '1', 0, '4', '7', 0, 0, 0,
    '0', '.', '2', '5', '6', '8', PS2_ESC, 0 /*NumLock*/,
    PS2_F11, '+', '3', '-', '*', '9', PS2_SCROLL, 0,
    0, 0, 0, PS2_F7 }
};




// HELPER FUNCTIONS

class char_queue {
private:
    static const int BUFFER_SZ = 128; // Important: power of 2
    char buffer[BUFFER_SZ];
    byte in_index = 0;   // Where to push
    byte out_index = 0;  // Where to pop
    
public:
    void push(char data) {
        buffer[in_index++] = data;  // Store new value in the buffer
        in_index &= (BUFFER_SZ-1);  // Keep index in the range [0, BUFFER_SZ)
    }
    char pop() {
        // Important: call only if queue is not empty
        char data = buffer[out_index++];
        out_index &= (BUFFER_SZ-1); // Keep index in the range [0, BUFFER_SZ)
        return data;
    }
    bool empty() {
        return (in_index == out_index);
    }
};

// Send a byte to the main CPU (doing so will cause an INTERRUPT).
void write_byte(byte data) {
    // WARNING: I made an error in the circuit and the pins are
    // connected in reverse order. We need to shuffle the bits of data:
    // data: _6543210  ==>  reverse_data: __012345
    byte reverse_data = 0;
    for (int i = 0; i <= 5; i++) {   // For bits 0..5
        if (data & (1 << i)) {   // If bit is set
            // Flip bit in reverse order (0->5, 1->4, ...)
            reverse_data |= 1 << (5 - i); 
        }
    }
    
    digitalWrite(PINS::OUT_6, data & (1 << 6)); // Bit 6
    PORTC = reverse_data;   // Bits 1..5 in the correct order
    // Send the data
    digitalWrite(PINS::SEND, 1);
    digitalWrite(PINS::SEND, 0);
}

// Read the byte stored in input register
byte read_byte() {
    // Bits 0..2 are pins D5..D7 (bits 5..7 of PORTD)
    byte data = PIND >> 5;
    // Bits 3..6 are pins D8..D11 (bits 0..3 of PORTB)
    data |= PINB << 3;
    
    return data;
}



// MAIN FUNCTIONS

PS2Keyboard keyboard;
SoftwareSerial serial(14, 1); // RX, TX
char_queue queue;
bool output_reg_full = false;
bool can_interrupt = false;


inline void interrupt_CPU() {
    digitalWrite(PINS::IRQ, HIGH);
    delay(10);
    digitalWrite(PINS::IRQ, LOW);
}
inline void clear_input_reg() {
    digitalWrite(PINS::CLEAR, 1);
    digitalWrite(PINS::CLEAR, 0);
}
inline void clear_output_reg() {
    write_byte(0);
    output_reg_full = false;
}


void setup() {
    // By default all pins are in INPUT mode

    digitalWrite(PINS::IRQ, LOW);
        
    digitalWrite(PINS::SEND, LOW);
    pinMode(PINS::SEND, OUTPUT);
    
    digitalWrite(PINS::CLEAR, LOW);
    pinMode(PINS::CLEAR, OUTPUT);
    
    DDRC = 0b00111111; // A0..A5 to output
    pinMode(PINS::OUT_6, OUTPUT);
    
    // Clear output register at startup
    write_byte(0);
    
    // Initialize keyboard
    keyboard.begin(PINS::PS2_DATA, PINS::PS2_CLK, PS2Keymap_CustomSpanish);
    
    // Initialize hardware serial
    serial.begin(BAUDRATE);
    
    // Wait 1 second for the programmer to send a program
    delay(1000);
    pinMode(PINS::IRQ, OUTPUT);
}

void loop() {
    // If no char is being presented and the queue is not empty
    if (!output_reg_full && can_interrupt && !queue.empty()) {
        // Send current char to CPU
        byte data = queue.pop();
        write_byte(data);
        interrupt_CPU();
        output_reg_full = true;
        can_interrupt = false;
    }
    
    // Receive command/char from CPU
    byte in = read_byte();
    if (in != 0) {
        if (in == CPU_ACK) {
            clear_output_reg();
        }
        else if (in == CPU_RDY) {
            can_interrupt = true;
            if (output_reg_full) clear_output_reg();
        }
        else {
            // Todo: convert from terminal commands to escape sequences
            // Regular char, send to serial
            serial.print(char(in));
        }
        clear_input_reg();
    }
    
    // Receive char from PS/2 keyboard
    if (keyboard.available()) {
        byte data = keyboard.read();
        if (data != 0) queue.push(data);
    }
    
    // Receive char from serial line
    if (serial.available()) {
        byte data = serial.read();
        if (data != 0) queue.push(data);
    }
}

