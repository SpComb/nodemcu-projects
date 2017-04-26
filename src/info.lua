-- Software/Hardware
local version_major, version_minor, version_dev, chip_id, flash_id, flash_size, flash_mode, flash_speed = node.info()

print("Version: " .. version_major .. "." .. version_minor .. "." .. version_dev)
print("Flash: id=" .. flash_id .. ", size=" .. flash_size .. ", mode=" .. flash_mode .. ", speed=" .. flash_speed)

-- WIFI
print("WIFI: mode=" .. wifi.getmode() .. ", phymode=" .. wifi.getphymode() .. ", channel=" .. wifi.getchannel())

if wifi.getmode() == wifi.STATION then
    local ssid, password, bssid_set, bssid = wifi.sta.getconfig()
    local status = wifi.sta.status()

    print("WIFI-STA: mac=" .. wifi.sta.getmac() .. ", ssid=" .. ssid .. ", status=" .. status)

    if bssid_set then
        local rssi = wifi.sta.getrssi()

        if rssi == nil then
            rssi = ""
        end

        print("WIFI-STA: bssid=" .. bssid)
    end

    local hostname = wifi.sta.gethostname()
    local address, netmask, gateway = wifi.sta.getip()

    if hostname == nil then
        hostname = ""
    end
    if address == nil then
        address = ""
    end
    if netmask == nil then
        netmask = ""
    end
    if gateway == nil then
        gateway = ""
    end

    print("WIFI-STA: hostname=" .. hostname .. ", address=" .. address .. ", netmask=" .. netmask .. ", gateway=" .. gateway)
end
