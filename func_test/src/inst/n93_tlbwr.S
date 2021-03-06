#include <asm/asm.h>
#include <asm/regdef.h>
#include <cpu.h>
#include <machine.h>
#include <ns16550.h>
#include <asm/context.h>
#include <inst_test.h>

### refers to testcase No.55

LEAF(n93_tlbwr_test)
    .set noreorder
    li  a0, 0x5d
###test inst
test_gbit_start:
    lui v0, 0xffe8
    ori v0, 0xdc03
    li s2, 0x0011
    sll s2, s2, 0x10
    li s0, 0xe124
    add s2, s0, s2
    lui s0, 0x0011
    ori s0, 0xe000
    lui a3, 0x1234
    ori a3, 0x5867
    li k0, 0x0001
    li t0, 0x0000
    li t1, 0x0000
    sw a3, 0(s2)
    nop
    nop
    nop
    nop
    nop
    lui t0, 0xed08
    ori t0, 0xdc16
    bne v1, t0, inst_error
    nop
    lui s2, 0x0011
    ori s2, 0xf124
    lw t0, 0(s2)
    lui a3, 0x1234
    ori a3, 0x5867
    bne a3, t0, inst_error
    nop
test_asid_match:
    lui v0, 0xffe8
    ori v0, 0xdc03
    li s2, 0x0012
    sll s2, s2, 0x10
    li k0, 0x0003
    ori s2, s2, 0xe124
    lui s0, 0x0012
    ori s0, 0xe0dc
    lui a3, 0xe235
    ori a3, 0xe8f7
    li t0, 0x0006
    li t1, 0x0006
    sw a3, 0(s2)
    nop
    nop
    nop
    nop
    nop
    lui t0, 0xed08
    ori t0, 0xdc18
    bne v1, t0, inst_error
    nop
    lui s0, 0x0013
    ori s0, 0xe0dc
    mtc0 s0, c0_entryhi
    lui s2, 0x0013
    ori s2, 0xf124
    lw t0, 0(s2)
    lui a3, 0xe235
    ori a3, 0xe8f7
    bne a3, t0, inst_error
    nop
test_asid_2:
    lui v0, 0xffe8
    ori v0, 0xdc03
    li s2, 0x0014
    sll s2, s2, 0x10
    li k0, 0x0004
    ori s2, s2, 0xe124
    lui s0, 0x0014
    ori s0, 0xe0dc
    lui a3, 0xbd86
    ori a3, 0x13ac
    li t0, 0x0000
    li t1, 0x0000
    sw a3, 0(s2)
    nop
    nop
    nop
    nop
    nop
    lui t0, 0xed08
    ori t0, 0xdc1f
    bne v1, t0, inst_error
    nop
    lui s0, 0x0015
    ori s0, 0xe0dc
    mtc0 s0, c0_entryhi
    lui s2, 0x0015
    ori s2, 0xf124
    lui s0, 0x0015
    ori s0, 0xe0dc
    li t0, 0x0000
    li t1, 0x0000
    li k0, 0x0004
    lw a3, 0(s2)
    lui a3, 0xed08
    ori a3, 0xdc1b
    bne a3, v1, inst_error
    nop
###score ++
    addiu s3, s3, 1
###output a0|s3
inst_error:  
    sw s3, 0($23)
    sw a0, 0(s1)
    jr ra
    nop
END(n93_tlbwr_test)
