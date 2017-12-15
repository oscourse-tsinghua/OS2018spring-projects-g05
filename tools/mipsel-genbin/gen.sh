#!/bin/bash

TOOLCHAIN=mipsel-linux-gnu-
MYPATH=`dirname $0`/

${TOOLCHAIN}gcc -c $@ -mno-abicalls
${TOOLCHAIN}as ${MYPATH}entry.S -o entry.o
${TOOLCHAIN}ld -T ${MYPATH}ldscript.ld entry.o ${@/.c/.o} -o a.elf
${TOOLCHAIN}objcopy -O binary -j .text -j .data -j .bss -j .bss -j .sbss \
        a.elf a.bin \
        --set-section-flags .bss=alloc,load,contents \
        --set-section-flags .sbss=alloc,load,contents

rm ${@/.c/.o} entry.o a.elf
