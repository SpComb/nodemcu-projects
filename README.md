
## Firmware

### DMX

The `src/dmx.lua` module requires a patched nodemcu-firmware for DMX output on UART2 (NodeMCU pin ***D4***, `GPIO2`, `TXD1`) at 250/125 kbaud: https://github.com/SpComb/nodemcu-firmware/tree/dmx-uart2

### Flashing a ESP-12E with 4MiB flash

    nodemcu-firmware $ ./tools/esptool.py --port /dev/ttyUSB5 write_flash -fm dio -fs 32m 0x00000 bin/nodemcu_integer_build_1.5.4.1_20161001+qmsk-dmx_1_20161016-1741.bin 0x3fc000 ~/Downloads/ESP8266_NONOS_SDK_V1.5.4.1_patch_20160704/esp_init_data_default.bin

## Configure

### `etc/config.lua`

    WIFI_SSID = "..."
    WIFI_PSK = "..."

## Setup

### Install nodemcu-uploader
    apt install virtualenv python-serial

    virtualenv --system-site-packages opt

    ./opt/bin/pip install --upgrade nodemcu-uploader

### Upload

    ./opt/bin/nodemcu-uploader --port /dev/ttyUSB5 upload etc/*.lua src/*.lua

## Running

    ./opt/bin/nodemcu-uploader --port /dev/ttyUSB5 exec init.lua
