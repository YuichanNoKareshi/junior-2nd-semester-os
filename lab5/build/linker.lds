       

SECTIONS
{
    . = 0x80000;
    img_start = .;
    init : {
        CMakeFiles/kernel.img.dir/boot/start.S.o
        CMakeFiles/kernel.img.dir/boot/mmu.c.o
        CMakeFiles/kernel.img.dir/boot/tools.S.o
        CMakeFiles/kernel.img.dir/boot/init_c.c.o
        CMakeFiles/kernel.img.dir/boot/uart.c.o
    }

    . = ALIGN(0x4000);

    init_end = ABSOLUTE(.);

    .text 0xffffff0000000000 + init_end : AT(init_end) {
        *(.text*)
    }

    . = ALIGN(0x10000);
    .data : {
        *(.data*)
    }
    . = ALIGN(0x10000);

    .rodata : {
        *(.rodata*)
    }
    _edata = . - 0xffffff0000000000;

    _bss_start = . - 0xffffff0000000000;
    .bss : {
        *(.bss*)
    }
    _bss_end = . - 0xffffff0000000000;
    . = ALIGN(0x10000);
    img_end = . - 0xffffff0000000000;
}
