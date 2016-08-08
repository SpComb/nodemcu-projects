function wifi_sta()
    print("wifi:sta: ssid=" .. WIFI_SSID)

    wifi.eventmon.register(wifi.eventmon.STA_CONNECTED, function(event)
        print("wifi:sta: Connected " .. event.SSID ..": " .. event.BSSID .. "@" .. event.channel)

        main("wifi-connected")
    end)

    wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, function(event)
        print("wifi:sta: Configured: " .. event.IP .. "/" .. event.netmask .. " gateway=" .. event.gateway)
        
        main("wifi-configured")
    end)

    wifi.eventmon.register(wifi.eventmon.STA_DHCP_TIMEOUT, function(event)
        print("wifi:sta: Configuration error: DHCP timeout")
        
        main("wifi-error")
    end)

    wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED, function(event)
        print("wifi:sta: Connect " .. event.SSID .. " error: bssid=" .. event.BSSID .. " reason=" .. event.reason)
        
        main("wifi-disconnected")
    end)

    wifi.setmode(wifi.STATION)
    wifi.sta.config(WIFI_SSID, WIFI_PASSWORD, 1)
end
