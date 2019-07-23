# 烧写SD卡 

## 前言

本文主要介绍了如何将主机上的固件烧写到 SD 卡，需要根据主机操作系统来选择合适的升级方式。***请注意烧写的固件类型：[原始固件]或者 [RK 固件]***

## 准备工作

* AIO-3399J 开发板
* 固件
* 主机
* SD卡
* 良好的双公头 USB 数据线

## Windows

 <a id="Etcher"></a>

* Etcher

* SD Firmware Tool

Etcher是windows、linux、Mac下都可以使用的图形化SD卡烧写工具。下载方式[Etcher 官网](https://etcher.io)

<a id="SD_Firmware_Tool"></a>

[SD Firmware Tool 下载页面](https://pan.baidu.com/s/1migPY1U#list/path=%2FPublic%2FDevBoard%2FROC-RK3328-CC%2FTools%2FSD_Firmware_Tool&parentPath=%2FPublic%2FDevBoard%2FROC-RK3328-CC)去下载 `SD_Firmware_Tool`，并解压。

### 烧写统一固件 

[原始固件]:

使用Etcher进行烧写比较简单

* 选择固件
* 选择设备
* 开始烧写

![](img/Etcher.png)

[RK 固件]:

运行 `sd_firmware_tool.exe`:

![](img/sdfirmwaretool.zh_CN.png)

1. 插入 SD 卡。
2. 从组合框中选择 SD 卡对应的设备。
3. 勾选 "SD启动" 选项。
4. 点击 "选择固件" 按钮，在文件对话框中选择固件。
5. 点击 "开始创建" 按钮。
6. 然后会显示警告对话框，选择 "是" 来确保选择了正确的SD卡设备。
7. 等待操作完成，直到提示成功对话框出现：

![](img/sdfirmwaretool_done.zh_CN.png)

8. 拔出 SD 卡。

## Linux

利用读卡器将 SD 卡接入电脑后，电脑会检测到相应设备

```
ls /dev/sdb    		#情况根据具体设备而定
```

### 准备工具

<a id="dd"></a>
* dd (ubuntu)

* Etcher (android、ubuntu)

linux 下 Etcher 使用方法与 Windows 相同，请参照 Windows 下 [Etcher] 使用方法。

### 烧写统一固件 

[原始固件]:

```
sudo apt-get install pv						                            #安装pv
pv -tpreb /path/to/system.img | sudo dd conv=fsync,notrunc of=/dev/sdb  #烧写进度可视化

or

sudo dd conv=fsync,notrunc /path/to/system.img of=/dev/sdb
```



[原始固件]: started.html#raw-firmware-format
[安装驱动]: upgrade_firmware.html#USB_driver
[RK 固件]: started.html#rk-firmware-format
[分区映像]: started.html#partition-image
[SD Firmware Tool]: upgrade_firmware_sd.html#SD_Firmware_Tool
[Etcher]: upgrade_firmware_sd.html#Etcher
[dd]: upgrade_firmware_sd.html#dd
[AndroidTool]: upgrade_firmware.html#Androidtool
[upgrade_tool]: upgrade_firmware.html#upgrade_and_rkdeveloptool
[rkdeveloptool]: upgrade_firmware.html#upgrade_and_rkdeveloptool
[《Android开发》]: android_compile_android8.html
[《上手指南》]: guidebook.html
[《创建ubuntu根文件系统》]: linux_build_ubuntu.html
[《创建Debian根文件系统》]: linux_build_debian.html
[《存储映射》]: http://opensource.rock-chips.com/wiki_Partitions#Default_storage_map
[《升级固件》]: upgrade_firmware.html
[《烧写sd卡》]: upgrade_firmware_sd.html
[论坛]: http://bbs.t-firefly.com
[脸书]: https://www.facebook.com/TeeFirefly
[Google+]: https://plus.google.com/u/0/communities/115232561394327947761
[油管]: https://www.youtube.com/channel/UCk7odZvUrTG0on8HXnBT7gA
[推特]: https://twitter.com/TeeFirefly
[在线商城]: http://store.t-firefly.com
[RKUSB]: upgrade_firmware_emmc.html#RKUSB_mode
[Maskrom]: upgrade_firmware_emmc.html#Maskrom_mode