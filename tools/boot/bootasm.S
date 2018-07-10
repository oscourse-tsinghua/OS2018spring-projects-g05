#define FLASH_START 0xBE000000
#define FLASH_SIZE  0x01000000
#define ELF_MAGIC 0x464C457F

/* off = offset from s0 */
/* load a 32bit word from Flash,
 * off is byte-addressed */
#define LOAD_WORD_I(dst, off) \
  la $t7, off; \
  addu $t7, $s0, $t7; \
  lw dst, 0($t7);

#define LOAD_WORD_R(dst, off, base) \
  addiu $t7, base, off;\
  addu $t7, $s0, $t7; \
  lw dst, 0($t7);

#assume file base == FLASH_START

.set noreorder
.set noat
.globl __start
__start:
  #spin if not the first CPU, and jump to *0x7ffffc if not zero
  mfc0 $t0, $15, 1
  andi $t0, $t0, 0x3ff
  beq $t0, $0, load_elf
  nop
  la $t0, 0x7ffffc
  sw $0, 0($t0)

spin:
  lw $t1, 0($t0)
  beq $t1, $0, spin
  nop
  jr $t1
  nop

load_elf:
  #dirty hack
  la $t0, (FLASH_START+FLASH_SIZE - 8)
  la $t1, 0x00FF
  sw $t1, 0($t0)

  #addr of elfheader, s0
  la $s0, FLASH_START
  #e_magic
  LOAD_WORD_I($t1, 0)
  la $t0, ELF_MAGIC
  beq $t0, $t1, 1f
  nop
  b bad
  nop
1:
  #e_phoff
  LOAD_WORD_I($s1, 28)
  #e_phnum
  LOAD_WORD_I($s2, 44)
  andi $s2, $s2, 0xFFFF

  #e_entry
  LOAD_WORD_I($s3, 24)

next_sec:
  #s1, addr proghdr
  #s4, p_va
  LOAD_WORD_R($s4, 8, $s1)
  #s5, p_filesz
  LOAD_WORD_R($s5, 16, $s1)
  #s6, p_offset
  LOAD_WORD_R($s6, 4, $s1)

  beq  $s4, $zero, 3f
  nop
  beq  $s5, $zero, 3f
  nop

#copy from file_base+p_offset to p_va
copy_sec:
  LOAD_WORD_R($t0, 0, $s6)
  sw $t0, 0($s4)
  addiu $s6, $s6, 4
  addiu $s4, $s4, 4
  addiu $s5, $s5, -4
  bgtz  $s5, copy_sec
  nop

3:
  addiu $s1, $s1, 32
  addiu $s2, $s2, -1
  bgtz  $s2, next_sec
  nop

done:
#jump to kernel
  jr $s3
  nop
  b .
  nop

bad:
  b bad
  nop

