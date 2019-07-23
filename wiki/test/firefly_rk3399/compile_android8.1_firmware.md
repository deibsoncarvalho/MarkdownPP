# 编译 Android8.1 固件

## 准备工作

编译 Android 对机器的配置要求较高：  

* 64 位 CPU
* 16GB 物理内存+交换内存
* 30GB 空闲的磁盘空间用于构建，源码树另外占用大约 25GB

官方推荐 Ubuntu 14.04 操作系统，经测试，Ubuntu 12.04 也可以编译运行成功，只需要满足 [http://source.android.com/source/building.html](http://source.android.com/source/building.html) 里的软硬件配置即可。  
编译环境的初始化可参考 [http://source.android.com/source/initializing.html](http://source.android.com/source/initializing.html) 。

* 安装 OpenJDK 8:

```
sudo apt-get install openjdk-8-jdk
```    

提示：安装 openjdk-8-jdk，会更改 JDK 的默认链接，这时可用： 

```
$ sudo update-alternatives --config java
$ sudo update-alternatives --config javac
```  

来切换 JDK 版本。SDK 在找不到操作系统默认 JDK 的时候会使用内部设定的 JDK 路径，因此，为了让同一台机器可以编译 Android 5.1 及之前的版本，去掉链接更方便：

```
$ sudo /var/lib/dpkg/info/openjdk-8-jdk:amd64.prerm remove   
```    

* Ubuntu 12.04 软件包安装：

```
sudo apt-get install git gnupg flex bison gperf build-essential \
zip curl libc6-dev libncurses5-dev:i386 x11proto-core-dev \
libx11-dev:i386 libreadline6-dev:i386 libgl1-mesa-glx:i386 \
g++-multilib mingw32 tofrodos gcc-multilib ia32-libs \
python-markdown libxml2-utils xsltproc zlib1g-dev:i386 \
lzop libssl1.0.0 libssl-dev
```  
 
* Ubuntu 14.04 软件包安装：

```
sudo apt-get install git-core gnupg flex bison gperf libsdl1.2-dev \
libesd0-dev libwxgtk2.8-dev squashfs-tools build-essential zip curl \
libncurses5-dev zlib1g-dev pngcrush schedtool libxml2 libxml2-utils \
xsltproc lzop libc6-dev schedtool g++-multilib lib32z1-dev lib32ncurses5-dev \
lib32readline-gplv2-dev gcc-multilib libswitch-perl \
libssl1.0.0 libssl-dev   
```  
  
## 下载 Android 8.1 SDK  

**Android SDK 源码包比较大,可以通过如下方式获取Android8.1源码包：**
* [[下载链接]](http://www.t-firefly.com/doc/download/page/id/3.html#other_144)

下载完成后先验证一下 MD5 码：
```
$ md5sum /path/to/Firefly-RK3399_Android8.1_git_SDK_20180901.7z.001
$ md5sum /path/to/Firefly-RK3399_Android8.1_git_SDK_20180901.7z.002

8efed8db2687a395df0c0d2791202cc0  Firefly-RK3399_Android8.1_git_SDK_20180901.7z.001
05b5db991bbb9b763d330fa476f2ed76  Firefly-RK3399_Android8.1_git_SDK_20180901.7z.002
```
确认无误后，就可以解压：
```
cd ~/proj/
7z x ./Firefly-RK3399_Android8.1_git_SDK_20180901.7z.001 -oFirefly-rk3399
cd ./Firefly-rk3399
git reset --hard
```
注意：解压后务必要先更新下远程仓库。
以下为从 gitlab 处更新的方法：
```
git remote add gitlab https://gitlab.com/TeeFirefly/firenow-oreo-rk3399.git
git pull gitlab firefly-rk3399:firefly-rk3399
```
也可以到 [[https://gitlab.com/TeeFirefly/firenow-oreo-rk3399#]](https://gitlab.com/TeeFirefly/firenow-oreo-rk3399#) 在线浏览源码。 

## 使用 Firefly 官方脚本编译
*    单独编译kernel：
```
cd ~/proj/firefly-rk3399/
./FFTools/make.sh -k -j8
```

*    单独编译uboot：
```
cd ~/proj/firefly-rk3399/
./FFTools/make.sh -u -j8
```

*    单独编译android上层：
```
cd ~/proj/firefly-rk3399/
./FFTools/make.sh -a -j8
```
*    同时编译ubooot、kernel、android：
```
cd ~/proj/firefly-rk3399/
./FFTools/make.sh -j8
```
## Firefly-RK3399产品编译方法
* 默认编译HDMI+DP
```
./FFTools/make.sh -j8
./FFTools/mkupdate/mkupdate.sh
```

* EDP7.85编译
```
./FFTools/make.sh -j8 -d rk3399-firefly-edp -l rk3399_firefly_edp_mid-userdebug
./FFTools/mkupdate/mkupdate.sh -l rk3399_firefly_edp_mid-userdebug
```

* MIPI7.85编译
```
./FFTools/make.sh -j8 -d rk3399-firefly-mipi -l rk3399_firefly_mipi_mid-userdebug
./FFTools/mkupdate/mkupdate.sh -l rk3399_firefly_mipi_mid-userdebug
```
## 手动编译
编译前执行如下命令配置环境变量：
```
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 
export PATH=$JAVA_HOME/bin:$PATH 
export CLASSPATH=.:$JAVA_HOME/lib:$JAVA_HOME/lib/tools.jar
```

*    编译kernel：
```
cd ~/proj/firefly-rk3399/kernel/
make ARCH=arm64 firefly_defconfig
make -j8 ARCH=arm64 rk3399-firefly.img
```

*    编译uboot：
```
cd ~/proj/firefly-rk3399/u-boot/
make rk3399_defconfig
make ARCHV=aarch64 -j8
```

* 编译android：
```
cd ~/proj/firefly-rk3399/
source build/envsetup.sh
lunch rk3399_firefly_mid-userdebug
make -j8
./mkimage.sh
```
## 打包成统一固件 update.img

编译完可以用Firefly官方的脚本打包成统一固件，执行如下命令：
```
./FFTools/mkupdate/mkupdate.sh update
```
打包完成后将在rockdev/Image-rk3399_firefly_mid/下生成统一固件：update.img

在 Windows 下打包统一固件 update.img 也很简单，将编译生成的文件拷贝到 AndroidTool 的 rockdev\Image 目录中，然后运行 rockdev 目录下的 mkupdate.bat 批处理文件即可创建 update.img 并存放到 rockdev\Image 目录里。
## 烧写分区映像

编译的时候执行 ./mkimage.sh 会重新打包 boot.img 和 system.img, 并将其它相关的映像文件拷贝到目录 rockdev/Image-rk3399_firefly_mid/ 中。以下列出一般固件用到的映像文件：

*    boot.img ：Android 的初始文件映像，负责初始化并加载 system 分区。
*    kernel.img ：内核映像。
*    misc.img ：misc 分区映像，负责启动模式切换和急救模式的参数传递。
*    parameter.txt ：emmc的分区信息
*    recovery.img ：急救模式映像。
*    resource.img ：资源映像，内含开机图片和内核的设备树信息。
*    system.img ：Android 的 system 分区映像，ext4 文件系统格式。
*    trust.img ：休眠唤醒相关的文件
*    rk3399_loader_v1.12.112.bin ：Loader文件
*    uboot.img ：uboot文件
*    oem.img ：预置媒体资源及数据包
*    vendor.img ：产品标识和驱动

请参照 [如何升级固件](upgrade_firmware.html) 一文来烧写分区映像文件。

如果使用的是 Windows 系统，将上述映像文件拷贝到 AndroidTool （Windows 下的固件升级工具）的 rockdev\Image 目录中，之后参照升级文档烧写分区映像即可，这样的好处是使用默认配置即可，不用修改文件的路径。

update.img 方便固件的发布，供终端用户升级系统使用。一般开发时使用分区映像比较方便。
