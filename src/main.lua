dofile("src/atx_psu.lua")
dofile("src/artnet.lua")
dofile("src/dmx.lua")
dofile("src/p9813.lua")
dofile("src/wifi.lua")

app = {
    version = 0x0001,
    running = false,
}

function app.start()
  if ARTNET then
    artnet.init(dmx, {
      universe  = ARTNET_UNIVERSE,
    })
  end

  if ATX_PSU then
    atx_psu.gpio = ATX_PSU_GPIO
    atx_psu.init()
    atx_psu.on()
  end

  if DMX then
    dmx.init()

    if ARTNET and DMX_ARTNET_ADDR then
      artnet.patch_output(DMX_ARTNET_ADDR, dmx)
    end
  end

  if P9813 then
    p9813.spi = P9813_SPI
    p9813.init()

    if ARTNET and P9813_ARTNET_ADDR then
      artnet.patch_output(P9813_ARTNET_ADDR, p9813)
    end
  end

  return true
end

function app.stop()
    return false
end

function main(event)
    if event == "init" then
        print("main: wifi setup")
        wifi_client.init()
    elseif event == "wifi-configured" then
        if app.start and not app.running then
            print("main: app.start")
            app.running = app.start()
        end
    elseif event == "wifi-disconnected" then
        if app.stop and app.running then
            print("main: app.stop")
            app.running = app.stop()
        end
    else

    end
end
