## PS/2 Keyboard + Serial

The CESC16 computer only has 4 GPIO ports. Therefore, in order to add new features, some of them have to share the same port.

For this reason, this peripheral is responsible for doing 2 seemingly unrelated things:

- **Interfacing with a keyboard (PS/2)**: The controller interprets keystrokes from a PS/2 keyboard, using the [`PS2Keyboard` library](https://github.com/PaulStoffregen/PS2Keyboard). When a key is pressed, the controller sends an interrupt to the CPU.

- **Serial line with another computer (UART)**: Using the FTDI chip included in the Arduino, the controller can send and receive characters using UART-over-USB.
    - Characters received over the serial line are sent to the CPU as if they were keyboard keystrokes.
    - When the CPU writes to the GPIO port, the character is sent over the serial line.

