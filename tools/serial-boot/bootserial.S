/*
	Boot loader for noname pad
	Xihang Liu
	May 8th, 2018
*/
#define SOH 0x01
#define EOT 0x04
#define ACK 0x06
#define NAK 0x15
#define CLK_COUNT 0x00040000

/* temp variables for byte operation: $25 to $28 */
#define load_byte(dst, base, offset) \
	add $25, base, offset; \
	li $26, 0x3; \
	and $27, $26, $25; \
	sub $28, $25, $27; \
	lw $26, 0($28); \
	li $25, 0xff; \
	sll $27, $27, 0x3; \
	sllv $25, $25, $27; \
	and $26, $26, $25; \
	srlv dst, $26, $27;


#define store_byte(dst, base, offset) \
	add $25, base, offset; \
	li $26, 0x3; \
	and $27, $26, $25; \
	sub $28, $25, $27; \
	lw $26, 0($28); \
	li $25, 0xff; \
	sll $27, $27, 0x3; \
	sllv $25, $25, $27; \
	and $25, $25, $26; \
	xor $26, $26, $25; \
	sllv $27, dst, $27; \
	add $26, $26, $27; \
	sw $26, 0($28)

.set noreorder
#define FLASH_START 0x80400000

.global bootentry
.type bootentry, @function
bootentry:
    li $2, 0x0002                   /* Magic */
    la $3, 0xbfd0f000               /* LED */
    sw $2, 0($3)

	la $4, 0xbfd003f8
	la $7, 0x80000300				/* $7 for tmp base address */
	la $10, FLASH_START 			/* $10 for total word store location */
	li $21, 0x0084 					/* $21 for frame length */
	li $23, 0x7c01 					/* set $23 to enable interrupt */
	mtc0 $23, $12
	li $24, 0x01

wait_sometime:
	mtc0 $23, $12
	la $5, CLK_COUNT
	li $8, 0x01

countdown:
	sub $5, $5, $8
	bnez $5, countdown
	nop
	mtc0 $0, $12
	nop
	nop
	nop
	nop

send_nak:
	li $6, NAK
	sw $22, 8($7)
	sw $13, 12($7)
	sw $6, 0($4)
	li $22, 0x00
	b wait_sometime
	nop

receive_byte:
	mtc0 $0, $12
	nop
	nop
	nop
	nop
	lw $13, 4($4)
	li $3, 0x02
	beq $13, $3, start_receive
	nop
	li $3, 0x03
	beq $13, $3, start_receive
	nop
	b wait_sometime
	nop
start_receive:
	addiu $22, $22, 0x1 			/* $22 frame count */
	lw $13, 0($4)
	li $3, 0x01
	beq $22, $3, frame_first_byte
	nop
	li $3, 0x02
	beq $22, $3, frame_second_byte
	nop
	li $3, 0x03
	beq $22, $3, frame_third_byte
	nop
	li $3, 0x04
	subu $3, $22, $3
	store_byte($13, $7, $3)
	beq $22, $21, calc_checksum
	nop
	b wait_sometime
	nop

frame_first_byte:
	li $3, EOT
	beq $13, $3, bootloader_start
	nop
	li $3, SOH
	beq $13, $3, wait_sometime
	nop
	b send_nak
	nop

frame_second_byte:
	addiu $20, $13, 0x0001
	beq $20, $24, send_ack
	nop
	beq $13, $24, wait_sometime		/* $24 frame id */
	nop
	b send_nak
	nop

frame_third_byte:
	li $3, 0xff
	subu $3, $3, $24
	beq $3, $13, wait_sometime
	nop
	b send_nak
	nop

calc_checksum:
	li $11, 0x80
	li $12, 0x00
	li $13, 0x00

calc:
	load_byte($14, $7, $12)
	addiu $12, $12, 0x0001
	add $13, $13, $14
	bne $12, $11, calc
	nop

compare:
	andi $13, $13, 0xff
	load_byte($14, $7, $12)
	addiu $12, $12, 0x0001
	beq $13, $14, copy_segment
	nop
	b send_nak
	nop

copy_segment:
	li $11, 0x00
	li $12, 0x20
	or $13, $7, $0

copyword:
	addiu $13, 0x0004
	addiu $10, 0x0004
	lw $14, -4($13)
	sw $14, -4($10)
	addiu $11, $11, 0x1
	bne $11, $12, copyword
	nop

send_ack:
	li $6, ACK
	sw $6, 0($4)
	li $22, 0x00
	addiu $24, $24, 0x1
	andi $24, $24, 0xff
	b wait_sometime
	nop

bootloader_start:
	li $6, ACK
	sw $6, 0($4)
	mtc0 $0, $12
#define FLASH_SIZE  0x04000000
#define ELF_MAGIC 0x464C457F

/* off = offset from s0 */
/* load a 32bit word from Flash,
 * off is byte-addressed */
#define LOAD_WORD_I(dst, off) \
	la $t7, off; \
	addu $t7, $s0, $t7; \
	lw dst, 0($t7);

#define LOAD_WORD_R(dst, off, base) \
	addiu $t7, base, off; \
	addu $t7, $s0, $t7; \
	lw dst, 0($t7);

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

bad:
  	b bad
  	nop

.section interrupt
    la $25, 0x807ff87c        /* TODO: FIXME: Use relocation */
    jr $25
    nop

