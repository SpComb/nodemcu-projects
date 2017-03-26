dofile("src/artnet.lua")
dofile("src/dmx.lua")
dofile("src/wifi.lua")
dofile("src/p9813.lua")

app = {
    version = 0x0001,
    running = false,

    dmx     = false,
    p9813   = true,
    artnet  = false,
}

p9813.spi = 1

function app.start()
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
