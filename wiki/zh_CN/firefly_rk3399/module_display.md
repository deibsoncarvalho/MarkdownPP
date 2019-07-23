# 屏幕模组

## 7.85寸EDP液晶屏模组

###  产品参数
* 型号：LP079QX1
* 尺寸：7.85寸
* 分辨率：2048x1563
* 显示接口：EDP
* 面板材料：IPS面板
* 可视角度：160°
* 触摸屏：多点电容触摸
### 参考固件

注意：
支持7.85寸屏的官方固件名带有“EDP785”字样，下面是固件的链接：
[固件链接](https://pan.baidu.com/s/1bA70M6#list/path=%2F)
### 编译命令

用官网SDK编译支持的7.85寸屏的固件时需用如下编译命令：

* Android 7.1
```
  ./FFTools/make.sh -j8 -d rk3399-firefly-edp -l rk3399_firefly_edp_box-userdebug
  ./FFTools/mkupdate/mkupdate.sh -l rk3399_firefly_edp_box-userdebug
```
### 技术资料
[7.85寸屏幕模组DataSheet、底板原理图](https://pan.baidu.com/s/1mhXH4fu#list/path=%2F)
### 实物图
![](img/module_display1.jpg)
### 连接方法
![](img/module_display2.jpg)

## 7.85寸MIPI液晶屏模组
### 产品参数

* 型号：B080XAN01
* 尺寸：7.85寸
* 分辨率：1024x768
* 显示接口：MIPI
* 面板材料：IPS面板
* 可视角度：160°
* 触摸屏：多点电容触摸
### 参考固件
注意：
支持7.85寸屏的官方固件名带有“MIPI785”字样，下面是固件的链接：
[固件链接](https://pan.baidu.com/s/1slNUe8P#list/path=%2F)
### 编译命令

用官网SDK编译支持的7.85寸屏的固件时需用如下编译命令：

*    Android 7.1

```
  ./FFTools/make.sh -j8 -d rk3399-firefly-mipi -l rk3399_firefly_mipi_box-userdebug
  ./FFTools/mkupdate/mkupdate.sh -l rk3399_firefly_mipi_box-userdebug
```
### 实物图
![](img/module_display3.jpg)