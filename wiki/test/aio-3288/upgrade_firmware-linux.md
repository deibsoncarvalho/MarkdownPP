# Linux 升级固件

## 前言

<font color=#ff0000 size=4>本文以下内容仅适用于Linux系统，若需要升级Android系统，参考[Android 升级固件](upgrade_firmware-android.html)</font>

本文介绍了如何将主机上的固件文件，通过 USB 双公头数据线，烧录到开发板的闪存中。升级时，需要根据主机操作系统和固件类型来选择合适的升级方式。
## 准备工作
* AIO-3288C 开发版
* 主机
* 良好的 USB 双公头线
* 固件

**注：固件文件一般有两种:**
* 单个统一固件 update.img, 将启动加载器、参数和所有分区镜像都打包到一起，用于固件发布。
* 多个分区镜像,如 kernel.img, boot.img, recovery.img 等，在开发阶段生成。 

**注：主机操作系统支持：**
* Windows XP （32/64位）
* Windows 7 (32/64位)
* Windows 8 (32/64位)
* Linux (32/64位)

### 连接设备
**有两种方法可以使设备进入升级模式**  
* 一种方式是断开电源适配器
1. 双公头 USB 数据线连接好设备和主机。
2. 按住设备上的 RECOVERY （恢复）键并保持
3. 插上电源
4. 大约两秒钟后，松开 RECOVERY 键。

主机应该会提示发现新硬件并配置驱动。打开设备管理器，会见到新设备"Rockusb Device" 出现，如下图。如果没有，则需要返回上一步重新安装驱动。
![](img/upgrade_firmware2.png)


### 固件下载：
* [Ubuntu16.04 GPT固件](https://pan.baidu.com/s/1mo44_kSMAIZq95GVFUR2IQ#list/path=%2FPublic%2FDevBoard%2FFirefly-RK3288%2FFirmware%2FAIO-3288C%2FUbuntu%2FGPT&parentPath=%2FPublic%2FDevBoard%2FFirefly-RK3288%2FFirmware%2FAIO-3288C)
* [Ubuntu16.04 MBR固件](https://pan.baidu.com/s/1mo44_kSMAIZq95GVFUR2IQ#list/path=%2FPublic%2FDevBoard%2FFirefly-RK3288%2FFirmware%2FAIO-3288C%2FUbuntu%2FMBR&parentPath=%2FPublic%2FDevBoard%2FFirefly-RK3288%2FFirmware%2FAIO-3288C)

### 工具下载：
1. Windows工具：[AndroidTool](http://www.t-firefly.com/doc/download/page/id/51.html#windows_22)
```    
    提示：AndroidTool_v2.35版本：升级MBR分区的Ubuntu固件    
         AndroidTool_v2.58版本：升级GPT分区的Ubuntu固件
```
2. Linux工具：[upgrade_tool](http://www.t-firefly.com/doc/download/page/id/51.html#linux_22)
```    
    提示：upgrade_tool_v1.24版本：升级MBR分区的Ubuntu固件    
         upgrade_tool_v1.34版本：升级GPT分区的Ubuntu固件
```                    

以下，将以Ubuntu16.04 GPT的烧录为例。
## Windows升级

### 烧写统一固件 
<font color=#ff0000 size=3>提示：建议先阅读[《升级统一固件须知(重要)》](upgrade_firmware-preface.html),并按照“须知”内容进行工具的选择和操作</font>
**步骤如下:**  
1. 切换至"升级固件"页。
2. 按"固件"按钮，打开要升级的固件文件。升级工具会显示详细的固件信息
3. 按"升级"按钮开始升级。
4. 如果升级失败，可以尝试先按"擦除Flash"按钮来擦除 Flash，然后再升级。

<font color=#ff0000 size=3>注意：如果你烧写的固件laoder版本与原来的机器的不一致，请在升级固件前先执行”擦除Flash”。</font>
![](img/win_tool_upgrade.png)

### 烧写分区映像
**步骤如下：**  
1. 切换至"下载镜像"页。
2. 勾选需要烧录的分区，可以多选。
3. 确保映像文件的路径正确，需要的话，点路径右边的空白表格单元格来重新选择。
4. 点击"执行"按钮开始升级，升级结束后设备会自动重启。
![](img/win_tool_img.png)

## Linux升级
下载Linux工具 Upgrade_Tool 后, 按以下方法安装到系统中，方便调用：
```
 unzip Linux_Upgrade_Tool_v1.34.zip
 cd Linux_Upgrade_Tool
 sudo mv upgrade_tool /usr/local/bin
 sudo chown root:root /usr/local/bin/upgrade_tool
 sudo chmod 0755 /usr/local/bin/upgrade_tool
```
然后根据[此处](http://wiki.t-firefly.com/zh_CN/ROC-RK3328-CC/flash_emmc.html#udev)的说明去添加 `udev`规则。这是为了让普通用户有权限烧写 Rockchip 设备。如果跳过这步，那么所有的烧写命令均需在前面加 `sudo` 才能成功执行。

### 烧写统一固件
<font color=#ff0000 size=3>提示：建议先阅读[《升级统一固件须知(重要)》](upgrade_firmware-preface.html),并按照“须知”内容进行工具的选择和操作</font>
运行以下命令：
```
 sudo upgrade_tool uf /path/firmware(固件路径)
```
如果烧写失败，先尝试擦出flash，然后再升级。
```
sudo upgrade_tool ef /path/firmware(固件路径)
sudo upgrade_tool uf /path/firmware(固件路径)
```

### 烧写分区镜像
烧写分区镜像时，GPT分区和MBR分区有不相同的命令参数，因此区分开：

GPT分区使用以下列表：
```
sudo upgrade_tool ul $LOADER
sudo upgrade_tool di -p $PARAMETER
sudo upgrade_tool di -uboot $UBOOT
sudo upgrade_tool di -trust $TRUST
sudo upgrade_tool di -b $BOOT
sudo upgrade_tool di -r $RECOVERY
sudo upgrade_tool di -m $MISC
sudo upgrade_tool di -oem $OEM
sudo upgrade_tool di -userdata $USERDATA
sudo upgrade_tool di -rootfs $ROOTFS
```

MBR分区使用以下列表：
```
 sudo upgrade_tool ul bootloader.bin                    # 烧写 bootloader
 sudo upgrade_tool di -p paramater                      # 烧写 parameter
 sudo upgrade_tool di resource /path/to/resource.img
 sudo upgrade_tool di -r /path/to/recovery.img
 sudo upgrade_tool di -m /path/to/misc.img
 sudo upgrade_tool di -b /path/to/boot.img
 sudo upgrade_tool di -k /path/to/kernel.img
 sudo upgrade_tool di -s /path/to/system.img
```
如果因 flash 问题导致升级时出错，可以尝试低级格式化、擦除 nand flash：
```
 sudo upgrade_tool lf   # 低级格式化
 sudo upgrade_tool ef   # 擦除
```
## 常见问题
### 如何强行进入 MaskRom 模式
如果板子进入不了 Loader 模式，此时可以尝试强行进入 MaskRom 模式。操作方法见[《如何进入 MaskRom 模式》](maskrom.html)。
