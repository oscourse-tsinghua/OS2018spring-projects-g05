#ifndef __KERN_DRIVER_VGA_H__
#define __KERN_DRIVER_VGA_H__

#include <thumips.h>
#include <defs.h>

void vga_init();
void vga_putc(uint8_t ch);

#endif