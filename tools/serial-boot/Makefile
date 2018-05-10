XCOMPILE = mipsel-linux-gnu-
CC = $(XCOMPILE)gcc
LD = $(XCOMPILE)ld

bootserial: bootserial.o bootserial.ld
	$(LD) -nostdlib -T bootserial.ld -o bootserial bootserial.o

bootserial.o: bootserial.S
	$(CC) -c $^
