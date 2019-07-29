# 入手指南

## 配件

Firefly-RK3399 的标准套装包含以下配件：

* Firefly-RK3399 主板一块
* 12V-2A 电源适配器一个

另外可以选购的配件有：

* Firefly 串口模块

另外，在使用过程中，你可能需要以下配件：

*    显示设备
     * 带 HDMI 接口的显示器或电视，及 HDMI 连接线
*    网络
     *   100M/1000M 以太网线缆，及有线路由器
     *   WiFi 路由器
*    输入设备
     *   USB 无线/有线的鼠标/键盘
     *   红外遥控器(需要接上红外接收器)
*    升级固件，调试
     *   Type-C 数据线
     *   串口转 USB 适配器

*    发货清单参考

![](img/Firefly-RK3399/started_components.jpg)

* 安装方法

![](img/Firefly-RK3399/started_install.jpg)

Firefly-RK3399_支持从以下存储设备启动：

* SD 卡
* eMMC

我们需要将系统固件烧写到 SD 卡或 eMMC 里，这样开发板上电后才能正常启动进入操作系统。

 <a id="firmware-format"></a>

## 固件格式

固件有两种格式：

- 原始固件(raw firmware)
- RK 固件(Rockchip firmware)

<a id="raw-firmware-format"></a>

[原始固件]，是一种能以逐位复制的方式烧写到存储设备的固件，是存储设备的原始映像。原始固件一般烧写到 SD 卡中，但也可以烧写到 eMMC 中。

<a id="rk-firmware-format"></a>

[RK 固件]，是以 Rockchip 专有格式打包的固件，使用 Rockchip 提供的 upgrade_tool (Linux) 或 AndroidTool (Windows) 工具烧写到 eMMC 闪存中。RK 固件是 Rockchip 的传统固件打包格式，常用于 Android 设备上。另外，RK 固件也可以使用 SD Firmware Tool 工具烧写到 SD 卡中。

<a id="partition-image"></a>

[分区映像]，是分区的映像数据，用于存储设备对应分区的烧写。例如，编译 Android SDK 会构建出 `boot.img`、`kernel.img` 和 `system.img` 等分区映像文件，`kernel.img` 会被写到 eMMC 或 SD 卡的 `kernel` 分区。

## 下载和烧写固件

以下是支持的系统列表：

* Ubuntu 18.04
* Ubuntu 16.04
* Android 8.1
* Android 7.1
* Debian 9

根据所使用的操作系统来选择合适的工具去烧写固件：

- 烧写 SD 卡
  + 图形界面烧写工具：
	* [Etcher] (windows/linux/Mac)
  + 命令行烧写工具
	* [dd] (Linux)
- 烧写 eMMC
  + 图形界面烧写工具：
	* [AndroidTool] (Windows)
  + 命令行烧写工具：
	* [upgrade_tool] (Linux)

## 开机

确认主板配件连接无误后，将电源适配器插入带电的插座上，电源线接口插入开发板，开发板第一次加电会自动开机。 在系统选择关机后，维持开发板供电，此时 Firefly-RK3399 开机方式如下：

*    长按电源键三秒
*    按红外遥控器上的开机按钮

开机时，蓝色的电源指示灯会亮起。如果板子接了 HDMI 显示器，可以看到 Firefly 官方 logo.

[RK 固件]:started.html#rk-firmware-format
[原始固件]:started.html#raw-firmware-format
[分区映像]:started.html#partition-image
[固件类型]:started.html#firmware-format
[Etcher]:upgrade_firmware_sd.html#Etcher
[dd]:upgrade_firmware_sd.html#dd
[AndroidTool]:upgrade_firmware.html#Androidtool
[upgrade_tool]:upgrade_firmware.html#upgrade_and_upgrade_tool