#/* $Id: start.S,v 1.1.1.1 2006/09/14 01:59:08 root Exp $ */

/*
 * Copyright (c) 2001 Opsycon AB  (www.opsycon.se)
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. All advertising materials mentioning features or use of this software
 *    must display the following acknowledgement:
 *  This product includes software developed by Opsycon AB, Sweden.
 * 4. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS
 * OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 */

#ifndef _KERNEL
#define _KERNEL
#endif

#ifdef SIM
#define WAIT_COUNT 00000001
#else
    #ifndef TEST_DELAY_RAM
    #define WAIT_COUNT 11000000
    #else
    #define WAIT_COUNT 05000000
    #endif
#endif

#include <asm/asm.h>
#include <asm/regdef.h>
#include <cpu.h>
#include <machine.h>
#include <ns16550.h>
#include <asm/context.h>

#define LED_ADDR                0xbfd0f000
#define NUM_ADDR                0xbfd0f010

  .set  noreorder
  .globl  _start
  .globl  start
  .globl  __main
#   .set noat
_start:
start:
    lui a2,0x0040
  mtc0  a2, c0_status
  mtc0  zero, c0_cause
  la  sp, _stack
  la  gp, _gp
    ori a3,zero,0x0000
    mtlo a3
    ori t8,zero,0x0000
    mthi t8

  j locate      /* Get current execute address */
  nop

/*
 *  exception handle
 */
.org 0x380
    li  v1, 0x01 # syscall
    beq v0, v1, syscall_ex
    nop
    li  v1, 0x02 # break
    beq v0, v1, break_ex
    nop
    li  v1, 0x03 # eret
    beq v0, v1, eret_ex
    nop
    li  v1, 0x04 # overflow
    beq v0, v1, overflow_ex
    nop
    li  v1, 0x05 # adel(load)
    beq v0, v1, adel_load_ex
    nop
    li  v1, 0x06 # ades
    beq v0, v1, ades_ex
    nop
    li  v1, 0x07 # adel(inst fetch)
    beq v0, v1, adel_if_ex
    nop
    li  v1, 0x08 # reserved inst
    beq v0, v1, reserved_inst_ex
    nop
    li  v1, 0x09 # delay slot
    beq v0, v1, delay_slot_ex
    nop
    b other_ex
    nop
syscall_ex:
    addu  v0, zero, zero
    mfc0 k0, c0_epc
    la   k1, syscall_pc
    bne  k0, k1, other_ex
    nop
    mfc0 k0, c0_cause
    andi k0, k0, 0x7c # 6..2
    li   k1, 0x20 # 010_00
    bne  k0, k1, other_ex
    nop
    mfc0 k0, c0_status
    andi k0, k0, 0x02
    li   k1, 0x02
    bne  k0, k1, other_ex
    nop
    lui  v0, 0x00ff
    b other_ex
    nop
break_ex:
    addu  v0, zero, zero
    mfc0 k0, c0_epc
    la   k1, break_pc
    bne  k0, k1, other_ex
    nop
    mfc0 k0, c0_cause
    andi k0, k0, 0x7c # 6..2
    li   k1, 0x24 # 010_0100
    bne  k0, k1, other_ex
    nop
    mfc0 k0, c0_status
    andi k0, k0, 0x02 # exl
    li   k1, 0x02 # exl = 1
    bne  k0, k1, other_ex
    nop
    lui  v0, 0xff00
    b other_ex
    nop
eret_ex:
    la  k0, eret_ret_pc
    mtc0 k0, c0_epc
    lui  v0, 0x0f0f
    b other_ex
    nop
overflow_ex:
    addu v0, zero, zero 
    mfc0 k0, c0_cause
    andi k0, k0, 0x7c # 6..2 exc code
    li   k1, 0x30 # 011_0000
    bne  k0, k1, other_ex
    nop
    mfc0 k0, c0_status
    andi k0, k0, 0x02 # exl
    li k1, 0x02 # exl = 1
    bne k0, k1, other_ex
    nop
    lui v0, 0x1234
    b other_ex
    nop
adel_load_ex:
    addu v0, zero, zero 
    mfc0 k0, c0_cause
    andi k0, k0, 0x7c # 6..2 exc code
    li   k1, 0x10 # 001_0000
    bne  k0, k1, other_ex
    nop
    mfc0 k0, c0_status
    andi k0, k0, 0x02 # exl
    li k1, 0x02 # exl = 1
    bne k0, k1, other_ex
    nop
    lui v0, 0x5678
    b other_ex
    nop
ades_ex:
    addu v0, zero, zero 
    mfc0 k0, c0_cause
    andi k0, k0, 0x7c # 6..2 exc code
    li   k1, 0x14 # 001_0100
    bne  k0, k1, other_ex
    nop
    mfc0 k0, c0_status
    andi k0, k0, 0x02 # exl
    li k1, 0x02 # exl = 1
    bne k0, k1, other_ex
    nop
    lui v0, 0x1111
    b other_ex
    nop
adel_if_ex:
    addu v0, zero, zero 
    mtc0 k1, c0_epc
    mfc0 k0, c0_cause
    andi k0, k0, 0x7c # 6..2 exc code
    li   k1, 0x10 # 001_0000
    bne  k0, k1, other_ex
    nop
    mfc0 k0, c0_status
    andi k0, k0, 0x02 # exl
    li k1, 0x02 # exl = 1
    bne k0, k1, other_ex
    nop
    lui v0, 0x2222
    b other_ex
    nop
reserved_inst_ex:
    addu v0, zero, zero 
    mfc0 k0, c0_cause
    andi k0, k0, 0x7c # 6..2 exc code
    li   k1, 0x28 # 010_1000
    bne  k0, k1, other_ex
    nop
    mfc0 k0, c0_status
    andi k0, k0, 0x02 # exl
    li k1, 0x02 # exl = 1
    bne k0, k1, other_ex
    nop
    lui v0, 0x3333
    b other_ex
    nop
delay_slot_ex:
    addu v0, zero, zero
    mfc0 k0, c0_cause
    lui k1, 0x8000
    and k0, k0, k1
    bne k0, k1, other_ex
    nop
    lui v0, 0x4444
other_ex:
    mfc0 k0,c0_cause
    mfc0 v1,c0_epc
    lui k1,0x8000
    addiu v1,v1,0x4
    and k0,k0,k1
    beq k0,zero, 1f
    nop
    addiu v1,v1,0x4
1:  
    mtc0  v1,c0_epc
    bne v0, zero, ex_ret
    nop
    lui v0, 0xffff
ex_ret:
    .set mips32
    eret
    .set mips1
    nop
    nop
    nop


locate:
  .set noreorder

    li t1, 0x0000ffff
    li t0, LED_ADDR
    sw t1, 0(t0)

    li s1, NUM_ADDR
    lui s3, 0
    sw s3, 0(s1)
    xor s7, s7, s7

inst_test:
{% for test in tests %}{% if test.ex %}
    la v0, {{ test.name }}
    jalr v0
    nop
    addiu s7, s7, 1
    jal wait_1s
    nop
{% else %}
    jal {{ test.name }}
    nop
    addiu s7, s7, 1
    jal wait_1s
    nop
{% endif %}{% endfor %}


test_end:
    li  a0, {{ tests|length }}
    li s1, NUM_ADDR
    sw s3, 0(s1)
    beq a0, s3, 1f
    nop

    b  2f
    nop
1:

    li t0, LED_ADDR
    sw zero, 0(t0)

2:  b 2b
    nop

wait_1s:
#    li t0, 11000000
    li t0, WAIT_COUNT
1:
    addiu t0, -1
    bne t0,zero, 1b
    nop
    jr ra
    nop
