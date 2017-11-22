package flash_const is
    constant CLKS_TO_GET_DATA: integer := 3;

    subtype FlashAddrSliceWidth is integer range 23 downto 2;
    subtype FlashAddrWidth is integer range 22 downto 0;
    subtype FlashDataWidth is integer range 15 downto 0;
    subtype FlashDataHiWidth is integer range 31 downto 16;
    subtype FlashDataLoWidth is integer range 15 downto 0;
end flash_const;