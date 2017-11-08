##功能测试说明文件
###步骤
1. 依赖：mipsel-linux-gnu工具链；jinja2，通过`pip install jinja2`安装（若默认使用python3，则用`pip3 install jinja2`安装）。
2. 执行`cp testlist_example testlist`，在testlist内增删测例，一行一个测例，后面带“*”表示该测例是一条与测试延迟槽或会触发异常的测例。
3. 执行`make ver=sim`生成仿真前需要写入ram中的数据文件。若需要，之后可通过`make clean ver=sim`清除。
4. 导入IP核文件。文件为ram/ram.xci，作为设计文件导入工程。打开IP核设置对话框（在Sources面板的IP Sources标签页中双击ram），在Other Options标签页选择初始化文件。在这里我们需要将步骤2生成的ram\_init\_data.coe载入。点击OK重新定制IP核。
5. 导入integration\_test.vhd、integration\_test\_const.vhd、fake\_ram.vhd作为仿真文件，将文件属性设置为VHDL 2008。
6. 开始仿真，在Tcl Console中会打印每个测例的运行状况（例如：“Test 1 passed”或“Test 2 failed”）。

###注意事项
1. fake ram是对IP核的ram的一个封装，虽然它暴露的端口有两个读端口一个写端口（为了同时满足取指阶段的读请求和访存阶段的读或写请求），但其内部是串行地执行对于ram的一次写操作，两次读操作，并通过比CPU时钟快得多的时钟来达到同时进行两读一写的效果。所以要注意的是，fake ram只能用于仿真，同时功能仿真中也能观测到读或写有一定的延迟。
2. 要使导入的ram/ram.xci能正常工作，工程用到的芯片型号必须是xc7a100tfgg676-2L（这是工程模板中采用的型号）。你也可以自己生成一个IP核，就没有以上限制，步骤如下：在左边栏PROJECT MANAGER中点击IP Catalog。在IP Catalog面板中搜索Block Memory Generator，双击选择Block Memory Generator，进行IP核的定制。参数设置基本与ram/ram.xci中的一致（你可以先将ram/ram.xci导入，虽然无法工作，但是可以查看参数），唯一的不同在于Write Depth和Read Depth，这两者的最大取值与芯片型号相关。如果你用的不是上述型号，则可能需要将这两者设置小一点，或者可以将它们设置大一点（现在的取值接近上述型号所能允许的这两个参数的最大值）。要注意的一点是，由于芯片型号带来的限制，现在Write Depth和Read Depth的值是不足以容纳0x80000000~0x80200000的内存范围的，但足够容纳把所有现有测例添加到testlist后，生成的初始化数据。不过虽然能容纳生成的数据，但不能百分之百保证访存指令访问的地址还能落在当前设置下ram的地址范围内。所以如果可以的话，尽可能把Write Depth和Read Depth设置得大一些（有可能需要在integration\_test\_const.vhd中修改地址的位数）。
3. `make ver=sim`还会生成main.elf，执行`mipsel-linux-gnu-objdump -d main.elf`可以查看编译与链接过后，最终生成的可执行文件的每一条指令。
4. 仿真的时长需要设置得大一些，至少1ms。
5. 对于已有测例的说明及其他问题，可参考原来的说明文档readme_old.md（该文档的一些说明可能与移植后的情况不相符）。