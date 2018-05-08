{{{NOTICE}}}

package {{{TEST_NAME}}}_test_const is
    -- The simulator handle a too large memory space
    constant RAM_ADDR_WIDTH: integer := 10;
    constant MAX_RAM_ADDRESS: integer := 2 ** RAM_ADDR_WIDTH - 1;

    constant CLK_PERIOD: time := 10 ns;
end {{{TEST_NAME}}}_test_const;
