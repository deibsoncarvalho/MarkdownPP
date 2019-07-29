# 编译 Android 固件

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
$ md5sum /path/to/Firefly-RK3399_Android7.1.2_git_20180126.7z

699cff05bfa39a341e7aae3857cea4a7  Firefly-RK3399_Android7.1.2_git_20180126.7z
```
mkdir -p ~/proj/firefly-rk3399
cd ~/proj/firefly-rk3399
7z x /path/to/Firefly-RK3399_Android7.1.2_git_20180126.7z -r -o./
git reset --hard
```
# 进入SDK根目录
cd ~/proj/firefly-rk3399   
# 如果没有拉取远程仓库,需要先拉取对应bundle仓库
git clone https://gitlab.com/TeeFirefly/rk3399-nougat-bundle.git .bundle
# 更新SDK，并且后续更新不需要再次拉取远程仓库，直接执行以下命令即可
.bundle/update     
# 按照提示已经更新内容到 FETCH_HEAD,同步FETCH_HEAD到firefly-rk3399分支
git rebase FETCH_HEAD    
```
cd ~/proj/firefly-rk3399/
./FFTools/make.sh -k -j8
```
cd ~/proj/firefly-rk3399/
./FFTools/make.sh -u -j8
```
cd ~/proj/firefly-rk3399/
./FFTools/make.sh -a -j8
```
cd ~/proj/firefly-rk3399/
./FFTools/make.sh -j8
```
./FFTools/make.sh -j8
./FFTools/mkupdate/mkupdate.sh
```
./FFTools/make.sh -j8 -d rk3399-firefly-edp -l rk3399_firefly_edp_box-userdebug
./FFTools/mkupdate/mkupdate.sh -l rk3399_firefly_edp_box-userdebug
```
./FFTools/make.sh -j8 -d rk3399-firefly-mipi -l rk3399_firefly_mipi_box-userdebug
./FFTools/mkupdate/mkupdate.sh -l rk3399_firefly_mipi_box-userdebug
```
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 
export PATH=$JAVA_HOME/bin:$PATH 
export CLASSPATH=.:$JAVA_HOME/lib:$JAVA_HOME/lib/tools.jar
```
cd ~/proj/firefly-rk3399/kernel/
make ARCH=arm64 firefly_defconfig
make -j8 ARCH=arm64 rk3399-firefly.img
```
cd ~/proj/firefly-rk3399/u-boot/
make rk3399_box_defconfig
make ARCHV=aarch64 -j8
```
cd ~/proj/firefly-rk3399/
source build/envsetup.sh
lunch rk3399_firefly_box-userdebug
make -j8
./mkimage.sh
```
./FFTools/mkupdate/mkupdate.sh update