# Setup

    apt install virtualenv python-serial

    virtualenv --system-site-packages opt

    ./opt/bin/pip install --upgrade nodemcu-uploader

# Firmware

### 4MB flash

    ./nodemcu-firmware/tools/esptool.py --port /dev/ttyUSB5 write_flash -fm dio -fs 32m 0x00000 images/nodemcu-master-15-modules-2016-08-08-12-51-11-integer.bin 0x3fc000 ~/Downloads/nodemcu/ESP8266_NONOS_SDK_V1.5.4_16_05_20/ESP8266_NONOS_SDK/bin/esp_init_data_default.bin 

