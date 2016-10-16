dmx = {
    uart_id   = 1,
    gpio      = 2,
}

function dmx.init()
    uart.setup(dmx.uart_id, 250000, 8, uart.PARITY_NONE, uart.STOPBITS_2, 0)

    -- initial frame
    dmx.sendValue(0x00, 0)
end

-- Send packet as string
--
-- XXX: first packet is ignored?
function dmx.sendPacket(packet)
    print("dmx:sendPacket: ")

    for i = 1, #packet do
        print("\t" .. string.format("%02x", packet:byte(i)))
    end

    -- break
    uart.setup(dmx.uart_id, 125000, 8, uart.PARITY_NONE, uart.STOPBITS_2, 0)
    uart.write(dmx.uart_id, string.char(0x00))

    -- packet
    uart.setup(dmx.uart_id, 250000, 8, uart.PARITY_NONE, uart.STOPBITS_2, 0)
    uart.write(dmx.uart_id, packet)
end

-- Send repeated channel
function dmx.sendValue(value, count)
    local packet = string.char(0x00) .. string.rep(string.char(value), count)

    dmx.sendPacket(packet)
end

-- Send table of channels
function dmx.sendChannels(channels)
    local packet = string.char(0x00)

    for i, chan in ipairs(channels) do
        packet = packet .. string.char(chan)
    end

    dmx.sendPacket(packet)
end
