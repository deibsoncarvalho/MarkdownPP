# FAQs

### 如何调整HDMI输出分辨率？
Firefly-RK3399 的 HDMI 能自动识别显示的分辨率。假如无法读取显示器的 EDID (Extended Display Identification Data, 扩展显示器标识数据) ，HDMI 会默认设置为 1080P 的分辨率。你也可以进入系统设置对 HDMI 分辨率进行手动调整。
 
 ![](img/started3.jpg)
 
### 开机异常并循环重启怎么办？
有可能是电源电流不够，请使用电压为12V，电流为2.5A~3A的电源。

### ubuntu默认的用户名和密码是什么？
用户名 firefly  密码 firefly 

切换超级用户  sudo -s
### Git链接地址？
[https://gitlab.com/TeeFirefly/FireNow-Nougat](https://gitlab.com/TeeFirefly/FireNow-Nougat)

### 哪里有RK3399 芯片技术手册？
RK3399 芯片技术手册链接：[Brief](http://www.t-firefly.com/download/Firefly-RK3399/docs/Chip%20Specifications/Rockchip_RK3399_Datasheet_V0.7_20160219.pdf) [Part1](http://www.t-firefly.com/download/Firefly-RK3399/docs/TRM/Rockchip%20RK3399TRM%20V1.3%20Part1.pdf) [Part2](http://www.t-firefly.com/download/Firefly-RK3399/docs/TRM/Rockchip%20RK3399TRM%20V1.3%20Part2.pdf)

### 怎么烧写MAC地址？
MAC地址可以让用户自己更改，请先进入升级模式（参照升级固件中连接设备的方法），后使用工具 [WNpctool](https://pan.baidu.com/s/1kU727kF#list/path=%2F) 烧写MAC地址。

### Ubuntu系统，如果插入耳机后，没有声音，该如何处理？
Menu->Multimedia->PulseAudio Volume Control->Configuration->选择正在工作的声卡，关闭另一个声卡

### Android下如何让系统抓取LOG？
Settings(设置)->About phone(关于手机)->点击5下Build number(版本号)->Developer options(开发者选项)->Enable logging to save(启用日志保存)
打开功能后，系统的storage根目录下就会生成.LOGSAVE文件夹，里面包括系统logcat和内核kmsg。

### 打开Root权限
Android系统有很多很强大的功能都需要用到root权限，开发者经常在使用的时候遇到权限的问题，
那如何在Firefly平台上开启系统的root权限功能呢？Firefly已在系统添加启动root权限的功能，具体的步骤如下：
1. 在Settgins apk里面找到About device然后点击进去
2. 点击Build number 5次后会提示(you are now a developer)
3. 然后返回上一级点击Developer options选项后，在选项中点击ROOT access就打开root权限功能
![](img/android_root.png)

### 如何强行进入 MaskRom 模式
如果板子进入不了 Loader 模式，此时可以尝试强行进入 MaskRom 模式。操作方法见[《如何进入 MaskRom 模式》](maskrom_mode.html)。

### PCIE
* 开发板上的两个PCIE的区别?
  * 正面是PCIe 1.0, M.2，背面的是USB转的Mini PCIe。SSD、SATA接M.2，LTE/3G接Mini PCIe。

* M2接口类型：
  * B-key

* 如何接SSD：
  * 市面上的SSD基本是M-key，如果要接SSD，需要到[商城](https://store.t-firefly.com/goods.php?id=51)购买B-key转M-key的转接板

* SSD支持NVME吗：
  * 支持，测试过英特尔（Intel）600P系列，三星EVO系列

* 如何接SATA硬盘：
  * 如果要接SATA，需要到[商城](https://store.t-firefly.com/goods.php?id=52)购买PCIE转SATA的转接板


### TYPE-C
* 怎样接显示器？
  * 需要转接头，目前我们这边测试过有转DP和HDMI的转接头：
  * Type-C转DP：[购买参考链接](https://detail.tmall.com/item.htm?id=531442057703&areaId=442000&user_id=1127317597&cat_id=2&is%20_b=1&rn=4eff2fc1aac30e8c67ff74ef5fe76b56)
  * Type-C转HDMI: [购买参考链接](https://item.taobao.com/item.htm?spm=a1z0d.6639537.1997196601.291.150IpW&id=540645282055&qq-pf-to=pcqq.temporaryc2c)
  * 类似的转VGA和DVI也可以，我们没有买过类似的转接头，客户可以自行验证

* 显示的最大分辨率
  * 默认最大为2K，如果需要4K，需要修改软件

* 显示linux下可以吗
  * 目前只有Android支持，linux驱动原厂还在调试中

* 可以跟板载的HDMI同时显示吗
  * 可以同时显示

* 支持OTG（UFP/DFP）吗
  * 支持，需要购买3.0的转接线,购买[参考链接](https://detail.tmall.com/item.htm?spm=a220o.1000855.w5003-14913680624.1.W2eSKK&id=528676463455&scene=taobao_shop&skuId=3173247769269)

### BT(蓝牙)
* 开发板支持蓝牙耳机吗？
  * 支持

### LTE/4G
* 目前支持的型号：
  * EC20

### Camera
* 支持双摄像头吗？
  * 支持，目前我们调试验证过的有OV13850

* 支持USB摄像头吗？
  * 支持

* 最多可以支持多少个USB摄像头
  * 理论上板子上的USB口都支持接摄像头，但考虑到一个hub上只能挂一个YUV和编码的限制，两个是没有问题

* 支持两个MIPI摄像头，一个DVP摄像头同时用吗？
  * 不支持，由于软件架构问题，目前只支持最多两个同时用

### 风扇
* 支持速度控制吗？
  * 目前的硬件不支持，只支持检测运行状态

### RTC
* 开发板上电后时间不同步
  * 检查一下RTC电池是否正确接入。

* 支持定时开机吗
  * 支持，详细请看[wiki](http://wiki.t-firefly.com/zh_CN/Firefly-RK3399/driver_rtc.html)
