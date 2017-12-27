#include "vga.h"
#include <defs.h>
#include <thumips.h>

#define LINES 24
#define COLUMNS 64 // COLUMNS should be multiple of 4
#define CHAR_HEIGHT 16
#define CHAR_WIDTH 8

static int lineSt, lineEn; // Circulative, [lineSt, lineEn]
static int offset; // Horizontal position of current char
static uint8_t lines[LINES][COLUMNS];

void _vga_put_one_char(int ltrn, int ltcn, uint8_t ch) {
  const int ltr = ltrn * CHAR_HEIGHT, ltc = ltcn * CHAR_WIDTH;
  uint32_t latcAddr = LATTICE_BASE + (uint32_t)ch * 16;
  uint32_t latc;
  int pos = 0, r, c;
  for (r = 0; r < CHAR_HEIGHT; ++r) {
    if ((r & 3) == 0) {
      latc = inw(latcAddr);
      latcAddr += 4;
      pos = 31;
    }
    for (c = 0; c < CHAR_WIDTH; ++c) {
      if ((latc >> pos) % 2 == 1)
        outb(VGA_BASE + (ltr + r) * 640 + ltc + c, 0xff);
      else
        outb(VGA_BASE + (ltr + r) * 640 + ltc + c, 0);
      --pos;
    }
  }
}

void _vga_flush() {
  int ltrn, ltcn;
  for (ltrn = 0; ltrn < LINES; ltrn++) {
    const int lineID = (lineSt + ltrn) % LINES;
    for (ltcn = 0; ltcn < COLUMNS; ltcn++)
      _vga_put_one_char(ltrn, ltcn, lines[lineID][ltcn]);
  }
}

void _vga_nextline() {
  offset = 0;
  lineEn = (lineEn + 1) % LINES;
  if (lineEn == lineSt) {
    int i = 0;
    for (i = 0; i < COLUMNS; i += 4)
      *((uint32_t *)(lines[lineSt] + i)) = 0;
    lineSt = (lineSt + 1) % LINES;
    _vga_flush();
  }
}

void vga_init() {
  lineSt = lineEn = 0;
  offset = 0;
  int i;
  for (i = 0; i < LINES * COLUMNS; i += 4) {
    *((uint32_t *)(lines + i)) = 0;
  }
  uint32_t addr;
  for (addr = VGA_BASE; addr < VGA_TOP; ++addr) {
    outb(addr, 0);
  }
}

void vga_putc(uint8_t ch) {
  if (ch == '\n') {
    _vga_nextline();
    return;
  }
  if (++offset == COLUMNS)
    _vga_nextline();
  lines[lineEn][offset] = ch;
  _vga_put_one_char((lineEn - lineSt + LINES) % LINES, offset, ch);
}

