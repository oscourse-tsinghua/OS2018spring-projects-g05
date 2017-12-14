设该目录的绝对路径或相对于当前工作目录路径为XXX，要编译的c文件为1.c、2.c。执行`bash XXX/gen.sh 1.c 2.c`，会在当前工作目录下产生一个文件a.bin。将其烧入base ram，将thinpad_top.bin烧入FPGA（注意需要使用`FUNC_TEST`模式）即可。

注意用`sh XXX/gen.sh 1.c 2.c`可能会出问题。