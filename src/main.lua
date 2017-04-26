dofile("src/wifi.lua")

app = {
    version = 0x0002,
    running = false,
}

function app.init()
  print("app.init: pre heapsize=" .. node.heap())
  if ARTNET then
    dofile("src/artnet.lua")
  end
  if ATX_PSU then
    dofile("src/atx_psu.lua")
  end
  if DMX then
    dofile("src/dmx.lua")
  end
  if P9813 then
    dofile("src/p9813.lua")
  end
  if PUBSUB then
    dofile("src/pubsub.lua")
  end
  if DS18B20 then
    dofile("src/ds18b20.lua")
  end
  print("app.init: post heapsize=" .. node.heap())
end

function app.start()
  if ARTNET then
    artnet.init({
      universe  = ARTNET_UNIVERSE,
      version   = app.version,
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
      artnet.patch_output(DMX_ARTNET_ADDR, dmx, "DMX")
    end
  end

  if P9813 then
    p9813.spi = P9813_SPI
    p9813.init()

    if ARTNET and P9813_ARTNET_ADDR then
      artnet.patch_output(P9813_ARTNET_ADDR, p9813, "P9813")
    end
  end

  if PUBSUB then
    pubsub.init({
        node        = wifi.sta.gethostname(),
        server      = PUBSUB_MQTT_SERVER
    })
    pubsub.start()
  end

  if DS18B20 then
    ds18b20.init()

    if PUBSUB then
      pubsub.register_module("ds18b20", function()
        return {
          Devices     = ds18b20.list_devices()
        }
      end)

      ds18b20.start(function(device, temp)
          pubsub.publish_module("ds18b20", device, {
              Node            = pubsub.node_id,
              Device          = device,
              Temperature_16  = temp
          })
      end)
    end
  end

  print("app.start: post heapsize=" .. node.heap())

  return true
end

function app.stop()
    return false
end

function main(event)
    if event == "init" then
        app.init()
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
