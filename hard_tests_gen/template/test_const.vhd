{{{NOTICE}}}

package {{{TEST_NAME}}}_test_const is
    -- The simulator handle a too large memory space
    constant MAX_RAM_ADDRESS: integer := 1024 - 1;

    constant CLK_PERIOD: time := 10 ns;
end {{{TEST_NAME}}}_test_const;
