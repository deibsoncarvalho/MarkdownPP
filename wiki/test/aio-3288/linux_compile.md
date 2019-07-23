# 编译 Ubuntu16.04 固件(GPT) 
## 前言
本 SDK 开发环境是在 Ubuntu 上开发测试的。我们推荐使用 Ubuntu 16.04 的系统进行编译。其他的 Linux 版本可能需要对软件包做相应调整。
除了系统要求外,还有其他软硬件方面的要求。
## 准备工作
### 硬件要求：
64 位系统,硬盘空间大于 40G。如果您进行多个构建,将需要更大的硬盘空间。
### 软件要求：编译环境初始化
* Ubuntu 14.04 软件包安装：
```
$ sudo apt-get install git gnupg flex bison gperf build-essential \
zip tar curl libc6-dev libncurses5-dev:i386 x11proto-core-dev \
libx11-dev:i386 libreadline6-dev:i386 libgl1-mesa-glx:i386 \
libgl1-mesa-dev g++-multilib mingw32 cmake tofrodos \
python-markdown libxml2-utils xsltproc zlib1g-dev:i386 lzop lib32stdc++6
$ sudo ln -s /usr/lib/i386-linux-gnu/mesa/libGL.so.1 /usr/lib/i386-linux-gnu/libGL.so
```
* Ubuntu 16.04 软件包安装
```
sudo apt-get install git gcc-arm-linux-gnueabihf u-boot-tools device-tree-compiler mtools \
parted libudev-dev libusb-1.0-0-dev python-linaro-image-tools linaro-image-tools libssl-dev \
autotools-dev libsigsegv2 m4 libdrm-dev curl sed make binutils build-essential gcc g++ bash \
patch gzip bzip2 perl tar cpio python unzip rsync file bc wget libncurses5 libglib2.0-dev openssh-client lib32stdc++6
```
* 安装 ARM 交叉编译工具链和编译内核相关软件包
```
$ sudo apt-get install gcc-arm-linux-gnueabihf \
gcc-aarch64-linux-gnu device-tree-compiler lzop libncurses5-dev \
libssl1.0.0 libssl-dev
```
### 下载LINUX-SDK：
提供两种方式给用户下载：1：Github上同步SDK；2：下载源码包（推荐国内用户使用）
#### Github上同步SDK
* 下载repo工具：
```
mkdir linux
cd linux
git clone https://github.com/FireflyTeam/repo.git
```
* 初始化仓库：
```
repo init --repo-url https://github.com/FireflyTeam/repo.git -u https://github.com/FireflyTeam/manifests.git -b linux-sdk -m rk3288/rk3288_linux_release.xml
```
#### 下载源码包（推荐国内用户使用）
* 下载repo工具：
```
mkdir linux
cd linux
git clone https://github.com/FireflyTeam/repo.git
```

* 下载链接：[Linux-SDK GPT源码包](http://www.t-firefly.com/doc/download/page/id/16.html#other_208)

* 解压文件：7z x linux-sdk-3288.7z

<font color=#ff0000 size=3>注意</font>:解压完之后，用户可能会疑惑看不到文件。在linux/目录运行`ls -a`命令，有`.repo`/目录，这是我们的仓库。

### 同步源码：
```
repo sync -c
```
<font color=#ff0000 size=3>注意</font>:从Github上同步SDK时，部分国内用户会有不稳定的现象，这就需要多次运行同步命令`repo sync -c`才可以

目录
```
$ tree -L 1
.
├── app
├── buildroot buildroot根文件系统的编译目录
├── build.sh -> device/rockchip/common/build.sh 全自动编译脚本
├── device
├── distro
├── docs 开发文档
├── envsetup.sh -> buildroot/build/envsetup.sh
├── external
├── kernel 内核
├── Makefile -> buildroot/build/Makefile
├── mkfirmware.sh -> device/rockchip/common/mkfirmware.sh 打包脚本
├── prebuilts
├── rkbin
├── rkflash.sh -> device/rockchip/common/rkflash.sh 烧写脚本
├── rootfs
├── tools
└── u-boot
```
## 编译SDK

### 编译前配置：
在device/rockchip/rk3288/目录下，选择对应的板型的配置文件

本文例子：确定选用rk3288/aio-3288c.mk

aio-3288c.mk 相关配置介绍：
```
# Target arch
export RK_ARCH=arm                                      32位ARM架构
# Uboot defconfig
export RK_UBOOT_DEFCONFIG=firefly-rk3288                u-boot配置文件
# Kernel defconfig
export RK_KERNEL_DEFCONFIG=firefly_linux_defconfig      kernel配置文件
# Kernel dts
export RK_KERNEL_DTS=rk3288-firefly-aioc                dts文件
# parameter for GPT table
export RK_PARAMETER=parameter-ubuntu.txt                分区表（关键）
# rootfs image path
export RK_ROOTFS_IMG=buildroot/output/$RK_CFG_BUILDROOT/images/rootfs.$RK_ROOTFS_TYPE  根文件系统路径
```
<font color=#ff0000 size=3>重点</font>:

#### 配置Rootfs
源码中默认的Linux rootfs是buildroot，如果rootfs使用buildroot，跳过此步，如果用户需要使用Ubuntu，需要通过以下步骤来配置：

1、 下载根文件系统：[ubuntu16.04 根文件系统(32位)](http://www.t-firefly.com/doc/download/page/id/51.html#other_192)，放到SDK路径下;

2、 该文件为7z压缩包，解压该文件；
```
7z x ubuntu1604armhf-rootfs.7z
```
3、 完成上述后，得到ubuntu1604armhf-rootfs.img(2.6G),拷贝根文件系统到rootfs目录下；
```
cp ubuntu1604armhf-rootfs.img rootfs/
```
4、 在device/rockchip/rk3288/aio-3288c.mk中， 将“# rootfs image path”修改为：
```
export RK_ROOTFS_IMG=rootfs/ubuntu1604armhf-rootfs.img
```
#### 配置板型
根据各个板型和配件的差别，内核中使用的DTS也有差别，如果是标配板型，跳过此步，如果板型有VGA或者LCD等支持，需要在.BoardConfig.mk中做对应的修改。
* Firefly-rk3288
```
# 标配：
export RK_KERNEL_DTS=rk3288-firefly
# 带VGA：
export RK_KERNEL_DTS=rk3288-firefly-vga
```
* AIO-3288C
```
# 标配：
export RK_KERNEL_DTS=rk3288-firefly-aioc
# 带VGA:
export RK_KERNEL_DTS=rk3288-firefly-aioc-vga
# LVDS(HSX101H40C):
export RK_KERNEL_DTS=rk3288-firefly-aioc-lvds
```
* AIO-3288J
```
# 标配：
export RK_KERNEL_DTS=rk3288-firefly-aio
# LVDS(HSX101H40C):
export RK_KERNEL_DTS=rk3288-firefly-aio-lvds
```
#### 编译配置文件：
```
./build.sh aio-3288c.mk
```
运行完上述脚本后，在device/rockchip/目录下，生成.BoardConfig.mk 软链接 device/rockchip/rk3288/aio-3288c.mk
### 完全编译
完全编译运行如下命令，包含 kernel 、uboot、buildroot、recovery。 如果用户使用`buildroot`，可以使用完全编译。如果用户使用`Ubuntu`系统，则不需要使用完全编译。
```
./build.sh 
```
<font color=#ff0000 size=3>注意：</font>该脚本默认编译`buildroot`根文件系统，若用户需要用的根文件系统是`Debian`或者`Ubuntu16.04`时，请！先！将！对应的根文件系统准备好，不然在执行该build.sh脚本时，会在整理分区镜像、打包固件时出错，这部分操作在以下的“部分编译”中“编译rootfs”有详细说明，按照操作执行即可！

build.sh脚本运行完成后，会将分区镜像和统一固件update.img放在rockdev/目录下，同时创建IMAGE/目录备份。

### 模块化编译：

#### 编译u-boot:
```
./build.sh uboot
```
#### 编译kernel:
```
./build.sh kernel
```
#### 编译rootfs:
本SDK支持三种根文件系统，分别是buildroot、Debian、Ubuntu;
* Buildroot 

编译 Buildroot 环境搭建所依赖的软件包安装命令如下:
```
sudo apt-get install repo git-core gitk git-gui gcc-arm-linux-gnueabihf u-boot-tools device-tree-compiler \
gcc-aarch64-linux-gnu mtools parted libudev-dev libusb-1.0-0-dev python-linaro-image-tools linaro-image-tools \
autoconf autotools-dev libsigsegv2 m4 intltool libdrm-dev curl sed make binutils build-essential gcc g++ bash \
patch gzip bzip2 perl tar cpio python unzip rsync file bc wget libncurses5 libqt4-dev libglib2.0-dev libgtk2.0-dev \
libglade2-dev cvs git mercurial rsync openssh-client subversion asciidoc w3m dblatex graphviz python-matplotlib \
libc6:i386 libssl-dev texinfo liblz4-tool genext2fs
```
搭建环境完成后，编译buildroot，执行如下命令：
```
./build.sh rootfs
```
* Debian

编译 Debian 环境搭建所依赖的软件包安装命令如下:
```
sudo apt-get install repo git-core gitk git-gui gcc-arm-linux-gnueabihf u-boot-tools device-tree-compiler \
gcc-aarch64-linux-gnu mtools parted libudev-dev libusb-1.0-0-dev python-linaro-image-tools linaro-image-tools \
gcc-4.8-multilib-arm-linux-gnueabihf gcc-arm-linux-gnueabihf libssl-dev gcc-aarch64-linux-gnu g+conf autotools-dev \
libsigsegv2 m4 intltool libdrm-dev curl sed make binutils build-essential gcc g++ bash patch gzip bzip2 perl \
tar cpio python unzip rsync file bc wget libncurses5 libqt4-dev libglib2.0-dev libgtk2.0-dev libglade2-dev cvs \
git mercurial rsync openssh-client subversion asciidoc w3m dblatex graphviz python-matplotlib libc6:i386 \
libssl-dev texinfo liblz4-tool genext2fs 
```
搭建环境完成后，编译Debian，按照自身需求，执行如下命令：
```
cd rootfs/

## Usage for 32bit Debian
Building a base debian system by ubuntu-build-service from linaro.

    sudo apt-get install binfmt-support qemu-user-static
    sudo dpkg -i ubuntu-build-service/packages/*
    sudo apt-get install -f
    RELEASE=stretch TARGET=desktop ARCH=armhf ./mk-base-debian.sh

Building the rk-debain rootfs with debug:

    VERSION=debug ARCH=armhf ./mk-rootfs-stretch.sh

Creating the ext4 image(linaro-rootfs.img):

    ./mk-image.sh
------------------------------------------------------------------

## Usage for 64bit Debian
Building a base debian system by ubuntu-build-service from linaro.

    sudo apt-get install binfmt-support qemu-user-static
    sudo dpkg -i ubuntu-build-service/packages/*
    sudo apt-get install -f
    RELEASE=stretch TARGET=desktop ARCH=arm64 ./mk-base-debian.sh

Building the rk-debain rootfs with debug:

    VERSION=debug ARCH=arm64 ./mk-rootfs-stretch-arm64.sh

Creating the ext4 image(linaro-rootfs.img):

    ./mk-image.sh

```
完成上述后，会在rootfs目录下，生成linaro-rootfs.img.修改device/rockchip/.BoardConfig.mk中的根文件系统路径即可，参考配置前编译中的“配置Rootfs”.

* Ubuntu16.04

1、 下载根文件系统：[ubuntu16.04 根文件系统(32位)](http://www.t-firefly.com/doc/download/page/id/51.html#other_192)，放到SDK路径下;

2、 该文件为7z压缩包，解压该文件；
```
7z x ubuntu1604armhf-rootfs.7z
```
3、 完成上述后，得到ubuntu1604armhf-rootfs.img(2.6G),拷贝根文件系统到rootfs目录下；
```
cp ubuntu1604armhf-rootfs.img rootfs/
```
#### 补充说明：
```
./build.sh --help

====USAGE: build.sh modules====
uboot              -build uboot
kernel             -build kernel
rootfs             -build default rootfs, currently build buildroot as default
buildroot          -build buildroot rootfs
yocto              -build yocto rootfs, currently build ros as default
ros                -build ros rootfs
debian             -build debian rootfs
pcba               -build pcba
recovery           -build recovery
all                -build uboot, kernel, rootfs, recovery image
cleanall           -clean uboot, kernel, rootfs, recovery
firmware           -pack all the image we need to boot up system
updateimg          -pack update image
sdbootimg          -pack sdboot image
save               -save images, patches, commands used to debug
default            -build all modules
BoardConfig        -select the corresponding BoardConfig.mk file  
```
`recovery`分区在Ubuntu系统中不会用到，若有需要,可运行如下命令：
```
./build.sh recovery
```
## 打包固件
#### parameter分区表
parameter.txt文件中包含了固件的重要信息，如以rk3288为例：
路径：device/rockchip/rk3288/parameter-ubuntu.txt
```
FIRMWARE_VER: 8.1           固件版本
MACHINE_MODEL:rk3288        固件板型
MACHINE_ID:007
MANUFACTURER:RK3288
MAGIC: 0x5041524B
ATAG: 0x00200800
MACHINE: 3288
CHECK_MASK: 0x80
PWR_HLD: 0,0,A,0,1
TYPE: GPT                   分区类型
CMDLINE: mtdparts=rk29xxnand:0x00002000@0x00004000(uboot),0x00002000@0x00006000(trust),0x00010000@0x0000a000(boot),0x00010000@0x0002a000(backup),-@0x0005a000(rootfs:grow)      
uuid:rootfs=614e0000-0000-4b53-8000-1d28000054a9

```
CMDLINE属性是我们关注的地方，以uboot为例 0x00002000@0x00004000(uboot)中0x00004000为uboot分区的起始位置0x00002000为分区的大小，后面相同,用户可以根据自己需要增减或者修改分区信息，但是请最少保留uboot,trust,boot,rootfs分区，这是机器能正常启动的前提条件。

* 分区介绍：
```
uboot    分区:  uboot编译出来的 uboot.img.
trust    分区:  uboot编译出来的 trust.img
misc     分区:  misc.img开机检测进入recovery模式.(可省略)
boot     分区:  编译出来的 boot.img包含kernel和设备树信息.
recovery 分区:  烧写 recovery.img.(可省略)
backup   分区:  预留,暂时没有用。后续跟 android 一样作为 recovery 的 backup 使用.
oem      分区:  给厂家使用,存放厂家的 app 或数据，只读，代替原来音箱的 data 分区，挂载在/oem 目录.(可省略)
rootfs   分区:  存放 buildroot 或者 debian 编出来的rootfs.img只读.
userdata 分区:  存放app临时生成的文件或者是给最终用户使用。可读写,挂载在/userdata目录下.(可省略)
```
在parameter.txt文件中，仅仅保留了5个不可缺少的分区。

注意：若发现根文件分区大小异常时，执行如下命令：
```
resize2fs /dev/mmcblk2p5

```
#### package-file
package-file文件用于打包统一固件时确定需要的分区镜像和镜像路径，同时它需要与parameter.txt文件保持一致。
路径tools/linux/Linux_Pack_Firmware/rockdev/目录下，以package-file为例：
```
# NAME          Relative path
#
#HWDEF          HWDEF
package-file    package-file
bootloader      Image/MiniLoaderAll.bin
parameter       Image/parameter.txt
trust           Image/trust.img
uboot           Image/uboot.img
boot            Image/boot.img
rootfs:grow     Image/rootfs.img
backup          RESERVED
```
#### 打包
* 整理分区镜像到rockdev/目录下
```
./mkfirmware.sh
```
<font color=#ff0000 size=3>提示</font>：在运行./mkfirmware时，可能会遇到如下报错：
```
error: /home/ljh/proj/linux-sdk/buildroot/output/rockchip_rk3288_recovery/images/recovery.img not found!
```
表示recovery分区没有找到，类似的如oem.img、userdata.img，上文提到，这些属于可省略分区镜像，可以不用理会。

* 整合统一固件
```
./build.sh updateimg
```
注意：每次打包固件前，需要运行mkfirmware.sh脚本更新rockdev/下的分区镜像

## 烧写固件
### 工具下载
* Windows:[AndroidTool_v2.58](http://www.t-firefly.com/doc/download/page/id/51.html#windows_22)
* Linux:[Upgrade_tool_1.34](http://www.t-firefly.com/doc/download/page/id/51.html#linux_22)
### Windows升级
下载 AndroidTool2.58后,解压，运行里面的 AndroidTool.exe（注意，如果是 Windows 7/8,需要按鼠标右键，选择以管
理员身份运行），如下图：
![](img/win_tool_download.png)
 
前提：设备烧写固件或分区镜像时，需处于Loader模式或Maskrom模式，参考[设备模式](http://wiki.t-firefly.com/zh_CN/AIO-3288C/bootmode.html#loader-mo-shi)
#### 烧写统一固件 update.img
**烧写统一固件 update.img 的步骤如下:**  
1. 切换至"升级固件"页。
2. 按"固件"按钮，打开要升级的固件文件。升级工具会显示详细的固件信息
3. 按"升级"按钮开始升级。
4. 如果升级失败，可以尝试先按"擦除Flash"按钮来擦除 Flash，然后再升级。

<font color=#ff0000 size=3>注意：如果你烧写的固件loader版本与原来的机器的不一致，请在升级固件前先执行"擦除Flash"。</font>
![](img/win_tool_upgrade.png)

#### 烧写分区映像
**烧写分区映像时，请使用对应SDK下的FFTools/AndroidTool.rar烧写。步骤如下：**
1. 切换至"下载镜像"页。
2. 勾选需要烧录的分区，可以多选。
3. 确保映像文件的路径正确，需要的话，点路径右边的空白表格单元格来重新选择。
4. 点击"执行"按钮开始升级，升级结束后设备会自动重启。
![](img/win_tool_img.png)

### Linux升级
下载Upgrade_tool1.34.zip后，解压，将upgrade_tool拷贝到/usr/local/bin/目录下,操作如下：
```
unzip Linux_Upgrade_Tool_v1.34.zip
cd Linux_Upgrade_Tool
sudo mv upgrade_tool /usr/local/bin
sudo chown root:root /usr/local/bin/upgrade_tool
```
#### 统一固件烧写
* 使用upgrade_tool工具烧写：
```
sudo upgrade_tool uf update.img
```
* 使用SDK脚本烧写：
```
./rkflash.sh firmware
```

#### 分区镜像烧写
* 使用upgrade_tool工具烧写：
```
sudo upgrade_tool ul $LOADER
sudo upgrade_tool di -p $PARAMETER
sudo upgrade_tool di -uboot $UBOOT
sudo upgrade_tool di -trust $TRUST
sudo upgrade_tool di -b $BOOT
sudo upgrade_tool di -rootfs $ROOTFS
```
* 使用脚本烧写：
```
#全自动烧写
./rkflash.sh

#分区镜像烧写
./rkflash.sh loader
./rkflash.sh parameter
./rkflash.sh uboot
./rkflash.sh trust
./rkflash.sh boot
./rkflash.sh rootfs
```
说明：rkflash.sh该脚本文件的原理便是使用upgrade_tool工具烧写

[《存储映射》]: http://opensource.rock-chips.com/wiki_Partitions#Default_storage_map