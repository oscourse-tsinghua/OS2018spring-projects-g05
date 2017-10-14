package test_const is
    subtype RamDataWidth is integer range 31 downto 0;
    subtype RamAddrWidth is integer range 31 downto 0;
    subtype intWidth is integer range 5 downto 0;

    constant MAX_RAM_ADDRESS: integer := 16 * 1024 * 1024 - 1;

    constant CLK_PERIOD: time := 10 ns;
end test_const;
