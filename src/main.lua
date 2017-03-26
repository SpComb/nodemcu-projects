dofile("src/atx_psu.lua")
dofile("src/artnet.lua")
dofile("src/dmx.lua")
dofile("src/p9813.lua")
dofile("src/wifi.lua")

app = {
    version = 0x0001,
    running = false,

    atx_psu = APP_ATX_PSU,
    dmx     = APP_DMX,
    p9813   = APP_P9813,
    artnet  = APP_ARTNET,
}

p9813.spi = 1

function app.start()
  if app.atx_psu then
    atx_psu.init()
  end

  if app.dmx then
    dmx.init()
  end

  if app.p9813 then
    p9813.init()
    p9813.test()
  end

  if app.artnet then
    artnet.init(dmx)
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
