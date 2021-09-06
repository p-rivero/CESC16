BOARD=arduino:avr:nano
BUILDDIR=build
PORT=COM4
FILENAME=Keyboard_Serial.ino

upload: $(BUILDDIR)/$(FILENAME).hex
	arduino-cli upload -b $(BOARD) -p $(PORT) -i $(BUILDDIR)/$(FILENAME).hex --verify

$(BUILDDIR)/$(FILENAME).hex: $(FILENAME)
	arduino-cli compile -b $(BOARD) --build-path=$(BUILDDIR) --build-cache-path=$(BUILDDIR)/cache
