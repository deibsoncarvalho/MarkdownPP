# FAQ

## 开机异常并循环重启
可能是电源电流不够，请使用电压为12V，电流为 2.5A~3A 的电源。
## ubuntu 用户名和密码
用户：root 密码：firefly用户：firefly 密码：firefly
## Git 链接地址
[https://bitbucket.org/T-Firefly/firenow-lollipop](https://bitbucket.org/T-Firefly/firenow-lollipop)
## MAC 地址烧写
AIO-3288C 的 MAC 地址可以让用户自己更改，请使用 SDK 下的统一动态库工具 RKTools/windows/UpgradeDllTool_v1.35.zip 烧写 MAC 地址。

## 打开蓝牙设备
仅针对Linux系统，按照不同芯片系列，运行不同的脚本(由本公司所编写)：
* AP6236:
```
bt_load_broadcom_firmware 
```
* AP6212/AP6255/AP6335/AP6356/...
```
enable_bt 
```

## 打开Root权限
Android系统有很多很强大的功能都需要用到root权限，开发者经常在使用的时候遇到权限的问题，
那如何在Firefly平台上开启系统的root权限功能呢？Firefly已在系统添加启动root权限的功能，具体的步骤如下：
1. 在Settgins apk里面找到About device然后点击进去
2. 点击Build number 7次后会提示(you are now a developer)
3. 然后返回上一级点击Developer options选项后，在选项中点击Enable ROOT就打开root权限功能
![](img/android_root.png)
