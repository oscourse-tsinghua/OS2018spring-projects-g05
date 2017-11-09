## 功能测试说明文件
### 步骤
1. 依赖：mipsel-linux-gnu工具链；jinja2，通过`pip install jinja2`安装（若你的python命令实际指向python3，则用`pip3 install jinja2`安装）。
2. 执行`cp testlist_example testlist`，在testlist内增删测例，一行一个测例，后面带“*”表示该测例是一条测试延迟槽或会触发异常的测例。
3. 执行`make ver=sim`生成仿真前需要写入ram中的数据文件。若需要，之后可通过`make clean ver=sim`清除。
4. 导入IP核文件。文件为ram/ram.xci，作为设计文件导入工程。打开IP核设置对话框（在Sources面板的IP Sources标签页中双击ram），在Other Options标签页选择初始化文件。在这里我们需要将步骤2生成的ram\_init\_data.coe载入。点击OK重新定制IP核。
5. 导入integration\_test.vhd、integration\_test\_const.vhd、fake\_ram.vhd作为仿真文件，将文件属性设置为VHDL 2008。
6. 开始仿真，在Tcl Console中会打印每个测例的运行状况（例如：“Test 1 passed”或“Test 2 failed”）。

### 注意事项
1. 功能仿真中能观测到ram的读或写有一定的延迟，因为我让ram的时钟稍微落后于cpu的时钟。
2. 要使导入的ram/ram.xci能正常工作，工程用到的芯片型号必须是xc7a100tfgg676-2L（这是工程模板中采用的型号）。你也可以自己生成一个IP核，就没有以上限制，步骤如下：在左边栏PROJECT MANAGER中点击IP Catalog。在IP Catalog面板中搜索Block Memory Generator，双击选择Block Memory Generator，进行IP核的定制。参数设置基本与ram/ram.xci中的一致（你可以先将ram/ram.xci导入，虽然无法工作，但是可以查看参数），唯一的不同在于Write Depth和Read Depth，这两者的最大取值与芯片型号相关。如果你用的不是上述型号，则可能需要将这两者设置小一点，或者可以将它们设置大一点（现在的取值接近上述型号所能允许的这两个参数的最大值）。
3. 由于芯片型号带来的限制，现在Write Depth和Read Depth的值是不足以容纳0x80000000~0x80200000的内存范围的，甚至不足以容纳把所有现有测例添加进来生成的ram初始化数据。所以加入testlist的测例不能过多，具体来说，`make ver=sim`之后，生成的ram_init_data.mif不能超过130000行。如果你选择了其他型号的芯片，并且该型号芯片所能设置的Write Depth和Read Depth更大，你可以将这两个值设置大一点来达到增加一次能接受的测例数的目的，但同时要注意的一点是，生成的程序会固定向两个地址写入数据：LED_ADDR和NUM_ADDR，在template_start.S中可以看到这两个值。如果你测例数较多，可能同时需要增加这两个地址，保证这两个地址在生成的代码数据的地址范围之外，以免向这两个地址写入数据的时候，破坏了在这两个地址的代码。另一点要注意的是，如果要增加Write Depth和Read Depth，有可能需要增加integration\_test\_const.vhd中的ram地址位数。
4. `make ver=sim`还会生成main.elf，执行`mipsel-linux-gnu-objdump -d main.elf`可以查看编译与链接过后，最终生成的可执行文件的每一条指令。
5. 仿真的时长需要设置得大一些，至少1ms。
6. 对于已有测例的说明及其他问题，可参考原来的说明文档readme_old.md（该文档的些说明可能与移植后的情况不相符）。