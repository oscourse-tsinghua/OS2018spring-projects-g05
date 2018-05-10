ENTRY(bootentry)

SECTIONS {
    . = 0x80000180;
    interrupt = . ;
    . = 0x807ff800;
    .text = . ;
}
