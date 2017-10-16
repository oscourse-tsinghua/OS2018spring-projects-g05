library ieee;
use ieee.std_logic_1164.all;
use work.global_const.all;

package alu_const is
    constant ALUSEL_LOGIC: std_logic_vector(AluSelWidth) := "001";
    constant ALUOP_OR: std_logic_vector(AluOpWidth) := "00000001";
    constant ALUOP_AND: std_logic_vector(AluOpWidth) := "00000010";
end alu_const;