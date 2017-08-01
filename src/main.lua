app = {
    version = 0x0002,
    running = false,
}

dofile("src/wifi.lua")
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
if ADXL345 then
  dofile("src/adxl345.lua")
end
if APA102 then
  dofile("src/apa102.lua")
end

function app.init()
  print("app.init: heapsize=" .. node.heap())
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
    p9813.init({
      layout  = P9813_LAYOUT,
    })

    if ARTNET and P9813_ARTNET_ADDR then
      artnet.patch_output(P9813_ARTNET_ADDR, p9813.artnet_dmx, "P9813")
    end
  end

  if APA102 then
    apa102.init()

    if ARTNET and APA102.artnet_addr then
      artnet.patch_output(APA102.artnet_addr, apa102.send_dmx, "APA102")
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
              Temperature     = temp
          })
      end)
    end
  end

  if ADXL345 then
    adxl345.init()
    adxl345.config(ADXL345)

    adxl345.start({
      activity = function()
        local x, y, z = adxl345.read_xyz()

        print(string.format("ADXL345 activity: X=%+6d Y=%+6d Z=%+6d", x, y, z))
      end,
    })
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
