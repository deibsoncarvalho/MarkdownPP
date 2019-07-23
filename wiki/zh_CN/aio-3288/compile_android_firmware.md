# 编译 Android 固件

## 准备工作

编译 Android 对机器的配置要求较高：  

* 64 位 CPU
* 16GB 物理内存+交换内存
* 30GB 空闲的磁盘空间用于构建，源码树另外占用大约 25GB

官方推荐 Ubuntu 14.04 操作系统，经测试，Ubuntu 12.04 也可以编译运行成功，只需要满足 [http://source.android.com/source/building.html](http://source.android.com/source/building.html) 里的软硬件配置即可。  
编译环境的初始化可参考 [http://source.android.com/source/initializing.html](http://source.android.com/source/initializing.html) 。

* 安装 OpenJDK 7：  

```
sudo apt-get install openjdk-7-jdk  
```

提示：安装 openjdk-7-jdk，会更改 JDK 的默认链接，这时可用： 

```
$ sudo update-alternatives --config java
$ sudo update-alternatives --config javac
```

来切换 JDK 版本。SDK 在找不到操作系统默认 JDK 的时候会使用内部设定的 JDK 路径，因此，为了让同一台机器可以编译 Android 5.1 及之前的版本，去掉链接更方便：

```
$ sudo /var/lib/dpkg/info/openjdk-7-jdk:amd64.prerm remove   
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
  
## 下载 Android SDK  

**Android SDK 源码包比较大(约6.3G),可以通过如下方式获取源码包：**
* [[下载链接]](http://www.t-firefly.com/doc/download/51.html#other_35)

下载完成后先验证一下 MD5 码：  

```
$ md5sum /path/to/firefly-rk3288_android5.1_git_20180126.tar.gz
dad080373115053de3367c21289562d2  firefly-rk3288_android5.1_git_20180126.tar.gz
```

确认无误后，就可以解压：

```
mkdir -p ~/proj/firefly-rk3288-lollipop
cd ~/proj/firefly-rk3288-lollipop
tar xzf /path/to/firefly-rk3288_android5.1_git_20180126.tar.gz
git reset --hard
git remote add bitbucket https://bitbucket.org/T-Firefly/firenow-lollipop.git
```

以后就可以直接从`bitbucket`处更新

```
git pull bitbucket Firefly-RK3288:Firefly-RK3288
```

也可以到 [https://bitbucket.org/T-Firefly/firenow-lollipop/commits/branch/Firefly-RK3288](https://bitbucket.org/T-Firefly/firenow-lollipop/commits/branch/Firefly-RK3288) 在线浏览源码。  

## 整体编译（uboot、Android、kernel）

```
./FFTools/make.sh -d firefly-rk3288-aio-3288c -j8 -l rk3288_aio_3288c_box-userdebug
./FFTools/mkupdate/mkupdate.sh -l rk3288_aio_3288c_box-userdebug
```

## 手动编译

编译内核：  
```
cd ~/proj/firefly-rk3288-lollipop/kernel
make firefly_defconfig
make firefly-rk3288-aio-3288c.img -j4
```
编译 Android：  
```
cd ~/proj/firefly-rk3288-lollipop
source build.sh
lunch rk3288_aio_3288c_box-userdebug
make -j8
./mkimage.sh
```

默认的目标构建变体(TARGET_BUILD_VARIANT)为 userdebug。常用变体有三种，分别是用户(user)、用户调试(userdebug)和工程模式(eng)，其区别如下：  
- user  
    + 仅安装标签为 user 的模块
    + 设定属性 ro.secure=1，打开安全检查功能
    + 设定属性 ro.debuggable=0，关闭应用调试功能
    + 默认关闭 adb 功能
    + 打开 Proguard 混淆器
    + 打开 DEXPREOPT 预先编译优化
- userdebug
    + 安装标签为 user、debug 的模块
    + 设定属性 ro.secure=1，打开安全检查功能
    + 设定属性 ro.debuggable=1，启用应用调试功能
    + 默认打开 adb 功能
    + 打开 Proguard 混淆器
    + 打开 DEXPREOPT 预先编译优化
- eng
    + 安装标签为 user、debug、eng 的模块
    + 设定属性 ro.secure=0，关闭安全检查功能
    + 设定属性 ro.debuggable=1，启用应用调试功能
    + 设定属性 ro.kernel.android.checkjni=1，启用 JNI 调用检查
    + 默认打开 adb 功能
    + 关闭 Proguard 混淆器
    + 关闭 DEXPREOPT 预先编译优化  

如果目标构建变体为 user，则 adb 无法获取 root 权限。  
要选择目标构建变体，可以在 make 命令行加入参数，例如：  
```
make -j8 PRODUCT-rk3288_aio_3288c_box-user
make -j8 PRODUCT-rk3288_aio_3288c_box-userdebug
make -j8 PRODUCT-rk3288_aio_3288c_box-eng 
```

## 烧写分区映像
上一步骤的`./mkimage.sh`会重新打包`boot.img`和`system.img`, 并将其它相关的映像文件拷贝到目录`rockdev/Image-rk3288_aio_3288c_box/`中。以下列出一般固件用到的映像文件：

* boot.img ：Android 的初始文件映像，负责初始化并加载 system 分区。
* kernel.img ：内核映像。
* misc.img ：misc 分区映像，负责启动模式切换和急救模式的参数传递。
* recovery.img ：急救模式映像。
* resource.img ：资源映像，内含开机图片和内核的设备树信息。
* system.img ：Android 的 system 分区映像，ext4 文件系统格式。

请参照 [如何升级固件](upgrade_firmware.html) 一文来烧写分区映像文件。  
如果使用的是 Windows 系统，将上述映像文件拷贝到 AndroidTool （Windows 下的固件升级工具）的 rockdev\Image 目录中，之后参照升级文档烧写分区映像即可，这样的好处是使用默认配置即可，不用修改文件的路径。    

## 打包成统一固件 update.img

编译完可以使用Firefly的脚本打包成统一固件，执行如下命令：

* ./FFTools/mkupdate/mkupdate.sh -l rk3288_aio_3288c_box-userdebug

打包完成后固件会生成在rockdev/Image-rk3288_aio_3288c_box/ 目录。
在 Windows 下打包统一固件 update.img 很简单，按上一步骤将文件拷贝到 AndroidTool 的`rockdev\Image` 目录中，然后运行 `rockdev` 目录下的 `mkupdate.bat` 批处理文件即可创建 `update.img` 并存放到 `rockdev\Image` 目录里。  
`update.img` 方便固件的发布，供终端用户升级系统使用。一般开发时使用分区映像比较方便。

