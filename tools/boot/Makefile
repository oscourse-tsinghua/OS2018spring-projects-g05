GCCPREFIX := mipsel-linux-gnu-
CC :=$(GCCPREFIX)gcc
CFLAGS	:=  -fno-builtin -nostdlib  -nostdinc -g  -EL -G0 -fno-delayed-branch -Wa,-O0
LD      := $(GCCPREFIX)ld
OBJCOPY := $(GCCPREFIX)objcopy
PYTHON := python3

all: boot_ctrl.vhd

loader.bin: bootasm.S
	$(CC) $(CFLAGS) -g -c -o loader.o $^
	$(LD) -EL -n -G0 -Ttext 0xbfc00000 -o loader loader.o
	$(OBJCOPY) -O binary -j .text -S loader $@

boot_ctrl.vhd: loader.bin boot_ctrl_template.vhd
	$(PYTHON) bit2vhd.py

clean:
	rm -rf loader* boot_ctrl.vhd