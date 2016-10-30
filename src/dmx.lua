dmx = {
    uart_id   = 1,
    led_gpio  = 0,

    debug     = false,
}

function dmx.init()
    gpio.mode(dmx.led_gpio, gpio.OUTPUT)
    uart.setup(dmx.uart_id, 250000, 8, uart.PARITY_NONE, uart.STOPBITS_2, 0)

    -- initial frame
    dmx.sendValue(0x00, 0)
end

-- Send packet as string
--
-- XXX: first packet is ignored?
function dmx.sendPacket(packet)
    -- start
    gpio.write(dmx.led_gpio, gpio.LOW)
    print("dmx:sendPacket...")

    if dmx.debug then
      for i = 1, #packet do
          print("\t" .. string.format("%02x", packet:byte(i)))
      end
    end

    -- break
    uart.setup(dmx.uart_id, 125000, 8, uart.PARITY_NONE, uart.STOPBITS_2, 0)
    uart.write(dmx.uart_id, string.char(0x00))

    -- packet
    uart.setup(dmx.uart_id, 250000, 8, uart.PARITY_NONE, uart.STOPBITS_2, 0)
    uart.write(dmx.uart_id, packet)

    -- done
    gpio.write(dmx.led_gpio, gpio.HIGH)
    print("dmx:sendPacket done")
end

function dmx.sendCommand(command, data)
  dmx.sendPacket(string.char(command) .. data)
end

-- Send repeated channel
function dmx.sendValue(value, count)
    dmx.sendCommand(0x00, string.rep(string.char(value), count))
end

-- Send table of channels
function dmx.sendChannels(channels)
    local data = ""

    for i, chan in ipairs(channels) do
        data = data .. string.char(chan)
    end

    dmx.sendCommand(0x00, data)
end
