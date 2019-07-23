
# 编译主线内核
## 预编译固件
为方便测试，现提供预先编译好的使用主线内核的 Ubuntu 14.04 固件，其特性为：

*  集成 Mali 内核和用户驱动，以及 OpenGL ES 示例。
*  使用板载的 eMMC 存储，无需额外的 TF 卡。
*  HDMI 显示支持。
  
## 准备工作

本文假定工作目录是 "~/proj/linux-rockchip"：
```
mkdir -p ~/proj/linux-rockchip
```
### 安装开发包

安装开发包：
```
sudo apt-get install build-essential lzop libncurses5-dev libssl-dev
# 如果使用的是 64 位的 Ubuntu，还需要安装：
sudo apt-get install libc6:i386
```
### 交叉编译工具链

本文使用 Android SDK 的预置交叉编译工具链来编译测试。
将 Android SDK 的 prebuilt 目录拷贝到工作目录下：
```
cd ~/proj/linux-rockchip
cp -rl ANDROID_SDK/prebuilts .
```
"prebuilts/gcc/linux-x86/arm/" 里的 arm-eabi-4.6 和 arm-eabi-4.7 是所需要的交叉编译工具链。其中，U-Boot 使用 arm-eabi-4.7，内核使用 arm-eabi-4.6。
### 工具
将 ANDROID SDK 里的一些工具安装到系统中：
```
cd ANDROID_SDK
cp ./kernel/mkkrnlimg /usr/local/bin
cp ./RKTools/linux/Linux_Upgrade_Tool_v1.2/upgrade_tool /usr/local/bin
```
另外建议安装 [rkflashkit](https://github.com/linuxerwang/rkflashkit)

## parameter

以下是固件使用的 parameter 文件，最主要是分区的设定：
 
 *  kernel: 烧写 kernel.img (RK KNRL 格式，用 mkkrnlimg 打包）
 *  boot: 烧写 boot.img (RK KNRL 格式，用 mkkrnlimg 打包）
 *   linuxroot: 烧写 linuxroot.img （ext4fs 格式）
```
FIRMWARE_VER:4.4.2
MACHINE_MODEL:rk30sdk
MACHINE_ID:007
MANUFACTURER:RK30SDK
MAGIC: 0x5041524B
ATAG: 0x60000800
MACHINE: 3066
CHECK_MASK: 0x80
PWR_HLD: 0,0,A,0,1
#KERNEL_IMG: 0x62008000
#FDT_NAME: rk-kernel.dtb
#RECOVER_KEY: 1,1,0,20,0
CMDLINE:console=ttyS2,115200 earlyprintk root=/dev/block/mtd/by-name/linuxroot rw rootfstype=ext4 init=/sbin/init initrd=0x62000000,0x00800000 mtdparts=rk29xxnand:0x00008000@0x00002000(kernel),0x00008000@0x0000A000(boot),0x00002000@0x00012000(misc),0x00001000@0x00014000(backup),-@0x00015000(linuxroot)
```
烧写 paramter 文件到设备上：
```
sudo rkflashkit flash @parameter parameter.txt
```
要提取设备上的 parameter 文件，可以使用：
```
sudo rkflashkit backup @parameter parameter.txt
```

## U-Boot

主线内核需要配套的 U-Boot，而不是 SDK 上的。
### 编译 U-Boot
下载并编译 U-Boot:

```
cd ~/proj/linux-rockchip
git clone -b u-boot-rk3288 https://github.com/linux-rockchip/u-boot-rockchip.git u-boot
cd u-boot
make rk3288_defconfig
make -j4
```
U-Boot 编译成功后，最后的几行信息是：
```
LD u-boot
OBJCOPY u-boot.bin
OBJCOPY u-boot.srec
./tools/boot_merger --subfix ".01.bin" ./tools/rk_tools/RKBOOT/RK3288.ini
out:RK3288UbootLoader.bin
fix opt:RK3288UbootLoader_V2.19.01.bin
merge success(RK3288UbootLoader_V2.19.01.bin)
```
"RK3288UbootLoader_V2.19.01.bin" 就是成功编译出来的映像，可以用 upgrade_tool 烧写到板子上。
### Flash U-Boot
```
sudo upgrade_tool ul RK3288UbootLoader_V2.19.01.bin
```
## 内核
由于主线内核版本更新很快，目前测试的版本是基于 v4.0-rc1 。

测试分支位于：
[https://github.com/TeeFirefly/linux-rockchip/tree/firefly](https://github.com/TeeFirefly/linux-rockchip/tree/firefly)

该分支基于：
[https://git.kernel.org/cgit/linux/kernel/git/mmind/linux-rockchip.git/log/?h=v4.1-armsoc/dts](https://git.kernel.org/cgit/linux/kernel/git/mmind/linux-rockchip.git/log/?h=v4.1-armsoc/dts)

并加入 Mali 内核驱动代码：
[https://github.com/mmind/linux-rockchip/tree/devel/mali-workbench](https://github.com/mmind/linux-rockchip/tree/devel/mali-workbench)

因为加入了命令行参数 “mtdparts=” 指定分区的支持，这样可以维持原有 RK SDK 方式，在 parameter 文件中设定 eMMC 分区。
### 编译内核

首先是下载源码：
```
cd ~/proj/linux-rockchip
git clone -b firefly https://github.com/TeeFirefly/linux-rockchip.git kernel
```
然后编译内核和模块：
```
cd ~/proj/linux-rockchip/kernel
export ARCH=arm
export CROSS_COMPILE=$PWD/../prebuilts/gcc/linux-x86/arm/arm-eabi-4.6/bin/arm-eabi-
make rk3288_firefly_defconfig
make -j4 zImage
make rk3288-firefly.dtb
cat arch/arm/boot/zImage arch/arm/boot/dts/rk3288-firefly.dtb > zImage-dtb
mkkrnlimg zImage-dtb kernel.img    
# 编译并安装模块
make -j4 modules
[ -d install_mod ] && rm -rf install_mod
make INSTALL_MOD_PATH=$PWD/install_mod modules_install
# 复制 install_mod 目录里的文件到根文件系统
```
### 烧写内核
```
sudo rkflashkit flash @kernel /path/to/kernel.img
```
## initramfs
### 创建 boot.img
```
cd ~/proj/linux-rockchip
git clone https://github.com/TeeFirefly/initrd.git
make -C initrd
mkkrnlimg initrd.img boot.img # 打包成 RK KRNL 格式
```
### 烧写 boot.img
```
sudo rkflashkit flash @boot /path/to/boot.img
```
## 根文件系统

要创建根文件系统 linuxroot.img，请参考《创建 Ubuntu 根文件系统》一文。

烧写 linuxroot.img：
```
sudo upgrade_tool di linuxroot /path/to/linuxroot.img
```
## FAQ
### 已知问题

 *   VGA： VGA 显示支持尚未添加。
 *   WiFi：AP6335 驱动尚未移植。

由于 RK3288 的主线内核支持尚未完善，在使用过程中会出现的 HDMI 显示刷新慢，USB 外设支持不好等问题。
### zImage-dtb 是什么?

zImage-dtb 是内核加设备树块，当 CONFIG_ARM_APPENDED_DTB 打开时，内核会在尾部查找 DTB。