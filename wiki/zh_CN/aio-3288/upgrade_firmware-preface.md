# 升级统一固件须知（重要）
<font color=#ff0000 size=4>以下内容仅针对“烧写统一固件”,若烧写分区镜像，可跳过阅读。</font>
## 前言
许多用户在烧写统一固件时，常常会出现“测试设备失败”，“烧写固件失败”等情况，是因为没有选择对相应的工具，下面将介绍：在烧写固件时，正确的选择对应的工具。

## 准备工作
### 固件下载
* [Ubuntu16.04 GPT固件](https://pan.baidu.com/s/1mo44_kSMAIZq95GVFUR2IQ#list/path=%2FPublic%2FDevBoard%2FFirefly-RK3288%2FFirmware%2FAIO-3288C%2FUbuntu%2FGPT&parentPath=%2FPublic%2FDevBoard%2FFirefly-RK3288%2FFirmware%2FAIO-3288C)
* [Ubuntu16.04 MBR固件](https://pan.baidu.com/s/1mo44_kSMAIZq95GVFUR2IQ#list/path=%2FPublic%2FDevBoard%2FFirefly-RK3288%2FFirmware%2FAIO-3288C%2FUbuntu%2FMBR&parentPath=%2FPublic%2FDevBoard%2FFirefly-RK3288%2FFirmware%2FAIO-3288C)
* [android5.1](http://www.t-firefly.com/doc/download/page/id/51.html#other_127)
### 工具下载
* Windows工具：[AndroidTool](http://www.t-firefly.com/doc/download/page/id/51.html#windows_22)
* Linux工具：[upgrade_tool](http://www.t-firefly.com/doc/download/page/id/51.html#linux_22)
### 设备模式
* [如何进入Loader模式](bootmode.html)
* [如何进入Maskrom模式](maskrom_mode.html)
    
    提醒：一般情况下，推荐用烧写工具让板子进入Maskrom模式，若工具无法进入Maskrom模式，再参考该链接。

## 烧写Android固件须知
烧写Android统一固件时，请仔细阅读表格：
![](img/win_upgrade_android.png)

重点说明：在Windows下，Ubuntu16.04 升级 Android5.1 时，如何进入Maskrom模式:

**步骤如下:**
1. 用AndroidTool_v2.58工具，点击“擦除flash”，这步的作用是“擦除IDB”，但无法擦除flash，因此会出现“擦除flash失败”的情况。
2. 按下“reset”键，让板子重新启动；
3. 用AndroidTool_v2.35工具，点击“擦除flash”，现在才是真正的“擦除flash”。
4. 点击“升级”，开始烧写Android5.1固件。

<font color=#ff0000 size=3>提示：若有用户在使用AndroidTool_v2.35工具时，点击“擦除flash”和“升级”都会出现“测试设备失败”的情况下，换AndroidTool_v2.47版本工具。</font>

## 烧写Ubuntu16.04 GPT固件须知
烧写Ubuntu16.04 GPT统一固件时，请仔细阅读表格：
![](img/win_upgrade_GPT.png)

重点说明：

一、在Windows下，Ubuntu16.04 MBR或Android5.1 升级 Ubuntu16.04 GPT，如何进入Maskrom模式：

**步骤如下：**
1. 用AndroidTool_v2.58工具，点击“擦除flash”，完成后，设备自动进入Maskrom模式。
2. 点击“升级”，开始烧写Ubuntu16.04 GPT固件

二、在Linux下，Ubuntu16.04 MBR或Android5.1 升级 Ubuntu16.04 GPT，如何进入Maskrom模式：

**步骤如下：**
```
1. 用upgrade_tool_v1.24工具，要进行擦出flash，则运行：

    sudo upgrade_tool_v1.24 ef /path/Ubuntu16.04 GPT(固件路径)

2. 上述完成后，用upgrade_tool_v1.34工具，烧写Ubuntu16.04 GPT固件，运行以下：

    sudo upgrade_tool_v1.34 uf /path/Ubuntu16.04 GPT(固件路径)
```

## 烧写Ubuntu16.04 MBR固件须知
烧写Ubuntu16.04 MBR统一固件时，请仔细阅读表格：
![](img/win_upgrade_mbr.png)

在上述表格中，都是进入Loader模式下，正常升级。

## 结束语
具体的升级方法，还需看[《Android 升级固件》](upgrade_firmware-android.html)和[《Linux 升级固件》](upgrade_firmware-linux.html)。
