
# RTC 使用

## 简介

Firefly-RK3399 开发板上有 一个集成于RK808上的RTC(Real Time Clock)，主要功能有时钟，日历，闹钟，周期性中断，双通道32KHz时钟输出。

J2接上CR2032纽扣电池后，可以保证板子掉电后RTC可以正常运行。J2位置如下图：

![](img/rtc.jpg)

## RTC 驱动

DTS配置信息存放于rk808节点

驱动代码路径：drivers/rtc/rtc-rk808.c
## 接口使用

Linux 提供了三种用户空间调用接口。 在 Firefly-RK3399 开发板中对应的路径为：

*    SYSFS接口：/sys/class/rtc/rtc0/

*    PROCFS接口： /proc/driver/rtc

*    IOCTL接口： /dev/rtc0

### SYSFS接口

可以直接使用cat和echo操作/sys/class/rtc/rtc0/下面的接口。

比如查看当前RTC的日期和时间：
```
# cat /sys/class/rtc/rtc0/date
2013-01-18                                                              
#cat /sys/class/rtc/rtc0/time                                            
09:36:10
```
设置开机时间，如设置120秒后开机：
```
#120秒后定时开机
echo +120 >  /sys/class/rtc/rtc0/wakealarm
# 查看开机时间
cat /sys/class/rtc/rtc0/wakealarm
#关机
reboot -p
```
### PROCFS接口

打印RTC相关的信息：
```
# cat /proc/driver/rtc
rtc_time        : 09:34:59
rtc_date        : 2013-01-18
alrm_time       : 08:52:45
alrm_date       : 2013-01-18
alarm_IRQ       : no
alrm_pending    : no
update IRQ enabled      : no
periodic IRQ enabled    : no
periodic IRQ frequency  : 1
max user IRQ frequency  : 64
24hr            : yes
```
### IOCTL接口

可以使用ioctl控制/dev/rtc0。
详细使用说明请参考文档 rtc.txt 。
## FAQs
###### Q1: 开发板上电后时间不同步

A1:  检查一下RTC电池是否正确接入。