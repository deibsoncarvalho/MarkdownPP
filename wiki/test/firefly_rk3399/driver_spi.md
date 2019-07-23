# SPI 使用

SPI是一种高速的，全双工，同步串行通信接口，用于连接微控制器、传感器、存储设备等。
Firefly-RK3399 开发板提供了 SPI1 （单片选）接口，具体位置如下图：
![](img/spi2.jpg)

## SPI工作方式

SPI以主从方式工作，这种模式通常有一个主设备和一个或多个从设备，需要至少4根线，分别是：

```
CS		片选信号
SCLK		时钟信号
MOSI		主设备数据输出、从设备数据输入
MISO		主设备数据输入，从设备数据输出
```

Linux内核用CPOL和CPHA的组合来表示当前SPI的四种工作模式：

```
CPOL＝0，CPHA＝0		SPI_MODE_0
CPOL＝0，CPHA＝1		SPI_MODE_1
CPOL＝1，CPHA＝0		SPI_MODE_2
CPOL＝1，CPHA＝1		SPI_MODE_3
```

CPOL：表示时钟信号的初始电平的状态，０为低电平，１为高电平。  
CPHA：表示在哪个时钟沿采样，０为第一个时钟沿采样，１为第二个时钟沿采样。  
SPI的四种工作模式波形图如下：

![](img/spi1.jpg)

## 驱动编写

下面以 W25Q128FV Flash模块为例简单介绍SPI驱动的编写。
### 硬件连接

Firefly-RK3399 与 W25Q128FV 硬件连接如下表：

![](img/spi3.png)
### 编写Makefile/Kconfig

在kernel/drivers/spi/Kconfig中添加对应的驱动文件配置：
```
config SPI_FIREFLY
       tristate "Firefly SPI demo support "
       default y
        help
          Select this option if your Firefly board needs to run SPI demo.
```
在kernel/drivers/spi/Makefile中添加对应的驱动文件名：
```
obj-$(CONFIG_SPI_FIREFLY)              += spi-firefly-demo.o
```
config中选中所添加的驱动文件，如：
```
  │ Symbol: SPI_FIREFLY [=y] 
  │ Type  : tristate
  │ Prompt: Firefly SPI demo support
  │   Location:
  │     -> Device Drivers
  │       -> SPI support (SPI [=y])
  │   Defined at drivers/spi/Kconfig:704
  │   Depends on: SPI [=y] && SPI_MASTER [=y]
```
### 配置DTS节点

在kernel/arch/arm64/boot/dts/rockchip/rk3399-firefly-demo.dtsi中添加SPI驱动结点描述，如下所示：
```
/* Firefly SPI demo */
&spi1 {
	spi_demo: spi-demo@00{
		status = "okay";
		compatible = "firefly,rk3399-spi";
		reg = <0x00>;
		spi-max-frequency = <48000000>;
		/* rk3399 driver support SPI_CPOL | SPI_CPHA | SPI_CS_HIGH */
		//spi-cpha;		/* SPI mode: CPHA=1 */
		//spi-cpol;   	/* SPI mode: CPOL=1 */
		//spi-cs-high;
	};
};
 
&spidev0 {
	status = "disabled";
};
```

* status:如果要启用SPI，则设为okay，如不启用，设为disable。
* spi-demo@00:由于本例子使用CS0，故此处设为00，如果使用CS1，则设为01。
* compatible:这里的属性必须与驱动中的结构体：of_device_id 中的成员compatible 保持一致。
* reg:此处与spi-demo@00保持一致，本例设为：0x00。
* spi-max-frequency：此处设置spi使用的最高频率。Firefly-RK3399最高支持48000000。
* spi-cpha，spi-cpol：SPI的工作模式在此设置，本例所用的模块SPI工作模式为SPI_MODE_0或者SPI_MODE_3，这里我们选用SPI_MODE_0，如果使用SPI_MODE_3，spi_demo中打开spi-cpha和spi-cpol即可。
* spidev0: 由于spi_demo与spidev0使用一样的硬件资源，需要把spidev0关掉才能打开spi_demo
### 定义SPI驱动

在内核源码目录kernel/drivers/spi/中创建新的驱动文件，如：spi-firefly-demo.c
在定义 SPI 驱动之前，用户首先要定义变量 of_device_id 。 of_device_id 用于在驱动中调用dts文件中定义的设备信息，其定义如下所示：
```
static struct of_device_id firefly_match_table[] = {{ .compatible = "firefly,rk3399-spi",},{},};
```
此处的compatible与DTS文件中的保持一致。

spi_driver定义如下所示：
```
static struct spi_driver firefly_spi_driver = {
	.driver = {
		.name = "firefly-spi",
		.owner = THIS_MODULE,
		.of_match_table = firefly_match_table,},
	.probe = firefly_spi_probe,};
```
### 注册SPI设备

在初始化函数static int __init spidev_init(void)中向内核注册SPI驱动： spi_register_driver(&firefly_spi_driver);

如果内核启动时匹配成功，则SPI核心会配置SPI的参数（mode、speed等），并调用firefly_spi_probe。
### 读写 SPI 数据

firefly_spi_probe中使用了两种接口操作读取W25Q128FV的ID:
firefly_spi_read_w25x_id_0接口直接使用了spi_transfer和spi_message来传送数据。
firefly_spi_read_w25x_id_1接口则使用SPI接口spi_write_then_read来读写数据。

成功后会打印：
```
root@rk3399_firefly_box:/ # dmesg | grep firefly-spi                                                                                   
[    1.006235] firefly-spi spi0.0: Firefly SPI demo program                                                                            
[    1.006246] firefly-spi spi0.0: firefly_spi_probe: setup mode 0, 8 bits/w, 48000000 Hz max                                          
[    1.006298] firefly-spi spi0.0: firefly_spi_read_w25x_id_0: ID = ef 40 18 00 00                                                     
[    1.006361] firefly-spi spi0.0: firefly_spi_read_w25x_id_1: ID = ef 40 18 00 00
```
### 打开SPI demo

spi-firefly-demo默认没有打开，如果需要的话可以使用以下补丁打开demo驱动：
```
--- a/kernel/arch/arm64/boot/dts/rockchip/rk3399-firefly-demo.dtsi
+++ b/kernel/arch/arm64/boot/dts/rockchip/rk3399-firefly-demo.dtsi
@@ -64,7 +64,7 @@ /* Firefly SPI demo */
 &spi1 {spi_demo: spi-demo@00{
 -                status = "disabled";
 +               status = "okay";
                   compatible = "firefly,rk3399-spi";
                   reg = <0x00>;
                   spi-max-frequency = <48000000>;
 @@ -76,6 +76,6 @@
  }; 
  
   &spidev0 {
   -       status = "okay";
   +       status = "disabled";
 };
```
注意：由于spi1_rxd和spi1_txd两个脚可复用为uart4_rx和uart4_tx，所以要留意关闭掉uart4的使用，如下：  
```
kernel/arch/arm64/boot/dts/rockchip/rk3399-firefly-port.dtsi
&uart4 {
        current-speed = <9600>;
        no-loopback-test;
        status = "disabled";
};
```
### 常用SPI接口

下面是常用的 SPI API 定义：
```
void spi_message_init(struct spi_message *m); 
void spi_message_add_tail(struct spi_transfer *t, struct spi_message *m); 
int spi_sync(struct spi_device *spi, struct spi_message *message) ; 
int spi_write(struct spi_device *spi, const void *buf, size_t len); 
int spi_read(struct spi_device *spi, void *buf, size_t len); 
ssize_t spi_w8r8(struct spi_device *spi, u8 cmd); 
ssize_t spi_w8r16(struct spi_device *spi, u8 cmd); 
ssize_t spi_w8r16be(struct spi_device *spi, u8 cmd); 
int spi_write_then_read(struct spi_device *spi, const void *txbuf, unsigned n_tx, void *rxbuf, unsigned n_rx);
```
## 接口使用

Linux提供了一个功能有限的SPI用户接口，如果不需要用到IRQ或者其他内核驱动接口，可以考虑使用接口spidev编写用户层程序控制SPI设备。
在 Firefly-RK3399 开发板中对应的路径为：
/dev/spidev0.0

spidev对应的驱动代码：
kernel/drivers/spi/spidev.c

内核config需要选上SPI_SPIDEV：
```
 │ Symbol: SPI_SPIDEV [=y]
 │ Type  : tristate
 │ Prompt: User mode SPI device driver support 
 │   Location:
 │     -> Device Drivers
 │       -> SPI support (SPI [=y])
 │   Defined at drivers/spi/Kconfig:684
 │   Depends on: SPI [=y] && SPI_MASTER [=y]
```
DTS配置如下：
```
&spi1 {
    status = "okay";
    max-freq = <48000000>;  
    spidev@00 {
        compatible = "linux,spidev";
        reg = <0x00>;
        spi-max-frequency = <48000000>;
    };
};
```
详细使用说明请参考文档 spidev 。
## FAQs
###### Q1: SPI数据传送异常

A1:  确保 SPI 4个引脚的 IOMUX 配置正确， 确认 TX 送数据时，TX 引脚有正常的波形，CLK 频率正确，CS 信号有拉低，mode 与设备匹配。