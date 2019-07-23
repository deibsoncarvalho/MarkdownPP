# Ubuntu 应用层支持

## 视频硬件编解码支持

Mpp是Rockchip为RK3399提供的一套视频编解码的api, 并且基于mpp,Rockchip提供了一套gstreamer的编解码插件。用户可以根据自己的需求，基于gstreamer来做视频编解码的应用，或者直接调用mpp，来实现硬件的编解码加速。

Firefly 发布的Ubuntu 系统， 都已经提供了完整的gstremaer 和 mpp支持，并且提供了相应的demo，供用户开发参考。

### Gstreamer

*   Ubuntu 16.04 下，gstreamer 1.12 已经安装在/opt/目录下。
*   Ubuntu 18.04下， gstreamer 1.12 已经安装到系统中。

/usr/local/bin/h264dec.sh  测试硬件H264解码。

/usr/local/bin/h264enc.sh  测试硬件H264编码。

用户可以参照这两个脚本，配置自己的gstreamer应用。

### Mpp

*   Ubunut 系统下， mpp 相关dev包都已经安装到系统中。

    /opt/mpp/下分别是mpp 编解码的相关demo 和 源文件。

## OpenGL-ES

RK3399 支持 OpenGL ES1.1/2.0/3.0/3.1。 

Firefly 发布的Ubuntu 系统， 都已经提供了完整的OpenGL-ES支持。运行`glmark2-es2`可以测试openGL-ES支持。 如果要避免屏幕刷新率对测试结果的影响，可以在串口终端上使用以下命令测试。

```shell
# systemctl stop lightdm
# export DISPLAY=:0
# Xorg &
# glmark2-es2 –off-screen
```

在Chromium浏览器中， 在地址栏输入：`chrome://gpu`可以查看chromium下硬件加速的支持。

Note:  

1.  EGL 是用arm 平台上OpenGL针对x window  system的扩展，功能等效于x86下的glx库。

2.  由于Xorg使用的Driver modesettings 默认会加载libglx.so(禁用glx会导致某些通过检测glx环境的应用启动失败)， libglx.so会搜索系统中的dri实现库。但是rk3399 Xorg 2D加速是直接基于DRM实现， 并未实现dri库，所以启动过程中，libglx.so会报告如下的错误 。

    ```
    (EE) AIGLX error: dlopen of /usr/lib/aarch64-linux-gnu/dri/rockchip_dri.so failed
    ```

    这个对系统运行没有任何影响，不需要处理。

3.  基于同样的道理，某些应用启动过程中，也会报告如下错误，不用处理，对应用的运行不会造成影响。

    ```
    libGL error: unable to load driver: rockchip_dri.so
    libGL error: driver pointer missing
    libGL error: failed to load driver: rockchip
    ```

4.  Firefly之前发布的某些版本的Ubuntu软件，默认关闭了加载libglx.so，在某些情况下，运行某些应用程序会出现下述错误：

    `GdkGLExt-WARNING **: Window system doesn't support OpenGL.`

    修正的方法如下：

    删除  `/etc/X11/xorg.conf.d/20-modesetting.conf` 中一下三行配置。

    ```shell
    Section "Module"
         Disable     "glx"
    EndSection
    ```

    

## OpenCL

Firefly发布的Ubuntu系统，已经添加了opencl1.2支持，可以运行系统内置的`clinfo`获取平台opencl相关参数。

```
firefly@firefly:~$ clinfo 
Platform #0
 Name:                                  ARM Platform
 Version:                               OpenCL 1.2 v1.r14p0-01rel0-git(966ed26).f44c85cb3d2ceb87e8be88e7592755c3

 Device #0
   Name:                                Mali-T860
   Type:                                GPU
   Version:                             OpenCL 1.2 v1.r14p0-01rel0-git(966ed26).f44c85cb3d2ceb87e8be88e7592755c3
   Global memory size:                  1 GB 935 MB 460 kB 
   Local memory size:                   32 kB 
   Max work group size:                 256
   Max work item sizes:                 (256, 256, 256)
…
```



## TensorFlow Lite

RK3399 支持神经网络的GPU加速方案LinuxNN， Firefly发布的Ubuntu系统，已经添加了LinuxNN的支持。

在opt/tensorflowbin/下，运行test.sh， 即可测试MobileNet 模型图像分类器的 Demo和MobileNet-SSD 模型的目标检测 Demo

```
firefly@firefly:/opt/tensorflowbin$ ./test.sh 
Loaded model mobilenet_ssd.tflite
resolved reporter
nn version: 1.0.0
findAvailableDevices
filename:libarmnn-driver.so     d_info:40432     d_reclen:40s
[D][ArmnnDriver]: Register Service: armnn (version: 1.0.0)!
first invoked time: 1919.17 ms 
invoked 
average time: 108.4 ms 
validCount: 26
car     @ (546, 501) (661, 586)
car     @ (1, 549) (51, 618)
person  @ (56, 501) (239, 854)
person  @ (332, 530) (368, 627)
person  @ (391, 541) (434, 652)
person  @ (418, 477) (538, 767)
person  @ (456, 487) (602, 764)
car     @ (589, 523) (858, 687)
person  @ (826, 463) (1034, 873)
bicycle @ (698, 644) (1128, 925)
write out.jpg succ!
```



## 屏幕旋转

Firefly发布的Ubuntu系统，如果需要默认对系统的显示方向做旋转，可以在

/etc/default/xrandr中修改对应的显示设备的方向即可。

```shell
firefly@firefly:~$ cat /etc/default/xrandr 
#!/bin/sh

# Rotation can be one of 'normal', 'left', 'right' or 'inverted'.

# xrandr --output HDMI-1 --rotate normal
# xrandr --output LVDS-1 --rotate normal
# xrandr --output EDP-1 --rotate normal
# xrandr --output MIPI-1 --rotate normal
# xrandr --output VGA-1 --rotate normal
# xrandr --output DP-1 --rotate normal
```

对于配有触摸屏的平台，如果需要对触摸屏的方向做旋转，可以在/etc/X11/xorg.conf.d/05-gslX680.conf中修改SwapAxes / InvertX / InvertY三个值。

```shell
firefly@firefly:~$ cat /etc/X11/xorg.conf.d/05-gslX680.conf 
Section "InputClass"
        Identifier "gslX680"
        MatchIsTouchscreen "on"
        MatchProduct  "gslX680"
        Driver "evdev"
        Option "SwapAxes" "off"
       # Invert the respective axis.
        Option "InvertX" "off"
        Option "InvertY" "off"
EndSection
```

