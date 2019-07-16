# 编译 Ubuntu 固件( GPT )

为了方便用户的使用与开发，官方提供了Linux开发的整套sdk，本章详细的说明SDK的具体用法。

## 准备工作

### 下载源码
下载repo工具：
```
mkdir linux
cd linux
git clone https://github.com/FireflyTeam/repo.git
```

下载 Linux-SDK: 

* 方法一

初始化repo仓库：
```
mkdir linux-sdk
cd linux-sdk
../repo/repo init --repo-url https://github.com/FireflyTeam/repo.git -u https://github.com/FireflyTeam/manifests.git -b linux-sdk -m rk3399/rk3399_linux_release.xml
```
同步源码:
```
../repo/repo sync -c
```

同步过程中,网络波动会导致下载速度过低中断同步,可以使用下面脚本同步代码:
```
#! /bin/bash

../repo/repo sync -c

while [ $? -ne 0 ] ; 
do  
	../repo/repo sync -c ; 
done

```

* 方法二(国内用户推荐使用)

因为国内用户可能git拉代码会比较慢，所以官方提供了基础得源码包`Linux_SDK.7z`

下载[Linux_SDK.7z](http://www.t-firefly.com/doc/download/page/id/54.html#other_186)

```
1.把压缩包放在上一步下载repo工具的目录下
7z x Linux_SDK.7z

2.更新代码
repo sync -c
```

### Linux_SDK 目录介绍
目录：
```
├── linux_sdk
│   ├── app
│   ├── buildroot buildroot根文件系统的编译目录
│   ├── build.sh -> device/rockchip/common/build.sh 全自动编译脚本
│   ├── device 编译相关配置文件
│   ├── distro debian根文件系统生成目录
│   ├── docs 文档
│   ├── envsetup.sh -> buildroot/build/envsetup.sh
│   ├── external
│   ├── kernel 内核
│   ├── Makefile -> buildroot/build/Makefile
│   ├── mkfirmware.sh -> device/rockchip/common/mkfirmware.sh rockdev链接更新脚本
│   ├── prebuilts
│   ├── rkbin 
│   ├── rkflash.sh -> device/rockchip/common/rkflash.sh 烧写脚本
│   ├── rootfs debian根文件系统编译目录
│   ├── tools 烧写、打包工具
│   └── u-boot u-boot

```
<a id="mkconfig"></a>

### 搭建SDK编译环境
编译buildroot固件:
```
sudo apt-get install repo git-core gitk git-gui gcc-arm-linux-gnueabihf u-boot-tools device-tree-compiler \
gcc-aarch64-linux-gnu mtools parted libudev-dev libusb-1.0-0-dev python-linaro-image-tools \
linaro-image-tools autoconf autotools-dev libsigsegv2 m4 intltool libdrm-dev curl sed make \
binutils build-essential gcc g++ bash patch gzip bzip2 perl tar cpio python unzip rsync file bc wget \
libncurses5 libqt4-dev libglib2.0-dev libgtk2.0-dev libglade2-dev cvs git mercurial rsync openssh-client \
subversion asciidoc w3m dblatex graphviz python-matplotlib libc6:i386 libssl-dev texinfo \
liblz4-tool genext2fs lib32stdc++6
```

编译debian固件:
```
sudo apt-get install repo git-core gitk git-gui gcc-arm-linux-gnueabihf u-boot-tools device-tree-compiler \
gcc-aarch64-linux-gnu mtools parted libudev-dev libusb-1.0-0-dev python-linaro-image-tools \
linaro-image-tools gcc-4.8-multilib-arm-linux-gnueabihf gcc-arm-linux-gnueabihf libssl-dev \
gcc-aarch64-linux-gnu g+conf autotools-dev libsigsegv2 m4 intltool libdrm-dev curl sed make \
binutils build-essential gcc g++ bash patch gzip bzip2 perl tar cpio python unzip rsync file bc wget \
libncurses5 libqt4-dev libglib2.0-dev libgtk2.0-dev libglade2-dev cvs git mercurial rsync openssh-client \
subversion asciidoc w3m dblatex graphviz python-matplotlib libc6:i386 libssl-dev texinfo \
liblz4-tool genext2fs lib32stdc++6
```

ubuntu固件:(根文件系统请使用官方提供的根文件系统镜像）
```
sudo apt-get install repo git-core gitk git-gui gcc-arm-linux-gnueabihf u-boot-tools device-tree-compiler \
gcc-aarch64-linux-gnu mtools parted libudev-dev libusb-1.0-0-dev python-linaro-image-tools \
linaro-image-tools gcc-4.8-multilib-arm-linux-gnueabihf gcc-arm-linux-gnueabihf libssl-dev \
gcc-aarch64-linux-gnu g+conf autotools-dev libsigsegv2 m4 intltool libdrm-dev curl sed make \
binutils build-essential gcc g++ bash patch gzip bzip2 perl tar cpio python unzip rsync file bc wget \
libncurses5 libqt4-dev libglib2.0-dev libgtk2.0-dev libglade2-dev cvs git mercurial rsync openssh-client \
subversion asciidoc w3m dblatex graphviz python-matplotlib libc6:i386 libssl-dev texinfo \
liblz4-tool genext2fs lib32stdc++6
```

## 编译SDK

### 编译前配置
配置文件 firefly-rk3399.mk:
```
./build.sh firefly-rk3399.mk

#文件路径在`device/rockchip/rk3399/firefly-rk3399.mk`
```

如果配置文件生效会连接到`device/rockchip/.BoardConfig.mk`,检查该文件可以验证是否配置成功

**注意**:`firefly-rk3399.mk`为编译生成buildroot固件的配置文件.同时用户也可以通过参考该配置生成新的配置文件来适配自己所需要的固件。

重要配置介绍:(如果需要diy固件，可能需要修改下列配置信息)
```

# Uboot defconfig
export RK_UBOOT_DEFCONFIG=firefly-rk3399   编译uboot配置文件

# Kernel defconfig
export RK_KERNEL_DEFCONFIG=firefly_linux_defconfig   编译kernel配置文件

# Kernel dts
export RK_KERNEL_DTS=rk3399-firefly   编译kernel用到的dts

# parameter for GPT table
export RK_PARAMETER=parameter-ubuntu.txt   分区信息(十分重要)

# packagefile for make update image 
export RK_PACKAGE_FILE=rk3399-ubuntu-package-file   打包配置文件

# rootfs image path
export RK_ROOTFS_IMG=xxxx/xxxx.img   根文件系统镜像路径

```
**<font color=#ff0000 >注意,十分重要！！</font>**

默认配置编译buildroot固件，如果想编译其他固件(如ubuntu固件)请执行一下操作:

*  [下载ubuntu根文件系统镜像](https://pan.baidu.com/s/1DuCzTGARDi7APxyKs9Nl1A#list/path=%2F)

*  把得到的镜像放到sdk的指定目录:

```
#解压
tar -xvf rk3399_ubuntu18.04_LXDE.img.tgz

#sdk根目录下
mkdir ubunturootfs
mv rk3399_ubuntu18.04_LXDE.img ubunturootfs/

#修改firefly-rk3399.mk文件
vim device/rockchip/rk3399/firefly-rk3399.mk

#把RK_ROOTFS_IMG属性改成ubuntu文件系统镜像得路径(也就是rk3399_ubuntu18.04_LXDE.img)
RK_ROOTFS_IMG=ubunturootfs/rk3399_ubuntu18.04_LXDE.img
```
**<font color=#ff0000 >注意</font>**:ubuntu根文件系统镜像存放路径不能错


### 全自动编译
在配置和搭建环境的工作都做好的前提下:
```
./build.sh
```
全自动编译的固件默认会编译一遍`buildroot`根文件系统。生成固件目录`rockdev/`,同时会在IMAGE中备份。

### 部分编译
#### kernel
```
./build.sh kernel
```
#### u-boot
```
./build.sh uboot
```
#### recovery
recovery分区可省略，若有需要： 编译recovery:
```
./build.sh recovery
```
#### rootfs

* buildroot:
```
./build.sh rootfs
```

* debian:
```
cd rootfs/

1:
#Building base debian system by ubuntu-build-service from linaro
sudo apt-get install binfmt-support qemu-user-static live-build
sudo dpkg -i ubuntu-build-service/packages/*
sudo apt-get install -f

2:
#编译 32 位的 debian:
RELEASE=stretch TARGET=desktop ARCH=armhf ./mk-base-debian.sh
#或编译 64 位的 debian:
RELEASE=stretch TARGET=desktop ARCH=arm64 ./mk-base-debian.sh


#上面编译如果遇到如下问题情况:
noexec or nodev issue /usr/share/debootstrap/functions: line 1450: ..../rootfs/ubuntu-build-
service/stretch-desktop-armhf/chroot/test-dev-null: Permission denied E: Cannot install into target
'/home/foxluo/work3/rockchip/rk_linux/rk3399_linux/rootfs/ubuntu-build-service/stretch-
desktop-armhf/chroot' mounted with noexec or nodev
# 解决办法: 
mount -o remount,exec,dev xxx (xxx is the mount place), then rebuild it.

3:
# 编译 32 位的 debian:
VERSION=debug ARCH=armhf ./mk-rootfs-stretch.sh
# 开发阶段推荐使用后面带 debug
# 编译 64 位的 debian:
VERSION=debug ARCH=arm64 ./mk-rootfs-stretch-arm64.sh

4:
./mk-image.sh
mv linaro-rootfs.img ../distro/

5:
#修改firefly-rk3399.mk文件
vim device/rockchip/rk3399/firefly-rk3399.mk

#把RK_ROOTFS_IMG属性改成ubuntu文件系统镜像得路径(也就是linaro-rootfs.img)
RK_ROOTFS_IMG=distro/linaro-rootfs.img

```
* ubuntu18.04,可以通过云盘下载:

[下载链接](https://pan.baidu.com/s/1DuCzTGARDi7APxyKs9Nl1A#list/path=%2F)

把得到的镜像放到sdk的根目录处:

```
#解压
tar -xvf rk3399_ubuntu18.04_LXDE.img.tgz

#sdk根目录下
mkdir ubunturootfs
mv rk3399_ubuntu18.04_LXDE.img ubunturootfs/

#修改firefly-rk3399.mk文件
vim device/rockchip/rk3399/firefly-rk3399.mk

#把RK_ROOTFS_IMG属性改成ubuntu文件系统镜像得路径(也就是rk3399_ubuntu18.04_LXDE.img)
RK_ROOTFS_IMG=ubunturootfs/rk3399_ubuntu18.04_LXDE.img
```
**注意**:ubuntu根文件系统镜像存放路径不能错

运行`./mkfirmware.sh`会自动更新`rockdev/rootfs.img`的链接



## 固件打包
### 同步更新各部分镜像
每次打包固件前先确保`rockdev/`目录下文件链接是否正确:
```
ls -l

├── boot.img -> ~/project/linux_sdk/kernel/boot.img
├── idbloader.img -> ~/project/linux_sdk/u-boot/idbloader.img
├── linaro-rootfs.img
├── MiniLoaderAll.bin -> ~/project/linux_sdk/u-boot/rk3399_loader_v1.14.115.bin
├── misc.img -> ~/project/linux_sdk/device/rockchip/rockimg/wipe_all-misc.img
├── oem.img
├── parameter.txt -> ~/project/linux_sdk/device/rockchip/rk3399/parameter-ubuntu.txt
├── recovery.img -> ~/project/linux_sdk/buildroot/output/rockchip_rk3399_recovery/images/recovery.img
├── rootfs.img -> ~/project/linux_sdk/ubunturootfs/rk3399_ubuntu18.04_LXDE.img
├── trust.img -> ~/project/linux_sdk/u-boot/trust.img
├── uboot.img -> ~/project/linux_sdk/u-boot/uboot.img
└── userdata.img

```
可以运行`./mkfirmware.sh`更新链接
```
./mkfirmware.sh
```
提示：若不是编译全部的分区镜像，在运行./mkfirmware时，会遇到如下类似情况：

```
error: /home/ljh/proj/linux-sdk/buildroot/output/rockchip_rk3399_recovery/images/recovery.img not found!
表示recovery分区没有编译出镜像，其他的情况类似，如oem.img、userdata.img
上文提到，这些属于可省略分区镜像，可以不用理会。
```
### 打包统一固件
**注意**：打包前请确认`tools/linux/Linux_Pack_Firmware/rockdev/package-file`是否正确。打包会根据此文件进行分区打包。此文件链接会在`./build.sh firefly-rk3399.mk` 命令时更新，如果配置不对请返回[配置]一节重新配置一次。

整合统一固件:
```
./build.sh updateimg
```
## 分区介绍

### parameter
`parameter.txt`包含了固件的分区信息十分重要,你可以在`device/rockchip/rk3399`目录下找到一些`parameter.txt`文件,下面以parameter-debian.txt为例子做介绍:
```
FIRMWARE_VER: 8.1                                                                                                                             
MACHINE_MODEL: RK3399
MACHINE_ID: 007 
MANUFACTURER: RK3399
MAGIC: 0x5041524B
ATAG: 0x00200800
MACHINE: 3399
CHECK_MASK: 0x80
PWR_HLD: 0,0,A,0,1
TYPE: GPT 
CMDLINE: mtdparts=rk29xxnand:0x00002000@0x00004000(uboot),0x00002000@0x00006000(trust),0x00002000@0x00008000(misc),0x00010000@0x0000a000(boot),0x00010000@0x0001a000(recovery),0x00010000@0x0002a000(backup),0x00020000@0x0003a000(oem),0x00700000@0x0005a000(rootfs),-@0x0075a000(userdata:grow)
uuid:rootfs=614e0000-0000-4b53-8000-1d28000054a9
```
`CMDLINE`属性是我们关注的地方。以uboot为例 `0x00002000@0x00004000(uboot)`中`0x00004000`为uboot分区的起始位置`0x00002000`为分区的大小。后面的分区规则相同。用户可以根据自己需要增减或者修改分区信息，但是请最少保留uboot,trust,boot,rootfs分区，这是机器能正常启动的前提条件。parameter-ubuntu.txt中使用的就是这样的最简分区方案。

分区介绍:
```
uboot 分区: 烧写 uboot 编译出来的 uboot.img.
trust 分区: 烧写 uboot 编译出来的 trust.img
misc 分区: 烧写 misc.img。开机检测进入recovery模式.（可省略）
boot 分区: 烧写 kernel 编译出来的 boot.img.包含kernel和设备树信息
recovery 分区: 烧写 recovery.img.（可省略）
backup 分区: 预留,暂时没有用。后续跟 android 一样作为 recovery 的 backup 使用.（可省略）
oem 分区: 给厂家使用,存放厂家的 app 或数据。只读。代替原来音箱的 data 分区。挂载在/oem 目录.（可省略）
rootfs 分区: 存放 buildroot 或者 debian 编出来的 rootfs.img,只读.
userdata 分 区 : 存 放 app 临 时 生 成 的 文 件 或 者 是 给 最 终 用 户 使 用 。 可 读 写 , 挂 载 在
/userdata 目录下.（可省略）

```

### package-file
此文件应当与parameter保持一致，用于固件打包。可以在`tools/linux/Linux_Pack_Firmware/rockdev`下找到相关文件。以rk3399-ubuntu-package-file为例介绍:
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
以上是SDK编译后生成的镜像文件。根据`parameter.txt`只打包自己用到的img文件。



## 常见问题

### 如何进入升级模式

操作方法见[《升级固件》](upgrade_firmware.html)

[《升级固件》]:upgrade_firmware.html
[配置]:linux_sdk#mkconfig
[原始固件]:started.html#raw-firmware-format
[RK固件]:started.html#rk-firmware-formate
[分区固件]:started.html#partition-image
[maskrom]:maskrom_mode.html
