# 驱动开发

## ADC 使用

### 简介

AIO-3399PRO-JD4 开发板上的 AD 接口有两种，分别为：温度传感器 (Temperature Sensor)、逐次逼近ADC (Successive Approximation Register)。其中：

* TS-ADC(Temperature Sensor)：支持两通道，时钟频率必须低于800KHZ

* SAR-ADC(Successive Approximation Register)：支持六通道单端10位的SAR-ADC，时钟频率必须小于13MHZ。

内核采用工业 I/O 子系统来控制 ADC，该子系统主要为 AD 转换或者 DA 转换的传感器设计。 

下面以SAR-ADC使用ADC风扇为例子，介绍 ADC 的基本配置方法。
### DTS配置
#### 配置DTS节点

AIO-3399PRO-JD4 SAR-ADC 的 DTS 节点在 kernel/arch/arm64/boot/dts/rockchip/rk3399.dtsi 文件中定义，如下所示：
```
saradc: saradc@ff100000 {
         compatible = "rockchip,rk3399-saradc";
         reg = <0x0 0xff100000 0x0 0x100>;
         interrupts = <GIC_SPI 62 IRQ_TYPE_LEVEL_HIGH 0>;
         #io-channel-cells = <1>;
         clocks = <&cru SCLK_SARADC>, <&cru PCLK_SARADC>;
         clock-names = "saradc", "apb_pclk";
         resets = <&cru SRST_P_SARADC>;
         reset-names = "saradc-apb";
};
```
用户首先需在DTS文件中添加ADC的资源描述：
```
kernel/arch/arm64/boot/dts/rockchip/rk3399-firefly-demo.dtsi :
adc_demo: adc_demo{
    status = "disabled";
    compatible = "firefly,rk3399-adc";
    io-channels = <&saradc 3>;
};
```

这里申请的是SARADC通道3，在 AIO-3399PRO-JD4 中是不提供给客户外部使用的，而且也没有风扇接口，这里只是提供一个参考，
客户可自行参考这个例子 运用SARADC通道0 去做自己的一些开发。

#### 在驱动文件中匹配 DTS 节点

用户驱动可参考Firefly adc demo :kernel/drivers/adc/adc-firefly-demo.c，这是一个侦测AIO-3399PROJD4风扇状态的驱动。 首先在驱动文件中定义 of_device_id 结构体数组：
```
static const struct of_device_id firefly_adc_match[] = { 
    { .compatible = "firefly,rk3399-adc" },
    {},
};
```
然后将该结构体数组填充到要使用 ADC 的 platform_driver 中：
```
static struct platform_driver firefly_adc_driver = { 
    .probe      = firefly_adc_probe,
    .remove     = firefly_adc_remove,
    .driver     = { 
        .name   = "firefly_adc",
        .owner  = THIS_MODULE,
        .of_match_table = firefly_adc_match,
        },  
};
```
接着在firefly_adc_probe中对DTS所添加的资源进行解析：
```
static int firefly_adc_probe(struct platform_device *pdev)
{
    printk("firefly_adc_probe!\n");
    chan = iio_channel_get(&(pdev->dev), NULL);
    if (IS_ERR(chan)){
        chan = NULL;
        printk("%s() have not set adc chan\n", __FUNCTION__);
        return -1;
    }
    fan_insert = false;
    if (chan) {
        INIT_DELAYED_WORK(&adc_poll_work, firefly_demo_adc_poll);
        schedule_delayed_work(&adc_poll_work,1000);
    }
    return 0;
}
```
### 驱动说明
#### 获取 AD 通道
```
struct iio_channel *chan; //定义 IIO 通道结构体
chan = iio_channel_get(&pdev->dev, NULL); //获取 IIO 通道结构体
```
注：iio_channel_get 通过 probe 函数传进来的参数 pdev 获取 IIO 通道结构体，probe 函数如下：
```
static int XXX_probe(struct platform_device *pdev);
```
#### 读取 AD 采集到的原始数据
```
int val,ret;
ret = iio_read_channel_raw(chan, &val);
```
调用 iio_read_channel_raw 函数读取 AD 采集的原始数据并存入 val 中。
### 计算采集到的电压

使用标准电压将 AD 转换的值转换为用户所需要的电压值。其计算公式如下：
```
Vref / (2^n-1) = Vresult / raw
```
注：

* Vref 为标准电压

* n 为 AD 转换的位数

* Vresult 为用户所需要的采集电压

* raw 为 AD 采集的原始数据

例如，标准电压为 1.8V，AD 采集位数为 10 位，AD 采集到的原始数据为 568，则：
```
Vresult = (1800mv * 568) / 1023;
```
### 接口说明
```
struct iio_channel *iio_channel_get(struct device *dev, const char *consumer_channel);
```

- 功能：获取 iio 通道描述
- 参数：
     + dev: 使用该通道的设备描述指针
     + consumer_channel: 该设备所使用的 IIO 通道描述指针

```
void iio_channel_release(struct iio_channel *chan);
```

- 功能：释放 iio_channel_get 函数获取到的通道
- 参数：
     + chan：要被释放的通道描述指针

```
int iio_read_channel_raw(struct iio_channel *chan, int *val);
```

- 功能：读取 chan 通道 AD 采集的原始数据。
- 参数：
     + chan：要读取的采集通道指针
     + val：存放读取结果的指针

### 调试方法
#### Demo程序使用

在kernel/arch/arm64/boot/dts/rockchip/rk3399-firefly-demo.dtsi中使能adc_demo，将"disabled" 改为 "okay":
```
adc_demo: adc_demo{
    status = "okay";
    compatible = "firefly,rk3399-adc";
    io-channels = <&saradc 3>;
};
```
编译内核，烧录内核到AIO-3399PROJD4 开发板上，然后插拔风扇时，会打印内核log信息如下：
```
[   85.158104] Fan insert! raw= 135 Voltage= 237mV
[   88.422124] Fan out! raw= 709 Voltage=1247mV
```
#### 获取所有ADC值

有个便捷的方法可以查询到每个SARADC的值：
```
cat /sys/bus/iio/devices/iio\:device0/in_voltage*_raw
```
### FAQs
#### 为何按上面的步骤申请SARADC，会出现申请报错的情况？
驱动需要获取ADC通道来使用时，需要对驱动的加载时间进行控制，必须要在saradc初始化之后。saradc是使用module_platform_driver()进行平台设备驱动注册，最终调用的是module_init()。所以用户的驱动加载函数只需使用比module_init()优先级低的，例如：late_initcall()，就能保证驱动的加载的时间比saradc初始化时间晚，可避免出错。



## GPIO 使用

### 简介

GPIO, 全称 General-Purpose Input/Output（通用输入输出），是一种软件运行期间能够动态配置和控制的通用引脚。 RK3399有5组GPIO bank：GPIO0~GPIO4，每组又以 A0~A7, B0~B7, C0~C7, D0~D7 作为编号区分（不是所有 bank 都有全部编号，例如 GPIO4 就只有 C0~C7, D0~D2)。 所有的GPIO在上电后的初始状态都是输入模式，可以通过软件设为上拉或下拉，也可以设置为中断脚，驱动强度都是可编程的。 每个 GPIO 口除了通用输入输出功能外，还可能有其它复用功能，例如 GPIO2_A2，可以利用成以下功能：

* GPIO2_A2
* CIF_D2

每个 GPIO 口的驱动电流、上下拉和重置后的初始状态都不尽相同，详细情况请参考《RK3399 规格书》中的 "Chapter 10 GPIO" 一章。 RK3399 的 GPIO 驱动是在以下 pinctrl 文件中实现的：
```
kernel/drivers/pinctrl/pinctrl-rockchip.c
```
其核心是填充 GPIO bank 的方法和参数，并调用 gpiochip_add 注册到内核中。

本文以TP_RST(GPIO0_B4)和LCD_RST(GPIO4_D5)这两个通用GPIO口为例写了一份简单操作GPIO口的驱动，在SDK的路径为：
```
kernel/drivers/gpio/gpio-firefly.c
```
以下就以该驱动为例介绍GPIO的操作。
### 输入输出
首先在DTS文件中增加驱动的资源描述：
```
kernel/arch/arm64/boot/dts/rockchip/rk3399-firefly-demo.dtsi
gpio_demo: gpio_demo {
    status = "okay";
    compatible = "firefly,rk3399-gpio";
    firefly-gpio = <&gpio0 12 GPIO_ACTIVE_HIGH>;          /* GPIO0_B4 */
    firefly-irq-gpio = <&gpio4 29 IRQ_TYPE_EDGE_RISING>;  /* GPIO4_D5 */               
};
```
这里定义了一个脚作为一般的输出输入口：
```
firefly-gpio GPIO0_B4
```
AIO-3399PRO-JD4 的dts对引脚的描述与Firefly-RK3288有所区别，GPIO0_B4被描述为：<&gpio0 12 GPIO_ACTIVE_HIGH>，这里的12来源于：8+4=12，其中8是因为GPIO0_B4是属于GPIO0的B组，如果是A组的话则为0，如果是C组则为16，如果是D组则为24，以此递推，而4是因为B4后面的4。
GPIO_ACTIVE_HIGH表示高电平有效，如果想要低电平有效，可以改为：GPIO_ACTIVE_LOW，这个属性将被驱动所读取。

然后在probe函数中对DTS所添加的资源进行解析，代码如下：
```
static int firefly_gpio_probe(struct platform_device *pdev)
{   
    int ret; int gpio; enum of_gpio_flags flag; 
    struct firefly_gpio_info *gpio_info; 
    struct device_node *firefly_gpio_node = pdev->dev.of_node; 

    printk("Firefly GPIO Test Program Probe\n"); 
    gpio_info = devm_kzalloc(&pdev->dev,sizeof(struct firefly_gpio_info *), GFP_KERNEL); 
    if (!gpio_info) { 
        return -ENOMEM; 
    } 
    gpio = of_get_named_gpio_flags(firefly_gpio_node, "firefly-gpio", 0, &flag); 
    if (!gpio_is_valid(gpio)) { 
        printk("firefly-gpio: %d is invalid\n", gpio); return -ENODEV; 
    } 
    if (gpio_request(gpio, "firefly-gpio")) { 
        printk("gpio %d request failed!\n", gpio); 
        gpio_free(gpio); 
        return -ENODEV; 
    } 
    gpio_info->firefly_gpio = gpio; 
    gpio_info->gpio_enable_value = (flag == OF_GPIO_ACTIVE_LOW) ? 0:1; 
    gpio_direction_output(gpio_info->firefly_gpio, gpio_info->gpio_enable_value); 
    printk("Firefly gpio putout\n"); 
    ...... 
}
```
of_get_named_gpio_flags 从设备树中读取 firefly-gpio 和 firefly-irq-gpio 的 GPIO 配置编号和标志，gpio_is_valid 判断该 GPIO 编号是否有效，gpio_request 则申请占用该 GPIO。如果初始化过程出错，需要调用 gpio_free 来释放之前申请过且成功的 GPIO 。 在驱动中调用 gpio_direction_output 就可以设置输出高还是低电平，这里默认输出从DTS获取得到的有效电平GPIO_ACTIVE_HIGH，即为高电平，如果驱动正常工作，可以用万用表测得对应的引脚应该为高电平。 实际中如果要读出 GPIO，需要先设置成输入模式，然后再读取值：
```
int val;
gpio_direction_input(your_gpio);
val = gpio_get_value(your_gpio);
```
下面是常用的 GPIO API 定义：
```
#include <linux/gpio.h>
#include <linux/of_gpio.h>  

enum of_gpio_flags {
     OF_GPIO_ACTIVE_LOW = 0x1,
};  
int of_get_named_gpio_flags(struct device_node *np, const char *propname,   
int index, enum of_gpio_flags *flags);  
int gpio_is_valid(int gpio);  
int gpio_request(unsigned gpio, const char *label);  
void gpio_free(unsigned gpio);  
int gpio_direction_input(int gpio);  
int gpio_direction_output(int gpio, int v);
```
### 中断
在Firefly的例子程序中还包含了一个中断引脚，GPIO口的中断使用与GPIO的输入输出类似，首先在DTS文件中增加驱动的资源描述：
```
kernel/arch/arm64/boot/dts/rockchip/rk3399-firefly-port.dtsi
gpio {
    compatible = "firefly-gpio";
    firefly-irq-gpio = <&gpio4 29 IRQ_TYPE_EDGE_RISING>;  /* GPIO4_D5 */
};
```
IRQ_TYPE_EDGE_RISING表示中断由上升沿触发，当该引脚接收到上升沿信号时可以触发中断函数。 这里还可以配置成如下：
```
IRQ_TYPE_NONE         //默认值，无定义中断触发类型
IRQ_TYPE_EDGE_RISING  //上升沿触发                                                                                                                                  
IRQ_TYPE_EDGE_FALLING //下降沿触发
IRQ_TYPE_EDGE_BOTH    //上升沿和下降沿都触发
IRQ_TYPE_LEVEL_HIGH   //高电平触发
IRQ_TYPE_LEVEL_LOW    //低电平触发
```
然后在probe函数中对DTS所添加的资源进行解析，再做中断的注册申请，代码如下：
```
static int firefly_gpio_probe(struct platform_device *pdev)
{   
    int ret; int gpio; enum of_gpio_flags flag; 
    struct firefly_gpio_info *gpio_info; 
    struct device_node *firefly_gpio_node = pdev->dev.of_node; 
    ......     
    gpio_info->firefly_irq_gpio = gpio; 
    gpio_info->firefly_irq_mode = flag; 
    gpio_info->firefly_irq = gpio_to_irq(gpio_info->firefly_irq_gpio); 
    if (gpio_info->firefly_irq) { 
        if (gpio_request(gpio, "firefly-irq-gpio")) { 
           printk("gpio %d request failed!\n", gpio); gpio_free(gpio); return IRQ_NONE; 
        } 
        ret = request_irq(gpio_info->firefly_irq, firefly_gpio_irq, flag, "firefly-gpio", gpio_info); 
        if (ret != 0) free_irq(gpio_info->firefly_irq, gpio_info); 
            dev_err(&pdev->dev, "Failed to request IRQ: %d\n", ret); 
    } 
    return 0;
}
static irqreturn_t firefly_gpio_irq(int irq, void *dev_id) //中断函数
{ 
    printk("Enter firefly gpio irq test program!\n"); return IRQ_HANDLED;
}
```
调用gpio_to_irq把GPIO的PIN值转换为相应的IRQ值，调用gpio_request申请占用该IO口，调用request_irq申请中断，如果失败要调用free_irq释放，该函数中gpio_info-firefly_irq是要申请的硬件中断号，firefly_gpio_irq是中断函数，gpio_info->firefly_irq_mode是中断处理的属性，"firefly-gpio"是设备驱动程序名称，gpio_info是该设备的device结构，在注册共享中断时会用到。
### 复用
如何定义 GPIO 有哪些功能可以复用，在运行时又如何切换功能呢？以 I2C4 为例作简单的介绍。

查规格表可知，I2C4_SDA 与 I2C4_SCL 的功能定义如下：
```
Pad# 	                func0 	        func1
I2C4_SDA/GPIO1_B3 	gpio1b3 	i2c4_sda
I2C4_SCL/GPIO1_B4 	gpio1b4 	i2c4_scl
```
在 kernel/arch/arm64/boot/dts/rockchip/rk3399.dtsi 里有：
```
i2c4: i2c@ff3d0000 { 
    compatible = "rockchip,rk3399-i2c"; 
    reg = <0x0 0xff3d0000 0x0 0x1000>; 
    clocks = <&pmucru SCLK_I2C4_PMU>, <&pmucru 	PCLK_I2C4_PMU>; 
    clock-names = "i2c", "pclk"; 
    interrupts = <GIC_SPI 56 IRQ_TYPE_LEVEL_HIGH 0>; 
    pinctrl-names = "default", "gpio"; 
    pinctrl-0 = <&i2c4_xfer>; 
    pinctrl-1 = <&i2c4_gpio>;   //此处源码未添加 
    #address-cells = <1>;  
    #size-cells = <0>;  
    status = "disabled"; 
};
```
此处，跟复用控制相关的是 pinctrl- 开头的属性：

* pinctrl-names 定义了状态名称列表： default (i2c 功能) 和 gpio 两种状态。

* pinctrl-0 定义了状态 0 (即 default）时需要设置的 pinctrl: &i2c4_xfer

* pinctrl-1 定义了状态 1 (即 gpio)时需要设置的 pinctrl: &i2c4_gpio

这些 pinctrl 在kernel/arch/arm64/boot/dts/rockchip/rk3399.dtsi中这样定义：
```
pinctrl: pinctrl { 
    compatible = "rockchip,rk3399-pinctrl"; 
    rockchip,grf = <&grf>; 
    rockchip,pmu = <&pmugrf>; 
    #address-cells = <0x2>; 
    #size-cells = <0x2>; 
    ranges; 
    i2c4 {
    i2c4_xfer: i2c4-xfer { 
        rockchip,pins = <1 12 RK_FUNC_1 &pcfg_pull_none>, <1 11 RK_FUNC_1 &pcfg_pull_none>;
    };
    i2c4_gpio: i2c4-gpio { 
        rockchip,pins = <1 12 RK_FUNC_GPIO &pcfg_pull_none>, <1 11 RK_FUNC_GPIO &pcfg_pull_none>;
    };          
};
```
RK_FUNC_1,RK_FUNC_GPIO 的定义在 kernel/include/dt-bindings/pinctrl/rk.h 中：
```
 #define RK_FUNC_GPIO    0
 #define RK_FUNC_1   1
 #define RK_FUNC_2   2
 #define RK_FUNC_3   3
 #define RK_FUNC_4   4
 #define RK_FUNC_5   5                         
 #define RK_FUNC_6   6
 #define RK_FUNC_7   7
```
另外，像"1 11"，"1 12"这样的值是有编码规则的，编码方式与上一小节"输入输出"描述的一样，"1 11"代表GPIO1_B3，"1 12"代表GPIO1_B4。

在复用时，如果选择了 "default" （即 i2c 功能),系统会应用 i2c4_xfer 这个 pinctrl，最终将 GPIO1_B3 和 GPIO1_B4 两个针脚切换成对应的 i2c 功能；而如果选择了 "gpio" ，系统会应用 i2c4_gpio 这个 pinctrl，将 GPIO1_B3 和 GPIO1_B4 两个针脚还原为 GPIO 功能。

我们看看 i2c 的驱动程序 kernel/drivers/i2c/busses/i2c-rockchip.c 是如何切换复用功能的：
```
static int rockchip_i2c_probe(struct platform_device *pdev)
{   
    struct rockchip_i2c *i2c = NULL; struct resource *res; 
    struct device_node *np = pdev->dev.of_node; int ret;// 
    ...
    i2c->sda_gpio = of_get_gpio(np, 0);
    if (!gpio_is_valid(i2c->sda_gpio)) {
        dev_err(&pdev->dev, "sda gpio is invalid\n");
        return -EINVAL;
    }
    ret = devm_gpio_request(&pdev->dev, i2c->sda_gpio, dev_name(&i2c->adap.dev));
    if (ret) {
        dev_err(&pdev->dev, "failed to request sda gpio\n");
        return ret;
    }
    i2c->scl_gpio = of_get_gpio(np, 1);
    if (!gpio_is_valid(i2c->scl_gpio)) {
        dev_err(&pdev->dev, "scl gpio is invalid\n");
        return -EINVAL;
    }
    ret = devm_gpio_request(&pdev->dev, i2c->scl_gpio, dev_name(&i2c->adap.dev));
    if (ret) {
        dev_err(&pdev->dev, "failed to request scl gpio\n");
        return ret;
    }
    i2c->gpio_state = pinctrl_lookup_state(i2c->dev->pins->p, "gpio");
    if (IS_ERR(i2c->gpio_state)) {
        dev_err(&pdev->dev, "no gpio pinctrl state\n");
        return PTR_ERR(i2c->gpio_state);
    }
    pinctrl_select_state(i2c->dev->pins->p, i2c->gpio_state);
    gpio_direction_input(i2c->sda_gpio);
    gpio_direction_input(i2c->scl_gpio);
    pinctrl_select_state(i2c->dev->pins->p, i2c->dev->pins->default_state);
    // ...
}
```
首先是调用 of_get_gpio 取出设备树中 i2c4 结点的 gpios 属于所定义的两个 gpio:
```
gpios = <&gpio1 GPIO_B3 GPIO_ACTIVE_LOW>, <&gpio1 GPIO_B4 GPIO_ACTIVE_LOW>;
```
然后是调用 devm_gpio_request 来申请 gpio，接着是调用 pinctrl_lookup_state 来查找 “gpio” 状态，而默认状态 "default" 已经由框架保存到 i2c->dev-pins->default_state 中了。

最后调用 pinctrl_select_state 来选择是 "default" 还是 "gpio" 功能。

下面是常用的复用 API 定义：
```
#include <linux/pinctrl/consumer.h> 
struct device {
    //...
    #ifdef CONFIG_PINCTRL
    struct dev_pin_info	*pins;
    #endif
    //...
}; 
struct dev_pin_info {
    struct pinctrl *p;
    struct pinctrl_state *default_state;
    #ifdef CONFIG_PM
    struct pinctrl_state *sleep_state;
    struct pinctrl_state *idle_state;
    #endif
}; 
struct pinctrl_state * pinctrl_lookup_state(struct pinctrl *p, const char *name); 
int pinctrl_select_state(struct pinctrl *p, struct pinctrl_state *s);
```
### IO-Domain

在复杂的片上系统（SOC）中，设计者一般会将系统的供电分为多个独立的block，这称作电源域（Power Domain），这样做有很多好处，例如：

* 在IO-Domain的DTS节点统一配置电压域，不需要每个驱动都去配置一次，便于管理；

* 依照的是Upstream的做法，以后如果需要Upstream比较方便；

* IO-Domain的驱动支持运行过程中动态调整电压域，例如PMIC的某个Regulator可以1.8v和3.3v的动态切换，一旦Regulator电压发生改变，会通知IO-Domain驱动去重新设置电压域。

AIO-3399ProJD4原理图上的 Power Domain Map 表以及配置如下表所示：

![](img/gpio2.png)

通过RK3399Pro SDK的原理图可以看到bt656-supply 的电压域连接的是vcc18_dvp, vcc_io是从PMIC RK808的VLDO1出来的；
在DTS里面可以找到vcc1v8_dvp， 将bt656-supply = <&vcc18_dvp>。
其他路的配置也类似，需要注意的是如果这里是其他PMIC，所用的Regulator也不一样,具体以实际电路情况为标准。

### 调试方法
#### IO指令

GPIO调试有一个很好用的工具，那就是IO指令，Android系统默认已经内置了IO指令，使用IO指令可以实时读取或写入每个IO口的状态，这里简单介绍IO指令的使用。 首先查看 io 指令的帮助：
```
#io --help
Unknown option: ?
Raw memory i/o utility - $Revision: 1.5 $

io -v -1|2|4 -r|w [-l <len>] [-f <file>] <addr> [<value>]

   -v         Verbose, asks for confirmation
   -1|2|4     Sets memory access size in bytes (default byte)
   -l <len>   Length in bytes of area to access (defaults to
              one access, or whole file length)
   -r|w       Read from or Write to memory (default read)
   -f <file>  File to write on memory read, or
              to read on memory write
   <addr>     The memory address to access
   <val>      The value to write (implies -w)

Examples:
   io 0x1000                  Reads one byte from 0x1000
   io 0x1000 0x12             Writes 0x12 to location 0x1000
   io -2 -l 8 0x1000          Reads 8 words from 0x1000
   io -r -f dmp -l 100 200    Reads 100 bytes from addr 200 to file
   io -w -f img 0x10000       Writes the whole of file to memory

Note access size (-1|2|4) does not apply to file based accesses.
```
从帮助上可以看出，如果要读或者写一个寄存器，可以用：
```
io -4 -r 0x1000 //读从0x1000起的4位寄存器的值
io -4 -w 0x1000 //写从0x1000起的4位寄存器的值
```
使用示例：

*    查看GPIO1_B3引脚的复用情况

*  从主控的datasheet查到GPIO1对应寄存器基地址为：0xff320000
*  从主控的datasheet查到GPIO1B_IOMUX的偏移量为：0x00014
*  GPIO1_B3的iomux寄存器地址为：基址(Operational Base) + 偏移量(offset)=0xff320000+0x00014=0xff320014  
*  用以下指令查看GPIO1_B3的复用情况：
```
# io -4 -r 0xff320014
ff320014:  0000816a
```

*  从datasheet查到[7:6]：
```
gpio1b3_sel 
GPIO1B[3] iomux select  
2'b00: gpio 
2'b01: i2c4sensor_sda 
2'b10: reserved 
2'b11: reserved
```
因此可以确定该GPIO被复用为 i2c4sensor_sda。

*  如果想复用为GPIO,可以使用以下指令设置：
```
# io -4 -w 0xff320014 0x0000812a
```
#### GPIO调试接口

Debugfs文件系统目的是为开发人员提供更多内核数据，方便调试。 这里GPIO的调试也可以用Debugfs文件系统，获得更多的内核信息。 GPIO在Debugfs文件系统中的接口为 /sys/kernel/debug/gpio，可以这样读取该接口的信息：
```
# cat /sys/kernel/debug/gpio
GPIOs 0-31, platform/pinctrl, gpio0:
 gpio-1   (                    |?                   ) out hi    
 gpio-4   (                    |sysfs               ) out hi    
 gpio-5   (                    |bt_default_wake_host) in  hi    
 gpio-10  (                    |sysfs               ) out hi    
 gpio-11  (                    |sysfs               ) out hi    

GPIOs 32-63, platform/pinctrl, gpio1:
 gpio-32  (                    |sysfs               ) out hi    
 gpio-33  (                    |vcc3v3_3g           ) out hi    
 gpio-35  (                    |sysfs               ) out hi    
 gpio-36  (                    |sysfs               ) out lo    
 gpio-45  (                    |?                   ) out lo    
 gpio-46  (                    |vsel                ) out lo    
 gpio-49  (                    |vsel                ) out lo    
 gpio-54  (                    |sysfs               ) out hi    
 gpio-55  (                    |sysfs               ) out hi    
 gpio-56  (                    |sysfs               ) out hi    

GPIOs 64-95, platform/pinctrl, gpio2:
 gpio-70  (                    |reset-gpio          ) out hi    
 gpio-72  (                    |irq-gpio            ) in  hi    
 gpio-76  (                    |cs-gpio             ) out hi    
 gpio-83  (                    |bt_default_rts      ) in  hi    
 gpio-90  (                    |bt_default_wake     ) in  hi    
 gpio-91  (                    |reset               ) out hi    
 gpio-92  (                    |bt_default_reset    ) out lo    

GPIOs 96-127, platform/pinctrl, gpio3:
 gpio-111 (                    |mdio-reset          ) out hi    

GPIOs 128-159, platform/pinctrl, gpio4:
 gpio-149 (                    |vbus-gpio           ) out hi    
 gpio-154 (                    |vcc5v0_host         ) out hi    

GPIOs 511-511, platform/rk805-pinctrl, rk817-gpio, can sleep:
```
从读取到的信息中可以知道，内核把GPIO当前的状态都列出来了，以GPIO0组为例，gpio-2(GPIO0_A2)作为3G模块的电源控制脚(vcc3v3_3g)，输出高电平(out hi)。
### FAQs
#### Q1: 如何将PIN的MUX值切换为一般的GPIO？

A1: 当使用GPIO request时候，会将该PIN的MUX值强制切换为GPIO，所以使用该pin脚为GPIO功能的时候确保该pin脚没有被其他模块所使用。
#### Q2: 为什么我用IO指令读出来的值都是0x00000000？

A2: 如果用IO命令读某个GPIO的寄存器，读出来的值异常,如 0x00000000或0xffffffff等，请确认该GPIO的CLK是不是被关了，GPIO的CLK是由CRU控制，可以通过读取datasheet下面CRU_CLKGATE_CON* 寄存器来查到CLK是否开启，如果没有开启可以用io命令设置对应的寄存器，从而打开对应的CLK，打开CLK之后应该就可以读到正确的寄存器值了。
#### Q3: 测量到PIN脚的电压不对应该怎么查？

A3: 测量该PIN脚的电压不对时，如果排除了外部因素，可以确认下该pin所在的io电压源是否正确，以及IO-Domain配置是否正确。
#### Q4: gpio_set_value()与gpio_direction_output()有什么区别？

A4: 如果使用该GPIO时，不会动态的切换输入输出，建议在开始时就设置好GPIO 输出方向，后面拉高拉低时使用gpio_set_value()接口，而不建议使用gpio_direction_output(), 因为gpio_direction_output接口里面有mutex锁，对中断上下文调用会有错误异常，且相比 gpio_set_value，gpio_direction_output 所做事情更多，浪费。


## I2C 使用

### 简介

AIO-3399PRO-JD4 开发板上有 9 个片上 I2C 控制器，各个 I2C 的使用情况如下表：

![](img/i2c.jpg)

本文主要描述如何在该开发板上配置 I2C。

配置 I2C 可分为两大步骤：

*    定义和注册 I2C 设备

*    定义和注册 I2C 驱动

下面以配置 GSL3680 为例。
### 定义和注册 I2C 设备

在注册I2C设备时，需要结构体 i2c_client 来描述 I2C 设备。然而在标准Linux中，用户只需要提供相应的 I2C 设备信息，Linux就会根据所提供的信息构造 i2c_client 结构体。

用户所提供的 I2C 设备信息以节点的形式写到 dts 文件中，如下所示：
```
kernel/arch/arm64/boot/dts/rockchip/rk3399pro-firefly-aiojd4-edp.dts
&i2c4 {
    status = "okay";
    gsl3680: gsl3680@41 {
        compatible = "gslX680";
        reg = <0x41>;
        screen_max_x = <1536>;
        screen_max_y = <2048>;
        touch-gpio = <&gpio1 20 IRQ_TYPE_LEVEL_LOW>;
        reset-gpio = <&gpio0 12 GPIO_ACTIVE_HIGH>;
    };  
};
```
### 定义和注册 I2C 驱动
#### 定义 I2C 驱动

在定义 I2C 驱动之前，用户首先要定义变量 of_device_id 和 i2c_device_id 。

of_device_id 用于在驱动中调用dts文件中定义的设备信息，其定义如下所示：
```
static struct of_device_id gsl_ts_ids[] = {
    {.compatible = "gslX680"},
    {}   
};
```
定义变量 i2c_device_id：
```
static const struct i2c_device_id gsl_ts_id[] = { 
    {GSLX680_I2C_NAME, 0}, 
    {}   
};
 MODULE_DEVICE_TABLE(i2c, gsl_ts_id);
```
i2c_driver 如下所示：
```
static struct i2c_driver gsl_ts_driver = { 
    .driver = { .name = GSLX680_I2C_NAME, 
    .owner = THIS_MODULE, 
    .of_match_table = of_match_ptr(gsl_ts_ids), 
    },   
 #ifndef CONFIG_HAS_EARLYSUSPEND 
    //.suspend  = gsl_ts_suspend, 
    //.resume   = gsl_ts_resume,
 #endif 
    .probe      = gsl_ts_probe, 
    .remove     = gsl_ts_remove, 
    .id_table   = gsl_ts_id,
};
```
注：变量id_table指示该驱动所支持的设备。
#### 注册 I2C 驱动

使用i2c_add_driver函数注册 I2C 驱动。
```
i2c_add_driver(&gsl_ts_driver);
```
在调用 i2c_add_driver 注册 I2C 驱动时，会遍历 I2C 设备，如果该驱动支持所遍历到的设备，则会调用该驱动的 probe 函数。
#### 通过 I2C 收发数据

在注册好 I2C 驱动后，即可进行 I2C 通讯。

*    向从机发送信息：
```
int i2c_master_send(const struct i2c_client *client, const char *buf, int count)
{   
    int ret; 
    struct i2c_adapter *adap = client->adapter; 
    struct i2c_msg msg; 
    msg.addr = client->addr; 
    msg.flags = client->flags & I2C_M_TEN; 
    msg.len = count; 
    msg.buf = (char *)buf; 
    ret = i2c_transfer(adap, &msg, 1);
    /*
    + If everything went ok (i.e. 1 msg transmitted), return #bytes
    + transmitted, else error code.
    */ 
    return (ret == 1) ? count : ret;
}
```

*    向从机读取信息：
```
int i2c_master_recv(const struct i2c_client *client, char *buf, int count)
{ 
    struct i2c_adapter *adap = client->adapter; 
    struct i2c_msg msg; 
    int ret; 
    msg.addr = client->addr; 
    msg.flags = client->flags & I2C_M_TEN; 
    msg.flags |= I2C_M_RD; 
    msg.len = count; 
    msg.buf = buf; 
    ret = i2c_transfer(adap, &msg, 1);  
    /* 
    + If everything went ok (i.e. 1 msg received), return #bytes received,
    + else error code.
    */ 
    return (ret == 1) ? count : ret;
} 
EXPORT_SYMBOL(i2c_master_recv);
```
### FAQs
#### Q1: 通信失败，出现这种log："timeout, ipd: 0x00, state: 1"该如何调试？

A1: 请检查硬件上拉是否给电。
#### Q2: 调用i2c_transfer返回值为-6？

A2: 返回值为-6表示为NACK错误，即对方设备无应答响应，这种情况一般为外设的问题，常见的有以下几种情况：

* I2C地址错误，解决方法是测量I2C波形，确认是否I2C 设备地址错误；

* I2C slave 设备不处于正常工作状态，比如未给电，错误的上电时序等；

* 时序不符合 I2C slave设备所要求也会产生Nack信号。

#### Q3: 当外设对于读时序要求中间是stop信号不是repeat start信号的时候，该如何处理？

A3: 这时需要调用两次i2c_transfer, I2C read 拆分成两次，修改如下：
```
static int i2c_read_bytes(struct i2c_client *client, u8 cmd, u8 *data, u8 data_len) { 
    struct i2c_msg msgs[2]; 
    int ret; 
    u8 *buffer;  
    buffer = kzalloc(data_len, GFP_KERNEL); 
    if (!buffer) 
        return -ENOMEM;;  
    msgs[0].addr = client->addr; 
    msgs[0].flags = client->flags; 
    msgs[0].len = 1; 
    msgs[0].buf = &cmd; 
    ret = i2c_transfer(client->adapter, msgs, 1); 
    if (ret < 0) { 
        dev_err(&client->adapter->dev, "i2c read failed\n"); 
        kfree(buffer); 
        return ret; 
    }  
    msgs[1].addr = client->addr; 
    msgs[1].flags = client->flags | I2C_M_RD; 
    msgs[1].len = data_len; 
    msgs[1].buf = buffer;  
    ret = i2c_transfer(client->adapter, &msgs[1], 1); 
    if (ret < 0) 
        dev_err(&client->adapter->dev, "i2c read failed\n"); 
    else 
        memcpy(data, buffer, data_len);  
    kfree(buffer);
    return ret; 
}
```

## IR 使用

### 红外遥控配置

AIO-3399PRO-JD4 开发板上使用红外收发传感器 IR (耳机接口和recovery之间)实现遥控功能，在IR接口处接上红外接收器。本文主要描述在开发板上如何配置红外遥控器。

其配置步骤可分为两个部分：

* 修改内核驱动：内核空间修改，Linux 和 Android 都要修改这部分的内容。
* 修改键值映射：用户空间修改（仅限 Android 系统）。

### 内核驱动

在 Linux 内核中，IR 驱动仅支持 NEC 编码格式。以下是在内核中配置红外遥控的方法。
所涉及到的文件
```
drivers/input/remotectl/rockchip_pwm_remotectl.c
```
#### 定义相关数据结构

以下是定义数据结构的步骤：
```
&pwm3 {
    status = "okay";
    interrupts = ;
    compatible = "rockchip,remotectl-pwm";
    remote_pwm_id = ;
    handle_cpu_id = ; 
    ir_key1{
    rockchip,usercode = ;
    rockchip,key_table = {
        {0xeb, KEY_POWER},        // Power
        //Control
        {0xa3, 250},              // Settings
        {0xec, KEY_MENU},         // Menu
        {0xfc, KEY_UP},           // Up
        {0xfd, KEY_DOWN},         // Down
        {0xf1, KEY_LEFT},         // Left
        {0xe5, KEY_RIGHT},        // Right
        {0xf8, KEY_REPLY},        // Ok
        {0xb7, KEY_HOME},         // Home
        {0xfe, KEY_BACK},         // Back
        // Vol
        {0xa7, KEY_VOLUMEDOWN},   // Vol-
        {0xf4, KEY_VOLUMEUP},     // Vol+
    };
};
```
注：第一列为键值，第二列为要响应的按键码。

#### 如何获取用户码和IR 键值

在 remotectl_do_something 函数中获取用户码和键值：
```
case RMC_USERCODE:
{
    //ddata->scanData <<= 1;
    //ddata->count ++;
    if ((RK_PWM_TIME_BIT1_MIN < ddata->period) && (ddata->period < RK_PWM_TIME_BIT1_MAX)){
        ddata->scanData |= (0x01<<ddata->count);
    }
    ddata->count ++;
    if (ddata->count == 0x10){//16 bit user code
        DBG_CODE("GET USERCODE=0x%x\n",((ddata->scanData) & 0xffff));
        if (remotectl_keybdNum_lookup(ddata)){
            ddata->state = RMC_GETDATA;
            ddata->scanData = 0;
            ddata->count = 0;
        }else{                //user code error
            ddata->state = RMC_PRELOAD;
        }
    }
}
```
注：用户可以使用 DBG_CODE() 函数打印用户码。

使用下面命令可以使能DBG_CODE打印：
```
echo 1 > /sys/module/rockchip_pwm_remotectl/parameters/code_print
```

#### 将 IR 驱动编译进内核
将 IR 驱动编译进内核的步骤如下所示：

(1)、向配置文件 drivers/input/remotectl/Kconfig 中添加如下配置：
```
config RK_REMOTECTL_PWM
    bool "rkxx remoctrl pwm0 capture"
default n
```
(2)、修改 drivers/input/remotectl 路径下的 Makefile,添加如下编译选项：
```
obj-$(RK_REMOTECTL_PWM)      += rk_pwm_remotectl.o
```
(3)、在 kernel 路径下使用 make menuconfig ，按照如下方法将IR驱动选中。
```
Device Drivers
  --->Input device support
  ----->  [*]   rkxx remotectl
  ------->[*]   rkxx remoctrl pwm0 capture.
```
保存后，执行 make 命令即可将该驱动编进内核。
#### Android 键值映射

文件 /system/usr/keylayout/ff420030_pwm.kl 用于将 Linux 层获取的键值映射到 Android 上对应的键值。用户可以添加或者修改该文件的内容以实现不同的键值映射。

该文件内容如下所示：
```
key 28    ENTER
key 116   POWER             WAKE
key 158   BACK
key 139   MENU
key 217   SEARCH
key 232   DPAD_CENTER
key 108   DPAD_DOWN
key 103   DPAD_UP
key 102   HOME
key 105   DPAD_LEFT
key 106   DPAD_RIGHT
key 115   VOLUME_UP
key 114   VOLUME_DOWN
key 143   NOTIFICATION      WAKE
key 113   VOLUME_MUTE
key 388   TV_KEYMOUSE_MODE_SWITCH
key 400   TV_MEDIA_MULT_BACKWARD
key 401   TV_MEDIA_MULT_FORWARD
key 402   TV_MEDIA_PLAY_PAUSE
key 64    TV_MEDIA_PLAY
key 65    TV_MEDIA_PAUSE
key 66    TV_MEDIA_STOP
```
注：通过 adb 修改该文件重启后即可生效。

### IR 使用

如下图是通过按红外遥控器按钮，所产生的波形，主要由head,Control,information,signed free这四部分组成，具体可以参考RC6 Protocol。

![](img/IR.jpg)


## LCD使用
### 简介

AIO-3399PRO-JD4开发板默认外置支持了两个LCD屏接口，一个是LVDS，一个是EDP，接口对应板子上的位置如下图：

![](img/LCD.PNG)

另外板子也支持MIPI屏幕，但需要注意的是MIPI和LVDS是复用的，使用MIPI之后不能使用LVDS。MIPI接口如下图:
![](img/jd4_lcd2.png)

### Config配置

如Android8.1，由于使用的是mipi转lvds，AIO-3399PRO-JD4默认的配置文件kernel/arch/arm64/configs/firefly_defconfig已经把LCD相关的配置设置好了，如果自己做了修改，请注意把以下配置加上：
```
CONFIG_LCD_MIPI=y
CONFIG_MIPI_DSI=y
CONFIG_RK32_MIPI_DSI=y
```
### DTS配置
#### 引脚配置
###### LVDS屏

AIO-3399PRO-JD4的SDK有LVDS DSI的DTS文件：kernel/arch/arm64/boot/dts/rockchip/rk3399pro-firefly-aiojd4-lvds-HSX101H40C.dts，从该文件中我们可以看到以下语句：
```
/ {
	model = "AIO-3399PRO-JD4 Board lvds HSX101H40C (Android)";
	compatible = "rockchip,android", "rockchip,rk3399-firefly-lvds", "rockchip,rk3399";
};

&backlight {
        status = "okay";
        pwms = <&pwm0 0 25000 1>; 
        enable-gpios = <&gpio1 1 GPIO_ACTIVE_HIGH>;
        default-brightness-level = <200>;
        polarity = <1>;
        brightness-levels = </*
                          0   1   2   3   4   5   6   7
                          8   9  10  11  12  13  14  15
                         16  17  18  19  20  21  22  23
                         24  25  26  27  28  29  30  31
                         32  33  34  35*/36  37  38  39
                         40  41  42  43  44  45  46  47
                         48  49  50  51  52  53  54  55
                         56  57  58  59  60  61  62  63
                         64  65  66  67  68  69  70  71
                         72  73  74  75  76  77  78  79
                         80  81  82  83  84  85  86  87
                         88  89  90  91  92  93  94  95
                         96  97  98  99 100 101 102 103
                        104 105 106 107 108 109 110 111
                        112 113 114 115 116 117 118 119
                        120 121 122 123 124 125 126 127
                        128 129 130 131 132 133 134 135
                        136 137 138 139 140 141 142 143
                        144 145 146 147 148 149 150 151
                        152 153 154 155 156 157 158 159
                        160 161 162 163 164 165 166 167
                        168 169 170 171 172 173 174 175
                        176 177 178 179 180 181 182 183
                        184 185 186 187 188 189 190 191
                        192 193 194 195 196 197 198 199
                        200 201 202 203 204 205 206 207
                        208 209 210 211 212 213 214 215
                        216 217 218 219 220 221 222 223
                        224 225 226 227 228 229 230 231
                        232 233 234 235 236 237 238 239
                        240 241 242 243 244 245 246 247
                        248 249 250 251 252 253 254 255>; 
};

&dsi {
        status = "okay";
        dsi_panel: panel {
                compatible ="simple-panel-dsi";
                reg = <0>;
                //ddc-i2c-bu
                //power-supply = <&vcc_lcd>;
                //pinctrl-0 = <&lcd_panel_reset &lcd_panel_enable>;
                backlight = <&backlight>;
                /*
                enable-gpios = <&gpio1 1 GPIO_ACTIVE_LOW>;
                reset-gpios = <&gpio4 29 GPIO_ACTIVE_LOW>;
                */
                dsi,flags = <(MIPI_DSI_MODE_VIDEO | MIPI_DSI_MODE_VIDEO_BURST | MIPI_DSI_MODE_LPM | MIPI_DSI_MODE_EOT_PACKET)>;
                dsi,format = <MIPI_DSI_FMT_RGB888>;
                //bus-format = <MEDIA_BUS_FMT_RGB666_1X18>;
                dsi,lvds-force-clk = <800>; // 800/2/3 ~= 65Mhz
                dsi,lanes = <4>;

                dsi,channel = <0>;

                enable-delay-ms = <35>;
                prepare-delay-ms = <6>;
        
                unprepare-delay-ms = <0>;
                disable-delay-ms = <20>;
                
                size,width = <120>;
                size,height = <170>;

                status = "okay";

                panel-init-sequence = [                 
                            29 02 06 3C 01 09 00 07 00                      
                            29 02 06 14 01 06 00 00 00                      
                            29 02 06 64 01 0B 00 00 00                      
                            29 02 06 68 01 0B 00 00 00                      
                            29 02 06 6C 01 0B 00 00 00                      
                            29 02 06 70 01 0B 00 00 00                      
                            29 02 06 34 01 1F 00 00 00                      
                            29 02 06 10 02 1F 00 00 00                      
                            29 02 06 04 01 01 00 00 00                      
                            29 02 06 04 02 01 00 00 00                      
                            29 02 06 50 04 20 01 F0 03                      
                            29 02 06 54 04 19 00 5A 00                       //5A
                            29 02 06 58 04 20 03 24 00                      
                            29 02 06 5C 04 0A 00 19 00                      
                            29 02 06 60 04 00 05 0A 00                      
                            29 02 06 64 04 01 00 00 00                      
                            29 02 06 A0 04 06 80 44 00                      
                        
                            29 02 06 A0 04 06 80 04 00
                            29 02 06 04 05 04 00 00 00                      
                            29 02 06 80 04 00 01 02 03                      
                            29 02 06 84 04 04 07 05 08                      
                            29 02 06 88 04 09 0A 0E 0F                      
                            29 02 06 8C 04 0B 0C 0D 10                      
                            29 02 06 90 04 16 17 11 12                      
                            29 02 06 94 04 13 14 15 1B                      
                            29 02 06 98 04 18 19 1A 06

                            29 02 06 9C 04 31 04 00 00
                ];
                panel-exit-sequence = [
                        05 05 01 28
                        05 78 01 10
                ];
                
                power_ctr: power_ctr {
                        rockchip,debug = <0>;
                        power_enable = <1>;
	                    bl_en:bl_en {
                                gpios = <&gpio1 RK_PC5 GPIO_ACTIVE_HIGH>;
                                pinctrl-names = "default";
                                pinctrl-0 = <&lcd_panel_bl_en>;
                                rockchip,delay = <0>;
	                    };
	                    lcd_en:lcd_en {
                                gpios = <&gpio4 RK_PD6 GPIO_ACTIVE_HIGH>;
                                pinctrl-names = "default";
                                pinctrl-0 = <&lcd_panel_lcd_en>;
                                rockchip,delay = <10>;
	                    };
                        lcd_pwr_en: lcd-pwr-en {
                                gpios = <&gpio1 RK_PA2 GPIO_ACTIVE_HIGH>;
                                pinctrl-names = "default";
                                pinctrl-0 = <&lcd_panel_pwr_en>;
                                rockchip,delay = <10>;
                        };

                        lcd_rst: lcd-rst {
                                gpios = <&gpio4 RK_PD1 GPIO_ACTIVE_HIGH>;
                                pinctrl-names = "default";
                                pinctrl-0 = <&lcd_panel_reset>;
                                rockchip,delay = <6>;
                        };
                };

                disp_timings: display-timings {
                        native-mode = <&timing0>;
                        timing0: timing0 {
                                clock-frequency = <166000000>; //166000000 @50
                                hactive = <800>;
                                vactive = <1280>;
                                hsync-len = <10>;   //20, 50
                                hback-porch = <100>; //50, 56
                                hfront-porch = <1580>;//50, 30 //1580
                                vsync-len = <10>;
                                vback-porch = <25>;
                                vfront-porch = <10>;
                                hsync-active = <0>;
                                vsync-active = <0>;
                                de-active = <0>;
                                pixelclk-active = <0>;
                        };
                };
        };
};
```
这里定义了LCD的电源控制引脚：

```
bl_en:(GPIO1_C5)GPIO_ACTIVE_HIGH
lcd_en:(GPIO4_D6)GPIO_ACTIVE_HIGH
lcd_pwr_en:(GPIO1_A2)GPIO_ACTIVE_HIGH
lcd_rst:(GPIO4_D1)GPIO_ACTIVE_HIGH
```
都是高电平有效，具体的引脚配置请参考[《GPIO 使用》](drive_development.html#gpio-shi-yong)一节。
#### LVDS配置背光

AIO-3399PRO-JD4开发板外置了一个背光接口用来控制屏幕背光，如下图所示：

![](img/backlight.PNG)

在DTS文件：kernel/arch/arm64/boot/dts/rockchip/rk3399pro-firefly-core.dtsi中配置了背光信息，如下：
```
/ {
    compatible = "rockchip,rk3399-firefly-core", "rockchip,rk3399";

    backlight: backlight {
        status = "disabled";
        compatible = "pwm-backlight";
        pwms = <&pwm0 0 25000 0>;
        brightness-levels = <
              0   1   2   3   4   5   6   7
              8   9  10  11  12  13  14  15
             16  17  18  19  20  21  22  23
             24  25  26  27  28  29  30  31
             32  33  34  35  36  37  38  39
             40  41  42  43  44  45  46  47   
             48  49  50  51  52  53  54  55
             56  57  58  59  60  61  62  63  
             64  65  66  67  68  69  70  71  
             72  73  74  75  76  77  78  79  
             80  81  82  83  84  85  86  87  
             88  89  90  91  92  93  94  95
             96  97  98  99 100 101 102 103  
            104 105 106 107 108 109 110 111  
            112 113 114 115 116 117 118 119  
            120 121 122 123 124 125 126 127  
            128 129 130 131 132 133 134 135
            136 137 138 139 140 141 142 143 
            144 145 146 147 148 149 150 151 
            152 153 154 155 156 157 158 159 
            160 161 162 163 164 165 166 167 
            168 169 170 171 172 173 174 175  
            176 177 178 179 180 181 182 183 
            184 185 186 187 188 189 190 191 
            192 193 194 195 196 197 198 199 
            200 201 202 203 204 205 206 207 
            208 209 210 211 212 213 214 215 
            216 217 218 219 220 221 222 223 
            224 225 226 227 228 229 230 231
            232 233 234 235 236 237 238 239  
            240 241 242 243 244 245 246 247  
            248 249 250 251 252 253 254 255>;
        default-brightness-level = <200>;
};
```
pwms属性：配置PWM，范例里面默认使用pwm0，25000ns是周期(40 KHz)。LVDS需要加背光电源控制脚，在kernel/arch/arm64/boot/dts/rockchip/rk3399-firefly-aiojd4-lvds-HSX101H40C.dts中可以看到以下语句：
```
&backlight {
    status = "okay";
    enable-gpios = <&gpio1 1 GPIO_ACTIVE_HIGH>;
    brightness-levels = < 150 151
    152 153 154 155 156 157 158 159
    160 161 162 163 164 165 166 167
    168 169 170 171 172 173 174 175
    176 177 178 179 180 181 182 183
    184 185 186 187 188 189 190 191
    192 193 194 195 196 197 198 199
    200 201 202 203 204 205 206 207
    208 209 210 211 212 213 214 215
    216 217 218 219 220 221 222 223
    224 225 226 227 228 229 230 231
    232 233 234 235 236 237 238 239
    240 241 242 243 244 245 246 247
    248 249 250 251 252 253 254 255>;
};
```
因此使用时需修改DTS文件。

brightness-levels属性：配置背光亮度数组，最大值为255，配置暗区和亮区，并把亮区数组做255的比例调节。比如范例中暗区是255-221，亮区是220-0。
default-brightness-level属性：开机时默认背光亮度，范围为0-255。
具体请参考kernel中的说明文档：kernel/Documentation/devicetree/bindings/leds/backlight/pwm-backlight.txt
#### 配置显示时序

##### LVDS屏

与EDP屏不同，LVDS屏的 Timing 写在DTS文件中，在kernel/arch/arm64/boot/dts/rockchip/rk3399pro-firefly-aiojd4-lvds-HSX101H40C.dts中可以看到以下语句：

```
disp_timings: display-timings {
                        native-mode = <&timing0>;
                        timing0: timing0 {
                                clock-frequency = <166000000>; //166000000 @50
                                hactive = <800>;
                                vactive = <1280>;
                                hsync-len = <10>;   //20, 50
                                hback-porch = <100>; //50, 56
                                hfront-porch = <1580>;//50, 30 //1580
                                vsync-len = <10>;
                                vback-porch = <25>;
                                vfront-porch = <10>;
                                hsync-active = <0>;
                                vsync-active = <0>;
                                de-active = <0>;
                                pixelclk-active = <0>;
                        };
                };
```

时序属性参考下图：

![](img/lcd3.png)

#### Init Code
###### LVDS屏
lvds屏上完电后需要发送初始化指令才能使之工作。

* dts
可以在kernel/arch/arm64/boot/dts/rockchip/rk3399pro-firefly-aiojd4-lvds-HSX101H40C.dts中可以看到lvds的初始化指令列表：
```
&dsi {    
   status = "okay";
        ...
  panel-init-sequence = [                 
  29 00 06 3C 01 09 00 07 00
  29 00 06 14 01 06 00 00 00
  29 00 06 64 01 0B 00 00 00
  29 00 06 68 01 0B 00 00 00
  29 00 06 6C 01 0B 00 00 00
  29 00 06 70 01 0B 00 00 00
  29 00 06 34 01 1F 00 00 00
  29 00 06 10 02 1F 00 00 00
  29 00 06 04 01 01 00 00 00
  29 00 06 04 02 01 00 00 00
  29 00 06 50 04 20 01 F0 03
  29 00 06 54 04 32 00 B4 00
  29 00 06 58 04 80 07 48 00
  29 00 06 5C 04 0A 00 19 00
  29 00 06 60 04 38 04 0A 00
  29 00 06 64 04 01 00 00 00
  29 01 06 A0 04 06 80 44 00
  29 00 06 A0 04 06 80 04 00
  29 00 06 04 05 04 00 00 00
  29 00 06 80 04 00 01 02 03
  29 00 06 84 04 04 07 05 08
  29 00 06 88 04 09 0A 0E 0F
  29 00 06 8C 04 0B 0C 0D 10
  29 00 06 90 04 16 17 11 12
  29 00 06 94 04 13 14 15 1B
  29 00 06 98 04 18 19 1A 06
  29 02 06 9C 04 33 04 00 00
  ];
  panel-exit-sequence = [
                        05 05 01 28
                        05 78 01 10
  ];
        ...
};
```
命令格式以及说明可参考以下附件：
[Rockchip DRM Panel Porting Guide.pdf](http://www.t-firefly.com/ueditor/php/upload/file/20171213/1513128959299913.pdf)

* kernel
发送指令可以看到在kernel/drivers/gpu/drm/panel/panel-simple.c文件中的操作：
```
static int panel_simple_enable(struct drm_panel *panel)
{
    struct panel_simple *p = to_panel_simple(panel);
    int err;
    if (p->enabled)
        return 0;
    DBG("enter\n");
    if (p->on_cmds) {
        err = panel_simple_dsi_send_cmds(p, p->on_cmds);
        if (err)
            dev_err(p->dev, "failed to send on cmds\n");
    }
    if (p->desc && p->desc->delay.enable) {
        DBG("p->desc->delay.enable=%d\n", p->desc->delay.enable);
        msleep(p->desc->delay.enable);
    }
    if (p->backlight) {
        DBG("open backlight\n");
        p->backlight->props.power = FB_BLANK_UNBLANK;
        backlight_update_status(p->backlight);
    }
    p->enabled = true;
    return 0;
}
```
* u-boot
发送指令可以看到在u-boot/drivers/video/rockchip-dw-mipi-dsi.c文件中的操作：
```
static int rockchip_dw_mipi_dsi_enable(struct display_state *state)
{
    struct connector_state *conn_state = &state->conn_state;
    struct crtc_state *crtc_state = &state->crtc_state;
    const struct rockchip_connector *connector = conn_state->connector;
    const struct dw_mipi_dsi_plat_data *pdata = connector->data;
    struct dw_mipi_dsi *dsi = conn_state->private;
    u32 val;
    DBG("enter\n");
    dw_mipi_dsi_set_mode(dsi, DW_MIPI_DSI_VID_MODE);
    dsi_write(dsi, DSI_MODE_CFG, ENABLE_CMD_MODE);
    dw_mipi_dsi_set_mode(dsi, DW_MIPI_DSI_VID_MODE);
    if (!pdata->has_vop_sel)
        return 0;
    if (pdata->grf_switch_reg) {
        if (crtc_state->crtc_id)
            val = pdata->dsi0_en_bit | (pdata->dsi0_en_bit << 16);
        else
            val = pdata->dsi0_en_bit << 16;
        writel(val, RKIO_GRF_PHYS + pdata->grf_switch_reg);
    }
    debug("vop %s output to dsi0\n", (crtc_state->crtc_id) ? "LIT" : "BIG");
    //rockchip_dw_mipi_dsi_read_allregs(dsi);
    return 0;
}
```

### DTS配置
#### 引脚配置
###### EDP屏
AIO-3399PRO-JD4的SDK有EDP DSI的DTS文件：kernel/arch/arm64/boot/dts/rockchip/rk3399pro-firefly-aiojd4-edp.dts，从该文件中我们可以看到以下语句：
```
  edp_panel: edp-panel {
		/* config 2 */
		compatible = "lg,lp079qx1-sp0v";
		/* config 3 */
		//compatible = "simple-panel";
		bus-format = <MEDIA_BUS_FMT_RGB666_1X18>;

		backlight = <&backlight>;

		ports {
			panel_in_edp: endpoint {
				remote-endpoint = <&edp_out_panel>;
			};
		};

		power_ctr: power_ctr {
		power_enable = <1>;
               rockchip,debug = <0>;
               lcd_en: lcd-en {
                       gpios = <&gpio1 4 GPIO_ACTIVE_HIGH>;
					   pinctrl-names = "default";
					   pinctrl-0 = <&lcd_panel_enable>;
                       rockchip,delay = <20>;
               };
               lcd_pwr_en: lcd-pwr-en {
                       gpios = <&gpio0 1 GPIO_ACTIVE_HIGH>;
                       pinctrl-names = "default";
                       pinctrl-0 = <&lcd_panel_pwr_en>;
                       rockchip,delay = <10>;
               };
       };
};
···
&pinctrl {
	lcd-panel {
		lcd_panel_enable: lcd-panel-enable {
			rockchip,pins = <1 4 RK_FUNC_GPIO &pcfg_pull_up>;
		};
        lcd_panel_pwr_en: lcd-panel-pwr-en {
            rockchip,pins = <0 1 RK_FUNC_GPIO &pcfg_pull_up>;
        };
	};
};

```
这里定义了LCD的电源控制引脚：
```
lcd_en:(GPIO1_A4)GPIO_ACTIVE_HIGH
lcd_pwr_en:(GPIO0_A1)GPIO_ACTIVE_HIGH
```
都是高电平有效，具体的引脚配置请参考[《GPIO 使用》](drive_development.html#gpio-shi-yong)一节。

#### EDP配置背光
因为背光接口是公用的，所以可参考上述LVDS的配置方法。

#### EDP配置显示时序
kernel 把 Timing 写在 panel-simple.c 中， 直接以短字符串匹配 在drivers/gpu/drm/panel/panel-simple.c文件中有以下语句

```
static const struct drm_display_mode lg_lp079qx1_sp0v_mode = {
  .clock = 200000,
  .hdisplay = 1536,
  .hsync_start = 1536 + 12,
  .hsync_end = 1536 + 12 + 16,
  .htotal = 1536 + 12 + 16 + 48,
  .vdisplay = 2048,
  .vsync_start = 2048 + 8,
  .vsync_end = 2048 + 8 + 4,
  .vtotal = 2048 + 8 + 4 + 8,
  .vrefresh = 60,
  .flags = DRM_MODE_FLAG_NVSYNC | DRM_MODE_FLAG_NHSYNC,
};

static const struct panel_desc lg_lp097qx1_spa1 = {
  .modes = &lg_lp097qx1_spa1_mode,
  .num_modes = 1,
  .size = {
    .width = 320,
    .height = 187,
  },
};

... ...

   static const struct of_device_id platform_of_match[] = {
  {
    .compatible = "simple-panel",
    .data = NULL,
  },{

  }, {
    .compatible = "lg,lp079qx1-sp0v",
    .data = &lg_lp079qx1_sp0v,
  }, {

  }, {
    /* sentinel */
  }
};
```

MODULE_DEVICE_TABLE(of, platform_of_match); 时序的参数在结构体lg_lp079qx1_sp0v_mode中配置。

*U-boot
把 Timing 写在 rockchip_panel.c 中， 直接以短字符串匹配 在drivers/video/rockchip_panel.c文件中有以下语句：
```
static const struct drm_display_mode lg_lp079qx1_sp0v_mode = {
  .clock = 200000,
  .hdisplay = 1536,
  .hsync_start = 1536 + 12,
  .hsync_end = 1536 + 12 + 16,
  .htotal = 1536 + 12 + 16 + 48,
  .vdisplay = 2048,
  .vsync_start = 2048 + 8,
  .vsync_end = 2048 + 8 + 4,
  .vtotal = 2048 + 8 + 4 + 8,
  .vrefresh = 60,
  .flags = DRM_MODE_FLAG_NVSYNC | DRM_MODE_FLAG_NHSYNC,
};
static const struct rockchip_panel g_panel[] = {
  {
    .compatible = "lg,lp079qx1-sp0v",
    .mode = &lg_lp079qx1_sp0v_mode,
  }, {
    .compatible = "auo,b125han03",
    .mode = &auo_b125han03_mode,
  },
};
```
时序的参数在结构体lg_lp079qx1_sp0v_mode中配置。

###### MIPI屏
客户根据需要在自行添加mipi硬件接口之后，配置MIPI屏的 Timing dts文件，在kernel/arch/arm64/boot/dts/rockchip/rk3399pro-firefly-aiojd4-mipi.dts中可以看到以下语句：
```
disp_timings: display-timings {
    native-mode = <&timing0>;
    timing0: timing0 {
         clock-frequency = <80000000>;
         hactive = <768>;
         vactive = <1024>;
         hsync-len = <20>;   //20, 50
         hback-porch = <130>; //50, 56
         hfront-porch = <150>;//50, 30
         vsync-len = <40>;
         vback-porch = <130>;
         vfront-porch = <136>;
         hsync-active = <0>;
         vsync-active = <0>;
         de-active = <0>;
         pixelclk-active = <0>;
           };
    }
}
```

Kernel
在kernel/drivers/gpu/drm/panel/panel-simple.c中可以看到在初始化函数panel_simple_probe中初始化了获取时序的函数。
```
static int panel_simple_probe(struct device *dev, const struct panel_desc *desc){
···
 panel->base.funcs = &panel_simple_funcs;
···
}
```

该函数的在kernel/drivers/gpu/drm/panel/panel-simple.c中也有定义：
```
static int panel_simple_get_timings(struct drm_panel *panel,unsigned int num_timings,struct display_timing *timings)
{
    struct panel_simple *p = to_panel_simple(panel); 
    unsigned int i;
    if (!p->desc)  
        return 0;
        
    if (p->desc->num_timings < num_timings)  
        num_timings = p->desc->num_timings;
        
    if (timings)  
        for (i = 0; i < num_timings; i++)   
        timings[i] = p->desc->timings[i];
    return p->desc->num_timings;
}
```

mipi屏上完电后需要发送初始化指令才能使之工作，可以在kernel/arch/arm64/boot/dts/rockchip/rk3399pro-firefly-mipi.dts中可以看到mipi的初始化指令列表：
```
&mipi_dsi {    
            status = "okay";      
        ...
            panel-init-sequence = [                
                05 20 01 29                
                05 96 01 11            
            ];            
            
            panel-exit-sequence = [                
                05 05 01 28                
                05 78 01 10            
            ];
        ...
};
```
命令格式以及说明可参考以下附件：
[Rockchip DRM Panel Porting Guide.pdf](http://www.t-firefly.com/ueditor/php/upload/file/20171213/1513128959299913.pdf)

发送指令可以看到在kernel/drivers/gpu/drm/panel/panel-simple.c文件中的操作：
```
static int panel_simple_enable(struct drm_panel *panel)
{
    struct panel_simple *p = to_panel_simple(panel);
    int err;
    if (p->enabled)
        return 0;
    DBG("enter\n");
    if (p->on_cmds) {
        err = panel_simple_dsi_send_cmds(p, p->on_cmds);
        if (err)
            dev_err(p->dev, "failed to send on cmds\n");
    }
    if (p->desc && p->desc->delay.enable) {
        DBG("p->desc->delay.enable=%d\n", p->desc->delay.enable);
        msleep(p->desc->delay.enable);
    }
    if (p->backlight) {
        DBG("open backlight\n");
        p->backlight->props.power = FB_BLANK_UNBLANK;
        backlight_update_status(p->backlight);
    }
    p->enabled = true;
    return 0;
}
```

U-boot
发送指令可以看到在u-boot/drivers/video/rockchip-dw-mipi-dsi.c文件中的操作：
```
static int rockchip_dw_mipi_dsi_enable(struct display_state *state)
{
    struct connector_state *conn_state = &state->conn_state;
    struct crtc_state *crtc_state = &state->crtc_state;
    const struct rockchip_connector *connector = conn_state->connector;
    const struct dw_mipi_dsi_plat_data *pdata = connector->data;
    struct dw_mipi_dsi *dsi = conn_state->private;
    u32 val;
    DBG("enter\n");
    dw_mipi_dsi_set_mode(dsi, DW_MIPI_DSI_VID_MODE);
    dsi_write(dsi, DSI_MODE_CFG, ENABLE_CMD_MODE);
    dw_mipi_dsi_set_mode(dsi, DW_MIPI_DSI_VID_MODE);
    if (!pdata->has_vop_sel)
        return 0;
    if (pdata->grf_switch_reg) {
        if (crtc_state->crtc_id)
            val = pdata->dsi0_en_bit | (pdata->dsi0_en_bit << 16);
        else
            val = pdata->dsi0_en_bit << 16;
        writel(val, RKIO_GRF_PHYS + pdata->grf_switch_reg);
    }
    debug("vop %s output to dsi0\n", (crtc_state->crtc_id) ? "LIT" : "BIG");
    //rockchip_dw_mipi_dsi_read_allregs(dsi);
    return 0;
}
```




## LED 使用

### 前言

AIO-3399PRO-JD4 开发板上有 2 个 LED 灯，如下表所示：

![](img/led.png)

以设备的方式控制 LED可通过使用 LED 设备子系统或者直接操作 GPIO 控制该 LED。

标准的 Linux 专门为 LED 设备定义了 LED 子系统。 在 AIO-3399PRO-JD4 开发板中的两个 LED 均以设备的形式被定义。

用户可以通过 /sys/class/leds/ 目录控制这两个 LED。

开发板上的 LED 的默认状态为：

 * Blue: 系统上电时打开

 * Yellow：用户自定义

用户可以通过 echo 向其 brightness属性输入命令控制每一个 LED：
```
root@rk3399_firefly_box:~ # echo 0 >/sys/class/leds/firefly:blue:power/brightness  //蓝灯灭
root@rk3399_firefly_box:~ # echo 1 >/sys/class/leds/firefly:blue:power/brightness  //蓝灯亮
```
### 使用trigger 方式控制 LED

Trigger 包含多种方式可以控制LED,这里就用两个例子来说明

* Simple trigger LED

* Complex trigger LED

更详细的说明请参考 leds-class.txt 。

首先我们需要知道定义多少个LED,同时对应的LED的属性是什么。

在 kernel/arch/arm64/boot/dts/rockchip/rk3399pro-firefly-port.dts 文件中定义LED节点，具体定义如下：
```
leds {
    compatible = "gpio-leds";
    power_led: power {
    label = "firefly:blue:power";
    linux,default-trigger = "ir-power-click";
    default-state = "on";
    gpios = <&gpio0 RK_PA1 GPIO_ACTIVE_HIGH>;
    pinctrl-names = "default";
    pinctrl-0 = <&led_power>;
    };
    user_led: user {
    label = "firefly:yellow:user";
    linux,default-trigger = "ir-user-click";
    default-state = "off";
    gpios = <&gpio1 RK_PB5 GPIO_ACTIVE_HIGH>;
    pinctrl-names = "default";
    pinctrl-0 = <&led_user>;
    };
};
```
注意：compatible 的值要跟 drivers/leds/leds-gpio.c 中的 .compatible 的值要保持一致。
#### Simple trigger LED

按名字来是看就是简单的触发方式控制LED，如下就默认打开黄灯，AIO-3399PRO-JD4开机后黄灯就亮

（1）定义 LED 触发器 在kernel/drivers/leds/trigger/led-firefly-demo.c 文件中有如下添加
```
DEFINE_LED_TRIGGER(ledtrig_default_control);
```
（2）注册该触发器
```
led_trigger_register_simple("ir-user-click", &ledtrig_default_control);
```
（3）控制 LED 的亮。
```
led_trigger_event(ledtrig_default_control, LED_FULL);   //yellow led on
```
（4）打开LED demo

led-firefly-demo默认没有打开，如果需要的话可以使用以下补丁打开demo驱动：
```
--- a/kernel/arch/arm64/boot/dts/rockchip/rk3399-firefly-demo.dtsi
+++ b/kernel/arch/arm64/boot/dts/rockchip/rk3399-firefly-demo.dtsi
@@ -52,7 +52,7 @@
            led_demo: led_demo { 
-                status = "disabled";
+                status = "okay"; 
                 compatible = "firefly,rk3399-led"; 
                 };
```

#### Complex trigger LED

如下是trigger方式控制LED复杂一点的例子，timer trigger 就是让LED达到不断亮灭的效果

我们需要在内核把timer trigger配置上

在 kernel 路径下使用 make menuconfig ，按照如下方法将timer trigger驱动选中。
```
Device Drivers
--->LED Support
   --->LED Trigger support 
      --->LED Timer Trigger
```
保存配置并编译内核，把kernel.img 烧到AIO-3399PRO-JD4板子上 我们可以使用串口输入命令，就可以看到蓝灯不停的间隔闪烁
```
echo "timer" > sys/class/leds/firefly\:blue\:power/trigger
```
用户还可以使用 cat 命令获取 trigger 的可用值：
```
root@rk3399_firefly_box:/ # cat sys/class/leds/firefly\:blue\:power/trigger    
none rc-feedback test_ac-online test_battery-charging-or-full test_battery-charging 
test_battery-full test_battery-charging-blink-full-solid test_usb-online mmc0 mmc1 
ir-user-click [timer] heartbeat backlight default-on rfkill0 mmc2 rfkill1 rfkill2
```


## MIPI CSI 使用
### 简介

AIO-3399PRO-JD4 开发板分别带有两个MIPI，MIPI最高支持支持4K拍照，并支持1080P 30FPS以上视频录制。此外，开发板还支持 USB 摄像头。

本文以 OV13850 摄像头为例，讲解在该开发板上的配置过程。

### 接口效果图
![](img/mipi_csi.png)

### DTS配置

```
isp0: isp@ff910000 {
    …
    status = "okay";
}
isp1: isp@ff920000 {
    …
    status = "okay";
}
```
### 驱动说明
与摄像头相关的代码目录如下：
```
Android：
 `- hardware/rockchip/camera/
    |- CameraHal             // 摄像头的 HAL 源码
    `- SiliconImage          // ISP 库，包括所有支持模组的驱动源码
       `- isi/drv/OV13850    // OV13850 模组的驱动源码
          `- calib/OV13850.xml // OV13850 模组的调校参数
 `- device/rockchip/rk3399/   
    |- rk3399_firefly_aio_box
    |  `- cam_board.xml      // 摄像头的参数设置

 Kernel：
 |- kernel/drivers/media/video/rk_camsys  // CamSys 驱动源码
 `- kernel/include/media/camsys_head.h
```

### 配置原理

设置摄像头相关的引脚和时钟，即可完成配置过程。

从以下摄像头接口原理图可知，需要配置的引脚有：CIF_PWR、DVP_PWR和MIPI_RST。

* mipi接口
![](img/mipi_csi1.png)

* DVP_PWR 对应 RK3399 的 GPIO1_C1;
* CIF_PWR 对应 RK3399 的 GPIO1_A1;
* MIPI_RST 对应GPIO0_B0;

在开发板中，这三个引脚都是在 cam_board.xml 中设置。

### 配置步骤
#### 配置 Android
修改device/rockchip/rk3399/XXX_PRODUCT/cam_board.xml 来注册摄像头：

```
<BoardFile>
<BoardXmlVersion version="v0.0xf.0"></BoardXmlVersion>
<CamDevie>
<HardWareInfo>
<Sensor>
<SensorName name="OV13850"/>
<SensorLens name="50013A1"/>
<SensorDevID IDname="CAMSYS_DEVID_SENSOR_1B"/>
<SensorHostDevID busnum="CAMSYS_DEVID_MARVIN"/>
<SensorI2cBusNum busnum="1"/>
<SensorI2cAddrByte byte="2"/>
<SensorI2cRate rate="100000"/>
<SensorAvdd name="NC" min="28000000" max="28000000" delay="0"/>
<SensorDvdd name="NC" min="12000000" max="12000000" delay="0"/>
<SensorDovdd name="NC" min="18000000" max="18000000" delay="5000"/>
<SensorMclk mclk="24000000" delay="1000"/>
<SensorGpioPwen ioname="RK30_PIN1_PC1" active="1" delay="1000"/>
<SensorGpioRst ioname="RK30_PIN0_PB0" active="0" delay="1000"/>
<SensorGpioPwdn ioname="RK30_PIN2_PA1" active="0" delay="0"/>
<SensorFacing facing="back"/>
<SensorInterface interface="MIPI"/>
<SensorMirrorFlip mirror="0"/>
<SensorOrientation orientation="180"/>
<SensorPowerupSequence seq="1234"/>
<SensorFovParemeter h="60.0" v="60.0"/>
<SensorAWB_Frame_Skip fps="15"/>
<SensorPhy phyMode="CamSys_Phy_Mipi" lane="2" phyIndex="0" sensorFmt="CamSys_Fmt_Raw_10b"/>
</Sensor>
<VCM>
<VCMDrvName name="DW9714"/>
<VCMName name="HuaYong6505"/>
<VCMI2cBusNum busnum="1"/>
<VCMI2cAddrByte byte="0"/>
<VCMI2cRate rate="0"/>
<VCMVdd name="NC" min="0" max="0" delay="0"/>
<VCMGpioPower ioname="NC" active="0" delay="1000"/>
<VCMGpioPwdn ioname="NC" active="0" delay="0"/>
<VCMCurrent start="20" rated="80" vcmmax="100" stepmode="13" drivermax="100"/>
</VCM>
<Flash>
<FlashName name="Internal"/>
<FlashI2cBusNum busnum="0"/>
<FlashI2cAddrByte byte="0"/>
<FlashI2cRate rate="0"/>
<FlashTrigger ioname="NC" active="0"/>
<FlashEn ioname="NC" active="0"/>
<FlashModeType mode="1"/>
<FlashLuminance luminance="0"/>
<FlashColorTemp colortemp="0"/>
</Flash>
</HardWareInfo>
<SoftWareInfo>
<AWB>
<AWB_Auto support="1"/>
<AWB_Incandescent support="1"/>
<AWB_Fluorescent support="1"/>
<AWB_Warm_Fluorescent support="1"/>
<AWB_Daylight support="1"/>
<AWB_Cloudy_Daylight support="1"/>
<AWB_Twilight support="1"/>
<AWB_Shade support="1"/>
</AWB>
<Sence>
<Sence_Mode_Auto support="1"/>
<Sence_Mode_Action support="1"/>
<Sence_Mode_Portrait support="1"/>
<Sence_Mode_Landscape support="1"/>
<Sence_Mode_Night support="1"/>
<Sence_Mode_Night_Portrait support="1"/>
<Sence_Mode_Theatre support="1"/>
<Sence_Mode_Beach support="1"/>
<Sence_Mode_Snow support="1"/>
<Sence_Mode_Sunset support="1"/>
<Sence_Mode_Steayphoto support="1"/>
<Sence_Mode_Pireworks support="1"/>
<Sence_Mode_Sports support="1"/>
<Sence_Mode_Party support="1"/>
<Sence_Mode_Candlelight support="1"/>
<Sence_Mode_Barcode support="1"/>
<Sence_Mode_HDR support="1"/>
</Sence>
<Effect>
<Effect_None support="1"/>
<Effect_Mono support="1"/>
<Effect_Solarize support="1"/>
<Effect_Negative support="1"/>
<Effect_Sepia support="1"/>
<Effect_Posterize support="1"/>
<Effect_Whiteboard support="1"/>
<Effect_Blackboard support="1"/>
<Effect_Aqua support="1"/>
</Effect>
<FocusMode>
<Focus_Mode_Auto support="1"/>
<Focus_Mode_Infinity support="1"/>
<Focus_Mode_Marco support="1"/>
<Focus_Mode_Fixed support="1"/>
<Focus_Mode_Edof support="1"/>
<Focus_Mode_Continuous_Video support="0"/>
<Focus_Mode_Continuous_Picture support="1"/>
</FocusMode>
<FlashMode>
<Flash_Mode_Off support="1"/>
<Flash_Mode_On support="1"/>
<Flash_Mode_Torch support="1"/>
<Flash_Mode_Auto support="1"/>
<Flash_Mode_Red_Eye support="1"/>
</FlashMode>
<AntiBanding>
<Anti_Banding_Auto support="1"/>
<Anti_Banding_50HZ support="1"/>
<Anti_Banding_60HZ support="1"/>
<Anti_Banding_Off support="1"/>
</AntiBanding>
<HDR support="1"/>
<ZSL support="1"/>
<DigitalZoom support="1"/>
<Continue_SnapShot support="1"/>
<InterpolationRes resolution="0"/>
<PreviewSize width="1920" height="1080"/>
<FaceDetect support="0" MaxNum="1"/>
<DV>
<DV_QCIF name="qcif" width="176" height="144" fps="10" support="1"/>
<DV_QVGA name="qvga" width="320" height="240" fps="10" support="1"/>
<DV_CIF name="cif" width="352" height="288" fps="10" support="1"/>
<DV_VGA name="480p" width="640" height="480" fps="10" support="0"/>
<DV_480P name="480p" width="720" height="480" fps="10" support="0"/>
<DV_720P name="720p" width="1280" height="720" fps="10" support="1"/>
<DV_1080P name="1080p" width="1920" height="1080" fps="10" support="1"/>
</DV>
</SoftWareInfo>
</CamDevie>
</BoardFile>
```

主要修改的内容如下：

   * Sensor 名称
 ```
<SensorName name="OV13850" ></SensorName>
 ```
该名字必须与 Sensor 驱动的名字一致,目前提供的 Sensor 驱动格式如下：
```
libisp_isi_drv_OV13850.so
```

*  Sensor 软件标识
```
<SensorDevID IDname="CAMSYS_DEVID_SENSOR_1A"></SensorDevID>
```
注册标识不一致即可,可填写以下值：
```
CAMSYS_DEVID_SENSOR_1A
CAMSYS_DEVID_SENSOR_1B
CAMSYS_DEVID_SENSOR_2
```
 
*  采集控制器名称
```
<SensorHostDevID busnum="CAMSYS_DEVID_MARVIN" ></SensorHostDevID>
```
目前只支持：
```
CAMSYS_DEVID_MARVIN
```

*  Sensor 所连接的主控 I2C 通道号
```
<SensorI2cBusNum busnum="1"></SensorI2cBusNum>  
```
具体通道号请参考摄像头原理图连接主控的 I2C 通道号。

*  Sensor 寄存器地址长度,单位：字节
```
<SensorI2cAddrByte byte="2"></SensorI2cAddrByte>
```

*   Sensor 的 I2C 频率,单位：Hz，用于设置 I2C 的频率。
```
<SensorI2cRate rate="100000"></SensorI2cRate>
```

*   Sensor 输入时钟频率, 单位：Hz，用于设置摄像头的时钟。
```
<SensorMclk mclk="24000000"></SensorMclk>
```

*  Sensor AVDD 的 PMU LDO 名称。如果不是连接到 PMU，那么只需填写 NC。
```
<SensorAvdd name="NC" min="0" max="0"></SensorAvdd>
```

*   Sensor DOVDD 的 PMU LDO 名称。
```
<SensorDovdd name="NC" min="18000000" max="18000000"></SensorDovdd>
```

如果不是连接到 PMU，那么只需填写 NC。注意 min 以及 max 值必须填写，这决定了 Sensor 的 IO 电压。

*  Sensor DVDD 的 PMU LDO 名称。
```
<SensorDvdd name="NC" min="0" max="0"></SensorDvdd> 
```

如果不是连接到 PMU，那么只需填写 NC。

*  Sensor PowerDown 引脚。
```
<SensorGpioPwdn ioname="RK30_PIN2_PA1" active="0"></SensorGpioPwdn>
```

直接填写名称即可，active 填写休眠的有效电平。

  *  Sensor Reset 引脚。
```
<SensorGpioRst ioname="RK30_PIN3_PB0" active="0"></SensorGpioRst>
```

直接填写名称即可，active 填写复位的有效电平。

  *  Sensor Power 引脚。
```
<SensorGpioPwen ioname="RK30_PIN1_PC1" active="1"></SensorGpioPwen>
```

直接填写名称即可, active 填写电源有效电平。

*    选择 Sensor 作为前置还是后置。
```
<SensorFacing facing="front"></SensorFacing>
```

可填写 "front" 或 "back"。

 *  Sensor 的接口方式
```
<SensorInterface mode="MIPI"></SensorInterface>
```

可填写如下值：
```
CCIR601
CCIR656
MIPI
SMIA
```
 
*  Sensor 的镜像方式
```
<SensorMirrorFlip mirror="0"></SensorMirrorFlip>
```
目前暂不支持。

*  Sensor 的角度信息
```
<SensorOrientation orientation="0"></SensorOrientation>
```

*  物理接口设置
      
MIPI
```
<SensorPhy phyMode="CamSys_Phy_Mipi" lane="2" phyIndex="0" sensorFmt="CamSys_Fmt_Raw_10b"></SensorPhy>
```
hyMode：Sensor 接口硬件连接方式，对 MIPI Sensor 来说，该值取 "CamSys_Phy_Mipi"
Lane：Sensor mipi 接口数据通道数
Phyindex：Sensor mipi 连接的主控 mipi phy 编号
sensorFmt：Sensor 输出数据格式,目前仅支持 CamSys_Fmt_Raw_10b


编译内核需将 drivers/media/video/rk_camsys 驱动源码编进内核，其配置方法如下：

在内核源码目录下执行命令：
```
make menuconfig
```
然后将以下配置项打开：
```
Device Drivers  --->
 Multimedia support  --->
        camsys driver
         RockChip camera system driver  --->
                   camsys driver for marvin isp
                   camsys driver for cif
```
最后执行：
```
make ARCH=arm64 rk3399-firefly-aio.img
```
即可完成内核的编译。

### 调试方法

终端下可以直接修改/system/etc/cam_board.xml调试各参数并重启生效
### FAQs

1.无法打开摄像头，首先确定sensor I2C是否通信。若不通则可检查mclk以及供电是否正常（Power/PowerDown/Reset/Mclk/I2cBus）分别排查
2.支持列表ː
13Mː OV13850/IMX214-0AQH5
8Mː OV8825/OV8820/OV8858-Z(R1A)/OV8858-R2A
5Mː OV5648/OV5640
2Mː OV2680
详细资料可查询SDK/RKDocs


## PWM 使用

### 前言

AIO-3399PRO-JD4开发板上引出有 3 路 PWM 输出，分别为：
* PWM0 屏背光
* PWM2 VDDLOG供电
* PWM3 红外IR

本章主要描述如何配置 PWM。

RK3399的 PWM 驱动为： kernel/drivers/pwm/pwm-rockchip.c
### DTS配置

配置 PWM 主要有以下三大步骤：配置 PWM DTS 节点、配置 PWM 内核驱动、控制 PWM 设备。
#### 配置 PWM DTS节点

在 DTS 源文件kernel/arch/arm64/boot/dts/rockchip/rk3399-firefly-demo.dtsi 添加 PWM DTS 配置，如下所示：
```
pwm_demo: pwm_demo {   
   status = "okay";   
   compatible = "firefly,rk3399-pwm";   
   pwm_id = <1>;   
   min_period = <0>;   
   max_period = <10000>;   
   duty_ns = <5000>;   
};
```

* pwm_id：需要申请的pwm通道数。
* min_period：周期时长最小值。
* max_period：周期时长最大值。
* duty_ns：pwm 的占空比激活的时长，单位 ns。

### 接口说明

用户可在其它驱动文件中使用以上步骤生成的 PWM 节点。具体方法如下：

(1)、在要使用 PWM 控制的设备驱动文件中包含以下头文件：  
```
#include <linux/pwm.h>
```
该头文件主要包含 PWM 的函数接口。

(2)、申请 PWM  
使用
```
struct pwm_device *pwm_request(int pwm_id, const char *label);
```
函数申请 PWM。 例如：
```
struct pwm_device * pwm1 = NULL;pwm0 = pwm_request(1, “firefly-pwm”);
```

(3)、配置 PWM  
使用  
```
int pwm_config(struct pwm_device *pwm, int duty_ns, int period_ns);
```
配置 PWM 的占空比，
例如：
```
pwm_config(pwm0, 500000, 1000000)；
```

(4)、使能PWM   函数  
```
int pwm_enable(struct pwm_device *pwm);
```
用于使能 PWM，例如：  
```
pwm_enable(pwm0);
```

(5)控制 PWM 输出主要使用以下接口函数：  
```
struct pwm_device *pwm_request(int pwm_id, const char *label);
```

* 功能：用于申请 pwm

```
void pwm_free(struct pwm_device *pwm);
```

*  功能：用于释放所申请的 pwm  

```
int pwm_config(struct pwm_device *pwm, int duty_ns, int period_ns);
```

* 功能：用于配置 pwm 的占空比  

```
int pwm_enable(struct pwm_device *pwm);
```

* 功能：使能 pwm  

```
void pwm_disable(struct pwm_device *pwm);
```

* 功能：禁止 pwm  


参考Demo：kernel/drivers/pwm/pwm-firefly.c

### 调试方法

通过内核丰富的debug接口查看pwm注册状态，adb shell或者串口进入android终端
cat  /sys/kernel/debug/pwm  ---注册是否成功，成功则返回接口名和寄存器地址
### FAQs

###### Pwm无法注册成功：
* dts配置文件是否打开对应的pwm。
* pwm所在的io口是否被其他资源占用，可以根据报错的返回值去查看原因。


## SPI 使用

SPI是一种高速的，全双工，同步串行通信接口，用于连接微控制器、传感器、存储设备等。
AIO-3399PRO-JD4 SPI引出来了一路SPI2(可复用GPIO)给外部使用。
AIO-3399PRO-JD4 开发板提供了 SPI2（单片选）接口，具体位置如下图：
![](img/spi.png)

### SPI工作方式

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

### 驱动编写

下面以 W25Q128FV Flash模块为例简单介绍SPI驱动的编写。
#### 硬件连接

AIO-3399PRO-JD4 与 W25Q128FV 硬件连接如下表：

![](img/spi3.jpg)
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
#### 配置DTS节点

在kernel/arch/arm64/boot/dts/rockchip/rk3399-firefly-demo.dtsi中添加SPI驱动结点描述，如下所示：
```
/* Firefly SPI demo */
&spi2 {
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

#### 定义SPI驱动

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
    .probe = firefly_spi_probe,
};
```
#### 注册SPI设备

在初始化函数static int __init spidev_init(void)中向内核注册SPI驱动： spi_register_driver(&firefly_spi_driver);

如果内核启动时匹配成功，则SPI核心会配置SPI的参数（mode、speed等），并调用firefly_spi_probe。
#### 读写 SPI 数据

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
#### 打开SPI demo

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
#### 常用SPI接口

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
### 接口使用

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
### FAQs
###### Q1: SPI数据传送异常

A1:  确保 SPI 4个引脚的 IOMUX 配置正确， 确认 TX 送数据时，TX 引脚有正常的波形，CLK 频率正确，CS 信号有拉低，mode 与设备匹配。


## TIMER 使用

### 前言

RK3399有12 个Timers (timer0-timer11)，有12 个Secure Timers(stimer0~stimer11) 和 2 个Timers(pmutimer0~pmutimer1)， 我们主要用到的是Timers(timer0-timer11)时钟频率为24MHZ ，工作模式有 free-running 和 user-defined count 模式
### 框架图

![](img/timer1.png)

### 工作模式

user-defined count：Timer 先载入初始值到 TIMERn_LOAD_COUNT3 和 TIMER_LOADn_COUNT2寄存器， 当时间累加的值在寄存器TIMERn_LOAD_COUNT1和TIMERn_LOAD_COUNT0时，将不会自动载入到计数寄存器。 用户需要重新关闭计数器和然后重新设置计数器相关才能继续工作。

free-running：Timer先载入初始值到TIMER_LOAD_COUNT3 和 TIMER_LOAD_COUNT2寄存器， 当时间累加的值在寄存器TIMERn_LOAD_COUNT1和TIMERn_LOAD_COUNT0时，Timer将一直自动加载计数寄存器。

### 软件配置

1.在 dts 文件中定义 Timer 的相关配置 kernel/arch/arm64/boot/dts/rockchip/rk3399.dtsi

```
rktimer: rktimer@ff850000 {
    compatible = "rockchip,rk3399-timer";
    reg = <0x0 0xff850000 0x0 0x1000>;
    interrupts = <GIC_SPI 81 IRQ_TYPE_LEVEL_HIGH 0>;
    clocks = <&cru PCLK_TIMER0>, <&cru SCLK_TIMER00>;
    clock-names = "pclk", "timer";
};
```
其中定义的Timer0 的寄存器和中断号和时钟等

其他Timer 对应的中断号可看如下图片

![](img/timer2.png)

2.对应的驱动文件Kernel/drivers/clocksource/rockchip_timer.c

### 对应寄存器和使用

1.寄存器如下图片

![](img/timer3.png)

2.使用方式 查看对应寄存器
```
rk3399pro_firefly_aiojd4:/ # io -4 0xff85001c  //查看当前控制寄存器的状态                                 
ff85001c:  00000007 
 
rk3399pro_firefly_aiojd4:/ # io -4 0xff850000  //查看寄存器时时的值                                 
ff850000:  0001639f
```
控制对应寄存器
```
root@rk3399_firefly_box:/ # io -4 -w 0xff85001c 0x06  //关闭时间计数功能
```


## UART 使用


### 简介

AIO-3399PRO-JD4 支持SPI桥接/扩展4个增强功能串口(UART)的功能，分别为UART1，UART2，RS232，RS485。每个UART都拥有256字节的FIFO缓冲区，用于数据接收和发送。 其中：

* UART1、UART2为TTL电平接口，RS232为RS232电平接口，RS485为RS485电平接口

* UART1、UART2最高支持波特率691200。RS232、RS485受通讯媒介影响一般只支持115200以下。

* 每个子通道具备收/发独立的256 BYTE FIFO,FIFO的中断可按用户需求进行编程触发点

* 具备子串口接收FIFO超时中断

* 支持起始位错误检测

AIO-3399PRO-JD4开发板的串口接口图如下：

![](img/spi_uart.PNG)

### DTS配置

文件kernel/arch/arm64/boot/dts/rockchip/rk3399-firefly-port.dtsi 有spi转uart相关节点的定义：
```
&spi1 { 
    spi_wk2xxx: spi_wk2xxx@00{ 
    status = "disabled"; 
    compatible = "firefly,spi-wk2xxx"; 
    reg = <0x00>; 
    spi-max-frequency = <10000000>; 
    power-gpio = <&gpio2 4 GPIO_ACTIVE_HIGH>; 
    reset-gpio = <&gpio1 17 3 GPIO_ACTIVE_HIGH>; 
    irq-gpio = <&gpio1 2 IRQ_TYPE_EDGE_FALLING>; 
    cs-gpio = <&gpio1 10 GPIO_ACTIVE_HIGH>; 
    /* rk3399 driver support SPI_CPOL | SPI_CPHA | 			SPI_CS_HIGH */ 
    //spi-cpha;     /* SPI mode: CPHA=1 */ 
    //spi-cpol;     /* SPI mode: CPOL=1 */ 
    //spi-cs-high; 
     }; 
}
```
可以看到，在kernel/arch/arm64/boot/dts/rockchip/rk3399-firefly-aiojd4.dts文件中使能该节点即可使用。另外，由于我们板子使用的spi转uart串口模块挂到spi1上，所以还要使能spi1节点。如下：
```
&spi1 {
    status = "okay";
};          
             
&spi_wk2xxx {
    status = "okay";
};
```
注意：由于spi1_rxd和spi1_txd两个脚可复用为uart4_rx和uart4_tx，所以要留意关闭掉uart4的使用，如下：
```
&uart4 {              
    status = "disabled";
};
```
### 调试方法

配置好串口后，硬件接口对应软件上的节点分别为：
```
RS485：/dev/ttysWK0
RS232：/dev/ttysWK1
UART1：/dev/ttysWK2
UART2：/dev/ttysWK3
```
用户可以根据不同的接口使用不同的主机的 USB 转串口适配器向开发板的串口收发数据，例如RS485的调试步骤如下：

(1) 连接硬件

将开发板RS485 的A、B、GND 引脚分别和主机串口适配器（USB转485转串口模块）的 A、B、GND 引脚相连。

(2) 打开主机的串口终端

在终端打开kermit,并设置波特率：
```
$ sudo kermit
C-Kermit> set line /dev/ttyUSB0
C-Kermit> set speed 9600
C-Kermit> set flow-control none
C-Kermit> connect
```

*  /dev/ttyUSB0 为 USB 转串口适配器的设备文件

(3) 发送数据

RS485 的设备文件为 /dev/ttysWK0。在设备上运行下列命令：
```
echo firefly RS485 test... > /dev/ttysWK0
```
主机中的串口终端即可接收到字符串“firefly RS485 test...”

(4) 接收数据

首先在设备上运行下列命令：
```
cat /dev/ttysWK0
```
然后在主机的串口终端输入字符串 “Firefly RS485 test...”，设备端即可见到相同的字符串。
