
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

## Usage

Connects to the configured WiFi network in STA mode, using DHCP for autoconfiguration.

Implements an ArtNet -> DMX bridge, listening on UDP port 6454.
The second ESP8266 hardware UART is used to output serial DMX data on NodeMCU pin ***D4***.
Connect this pin to a RS-485 transceiver (SN75176B), wired to an output XLR connector.

Supports the Art-Net [Discovery](http://art-net.org.uk/?page_id=454), [Subscription](http://art-net.org.uk/?page_id=649) and [Streaming](http://art-net.org.uk/?page_id=456) protocols for both unicast and broadcast packets.

### Art-Net

Supported protocol features:

* Receiving [`ArtPoll`](http://art-net.org.uk/?page_id=575) packets
* Sending (unicast) [`ArtPollReply`](http://art-net.org.uk/?page_id=575) packets
  * These should be broadcast, but the NodeMCU net module does not allow that
* Receiving [`ArtDmx`](http://art-net.org.uk/?page_id=675) packets
* Optional stream sequencing to skip duplicated/reordered packets.
  * Packets having a non-zero `ArtDmx.Sequence` field
* Outputting DMX for the configured Art-Net universe
  * Configured for a single output port on universe 0

## TODO

The Art-Net node is hardcoded for a specific Art-Net universe (0).
Support [`ArtAddress`](http://art-net.org.uk/?page_id=900) for dynamic configuration.
