# MaskRom模式

***有关启动模式的介绍，请参阅[《启动模式》](bootmode.html)一章***   
## 简介
`MaskRom` 模式是设备变砖的最后一条防线。强行进入 `MaskRom` 涉及硬件操作，有一定风险，因此仅在设备进入不了 `Loader` 模式的情况下，方可尝试 `MaskRom` 模式。   

* 请小心阅读，并谨慎操作！ 

## Firefly-RK3399进入MaskRom

#### 原理：
人为的把Flash的数据脚与地线短接，系统会认为Flash数据出错，从而清除Flash数据。
操作步骤如下：

*  1、找到Firefly-RK3399预留的焊点(TP31, TP32)，在开发板的背面，如下图所示：

![](img/maskrom1.jpg)

* 2、设备断开所有电源。
* 3、拔出 SD 卡。
* 4、用 USB Type-C 线连接好设备和主机。
* 5、用金属镊子接通Firefly-RK3399预留的焊点(TP31, TP32)，并保持。
* 6、设备插入电源。
* 7、稍候片刻，之后松开镊子，设备应该就会进入 MaskRom 模式。  
![](img/maskrom2.jpg)