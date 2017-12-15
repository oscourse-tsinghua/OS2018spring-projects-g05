#include "vga.h"
#include <defs.h>
#include <thumips.h>

static int ltr = 2, ltc = 1, ltrn = 0, ltcn = 0, buflen = 0;
static uint8_t buf[64 * 24];

void _vga_put_one_char(uint8_t ch) {
  uint32_t latcAddr = LATTICE_BASE + (uint32_t)ch * 16;
  uint32_t latc;
  int pos = 0, r, c;
  for (r = 0; r < 16; ++r) {
    if ((r & 3) == 0) {
      latc = inw(latcAddr);
      latcAddr += 4;
      pos = 31;
    }
    for (c = 0; c < 8; ++c) {
      outb(VGA_BASE + (ltr + r) * 640 + ltc + c, 0);
      *((volatile uint8_t *)VGA_BASE + (ltr + r) * 640 + ltc + c) = 0;
      if ((latc >> pos) % 2 == 1) {
        outb(VGA_BASE + (ltr + r) * 640 + ltc + c, 0xff);
      }
      --pos;
    }
  }

  ++ltcn;
  if (ltcn == 64) {
    ltcn = 0;
    ++ltrn;
    ltc = 1;
    ltr += 20;
  }
  else {
    ltc += 10;
  }
}

void _vga_flush() {
  int k = 0;
  uint32_t addr;
  for (addr = VGA_BASE; k < buflen; ++k, ++addr) {
    _vga_put_one_char(buf[k]);
  }
}

void _vga_scroll() {
  ltr = 2;
  ltc = 1;
  ltrn = ltcn = 0;
  int k;
  for (k = 0; k < 64 * 24 - 64; ++k) {
    buf[k] = buf[k + 64];
  }
  for (k = 64 * 24 - 64; k < 64 * 24; ++k) {
    buf[k] = 0;
  }
  buflen -= 64;
  _vga_flush();
}

void vga_init() {
  ltr = 2;
  ltc = 1;
  ltrn = 0;
  ltcn = 0;
  buflen = 0;
  int i;
  for (i = 0; i < 64 * 24; i += 4) {
    *((uint32_t *)(buf + i)) = 0;
  }
  uint32_t addr;
  for (addr = VGA_BASE; addr < VGA_TOP; ++addr) {
    outb(addr, 0);
  }
}

void vga_putc(uint8_t ch) {
  if (ch == '\n') {
    int k = 64 - buflen % 64;
    while (k--) {
      vga_putc(' ');
    }
    return;
  }
  if (buflen == 64 * 24) {
    _vga_scroll();
  }
  buf[buflen] = ch;
  ++buflen;
  _vga_put_one_char(ch);
}