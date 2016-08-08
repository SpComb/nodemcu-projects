dofile("src/artnet.lua")
dofile("src/dmx.lua")
dofile("src/wifi.lua")

app = {
    running = false,
}

function app.start() 
    dmx.init()

    artnet.init(dmx)

    return true
end

function app.stop()
    return false
end

function main(event)
    if event == "init" then
        print("main: wifi setup")
        wifi_sta()
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
