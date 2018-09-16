library ieee;
use ieee.std_logic_1164.all;
use work.global_const.all;

package config_const is
    constant CONFIG1_CONSTANT: std_logic_vector(31 downto 0) := 32ux"1e582c01";
    /* 
        config registers specification:
        for config0:
            bit 31      1, because config1 is present
            bit 30:25   5ub"0", we do not have a fixed mapping MMU
            bit 24:16   8ub"0", this field is reserved for implementation
            bit 15      0, because processor is running in little-endian mode
            bit 14:13   2ub"0", architecture type is mips32
            bit 12:10   3ub"0", revision level is release 1
            bit 9:7     3ub"1", we have a standard TLB
            bit 6:4     3ub"0", this field must be zero
            bit 3       0, instruction cache is not virtual
            bit 2:0     3, KSeg0 cacheability, 2 for uncached and 3 for cacheable
            only bit 2:0 is writable(but only write "010" or "011" is allowed here)

        for config1:
            bit 31      0, because config2 is not present
            bit 30:25   5ux"0f", TLB_ENTRY_NUM - 1
            bit 24:22   3ub"1", for I-cache is 128 sets per way
            bit 21:19   3ux"3", for I-cache line size is 16 bytes
            bit 18:16   0, for I-cache is direct mapped
            bit 15:13   3ub"1", for D-cache is 128 sets per way
            bit 12:10   3ux"3", for D-cache line size is 16 bytes
            bit 9:7     0, for D-cache is direct mapped
            bit 6       0, for coprocessor2 not implemented
            bit 5       0, for MDMX not supported
            bit 4       0, for no performance counter register implemented
            bit 3       0, for no watch register implemented
            bit 2       0, for mips16e not implemented
            bit 1       0, for EJTAG not implemented
            bit 0       1, for FPU(float point unit) not implemented
            0001 1110 0101 1000 0010 1100 0000 0000
            none is writable, could be directly initialized as 0x1e582c00

        below for "why config2 and config3 is not needed"
        for config2:
            bit 31      0, for config3 not present
            bit 30:28   0, for tertiary cache not present
            bit 27:16   0, for we don't have tertiary cache
            bit 15:12   0, for secondary cache not present
            bit 11:0    0, for we don't have secondary cache

        for config3:
            bit 31      0, for config4 not present
            bit 30      0, THIS FIELD MUST BE ZERO
            bit 29      0, GM GCR(Global Configuration Register Space) not implemented
            bit 28      0, MIPS SIMD structure not implemented
            bit 27      0, BadInstrP register not implemented
            bit 26      0, BadInstr register not implemented
            bit 25      0, Segment control not implemented
            bit 24      0, Page Table Walking not implemented
            bit 23      0, Virtualization Module not implemented
            bit 22:21   0, STATUS_IPL bits are 6-bits in width
            bit 20:18   0, This field will never be used
            bit 17      0, for MIPS MCU ASE not implemented
            bit 16      0, mips32 is used on entrance to an exception vector
            bit 15:14   0, only MIPS32 instruction set is implemented
            bit 13      0, UserLocal register not implemented
            bit 12      0, for PageGrain register not implemented
            bit 11      0, for revision 2 of the MIPS DSP module is not implemented
            bit 10      0, for MIPS DSP module not implemented
            bit 9       0, for CP0_ContextConfig register not implemented
            bit 8       0, for MIPS IFlowtrace not implemented
            bit 7       0, for large physical address support not implemented
            bit 6       0, for EIC interrupt mode not supported
            bit 5:4     0, for we are implementation of release 1
            bit 3       0, for common device memory map not implemented
            bit 2       0, for MIPS MT Module not implemented
            bit 1       0, for SmartMIPS ASE not implemented
            bit 0       0, for trace logic not implemented

        and so, config2 and config3 should always be zero. 
    */
    constant FIR_CONST: std_logic_vector(31 downto 0) := 32ux"00830000";
    /*
        fir register specification:
        for config0:
            bit 31:30   0, reserved
            bit 29      0, user-mode access of FRE is not supported
            bit 28      0, UFR is not needed
            bit 27:24   0, reserved
            bit 23      1, some IEEE754-2008 features is implementated
            bit 22      0, fpu is 32 bit
            bit 21      0, long-word fixed point not implemented
            bit 20      0, word fixed point not implemented
            bit 19      0, MIPS 3D not implemented
            bit 18      0, paired-single floating point is not implemented
            bit 17      1, double precision floating point is implemented
            bit 16      1, single precision floating point is implemented
            bit 15:8    CPU_id, implement through cp1.vhd
            bit 7:0     0, revision field not implemented
    */
end config_const;