.. {{board_name}} Manual documentation master file, created by
   sphinx-quickstart on Wed May 3 14:17:57 2018.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.
Welcome to {{board_name}} Manual
=====================================
.. toctree::
   :glob:
   :maxdepth: 2
   :caption: 上手教程

   started
   debug

.. toctree::
   :glob:
   :maxdepth: 2
   :caption: 烧写固件

   bootmode
   upgrade_table
   upgrade_firmware
   maskrom_mode

.. toctree::
   :glob:
   :maxdepth: 2
   :caption: Linux开发
   
   linux_build_ubuntu_rootfs.md  
   linux_compile_gpt.md
   ubuntu_support.md
   buildroot_compile

.. toctree::
   :glob:
   :maxdepth: 2
   :caption: Android开发
   
   adb_use
{% if board_name == "Firefly-RK3399" or board_name == "AIO-3399J" or board_name == "AIO-3399C" %}
   compile_android_firmware
{% endif %}
   compile_android8.1_firmware
   customize_android_firmware
   
.. toctree::
   :glob:
   :maxdepth: 2
   :caption: 驱动开发
   
   driver_adc
   driver_gpio
   driver_i2c
   driver_ir
   driver_lcd
   driver_led

{% if board_name == "Firefly-RK3399" %}
   driver_camera
   driver_rtc
{% endif %}

{% if board_name == "AIO-3399J" %}
   driver_mipi_csi
   driver_rtc
{% endif %}

{% if board_name == "AIO-3399C" %}
   driver_rtc
{% endif %}

{% if board_name == "AIO-3399PRO-JD4" %}
   driver_mipi_csi
{% endif %}

   driver_pwm
   driver_spi
   driver_timer
   driver_uart

.. toctree::
   :glob:
   :maxdepth: 2
   :caption: 配件

   module_transform
   module_display
   module_camera
   module_wireless
   module_power_adapter
   module_ir 
   module_cooling
   
.. toctree::
   :glob:
   :maxdepth: 2
   :caption: 其他
   
   uboot_introduction

.. toctree::
   :glob:
   :maxdepth: 2
   :caption: 常见问题解答

   faqs

.. toctree::
   :glob:
   :maxdepth: 2
   :caption: 硬件资料
   
   interface_definition
   hardware_doc