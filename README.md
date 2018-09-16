# 展示包
### 文件说明

- `vivado_prj`文件夹中包含Vivado工程入口、实现完成的bit文件、IP核相关文件；
- `myCPU`文件夹中是RTL源码；
- `constrs`文件夹中是约束文件；
- `soft`文件夹中是展示所需要的软件。

### 运行方法

1. 使用大赛提供的`programmer_by_uart`或其他工具，将`soft/u-boot-nscscc-small`烧写进SPI Flash；
2. 将`vivado_prj/top.bit`烧写进FPGA；
3. 用串口线和以太网线将实验板和任意一台计算机连接在一起，并将计算机的IP地址设为`192.168.1.30`、设置子网掩码使此计算机的IP实验板IP`192.168.1.20`在同一子网内；
4. 使用PuTTy或其他串口监视器以监视串口，使用[此程序](https://bitbucket.org/phjounin/tftpd64/downloads/Tftpd64-4.62-setup.exe)或其他TFTP服务器向网络提供`soft/linux-mp.ub`的下载，并将其置于TFTP服务的根目录；
5. 按下实验板的Reset按钮以开始运行，可在串口监视器上查看进度。系统会先进入U-Boot，然后从网络启动Linux。少数情况下可能遇到网络异常或Linux死机，可按reset重试；
6. 进入Linux后可在串口输入任意命令，也可以通过telnet登陆`192.168.1.30`来执行命令。可以执行`htop`命令以直观地查看系统状态。执行`htop`在内的部分命令耗时较长，请耐心等待。

### 软件说明

`soft`文件夹中提供了展示所需的软件。受限于空间，文件夹中只有二进制程序。若需要源码，可在[此GitHub仓库](https://github.com/roastduck/u-boot-naivemips/)的`nscscc`分支下载U-Boot的源码、在[此GitHub仓库](https://github.com/roastduck/linux)的`naivemips`分支下载Linux源码。