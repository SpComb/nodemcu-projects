wifi_client = {
  ssid    = WIFI_SSID,
  psk     = WIFI_PSK,
}

function wifi_client.init()
    print("wifi_client:init ssid=" .. wifi_client.ssid)

    wifi.eventmon.register(wifi.eventmon.STA_CONNECTED, wifi_client.sta_connected)
    wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, wifi_client.sta_got_ip)
    wifi.eventmon.register(wifi.eventmon.STA_DHCP_TIMEOUT, wifi_client.dhcp_timeout)
    wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED, wifi_client.sta_disconnected)

    local wifi_mode = wifi.getmode()

    if wifi_mode == wifi.STATION then
      print("wifi_client:init get mode: " .. wifi_mode)
    else
      print("wifi_client:init set mode: STATION")

      wifi.setmode(wifi.STATION)
    end

    local status = wifi.sta.status()

    local ssid, psk, bssid_set, bssid = wifi.sta.getconfig()

    if not bssid_set then
      bssid = ""
    end

    print("wifi_client:init status=" .. status .. " ssid=" .. ssid .. " bssid=" .. bssid)

    if ssid == wifi_client.ssid and status == wifi.STA_GOTIP then
      print("wifi_client:init configured")

      local ip, netmask, gateway = wifi.sta.getip()

      wifi_client.sta_got_ip({
        IP      = ip,
        netmask = netmask,
        gateway = gateway,
      })
    else
      print("wifi_client:init config: ssid=" .. WIFI_SSID)

      wifi.sta.config(wifi_client.ssid, wifi_client.psk, 1)
    end
end

function wifi_client.sta_connected(event)
  print("wifi_client:connected " .. event.SSID ..": " .. event.BSSID .. "@" .. event.channel)

  main("wifi-connected")
end

function wifi_client.sta_got_ip(event)
   print("wifi_client:configured: " .. event.IP .. "/" .. event.netmask .. " gateway=" .. event.gateway)

   main("wifi-configured")
end

function wifi_client.dhcp_timeout(event)
    print("wifi_client:init Configuration error: DHCP timeout")

    main("wifi-error")
end

function wifi_client.sta_disconnected(event)
    print("wifi_client:init Connect " .. event.SSID .. " error: bssid=" .. event.BSSID .. " reason=" .. event.reason)

    main("wifi-disconnected")
end
