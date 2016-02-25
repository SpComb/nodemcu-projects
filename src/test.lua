version_major, version_minor, version_dev, chip_id, flash_id, flash_size, flash_mode, flash_speed = node.info()

print("Version: " .. version_major .. "." .. version_minor .. "." .. version_dev)

power = {
    gpio    = 1,
}

function power.init()
    gpio.mode(power.gpio, gpio.OUTPUT)
end

function power.on()
    gpio.write(1, gpio.HIGH)
end
function power.off()
    gpio.write(1, gpio.LOW)
end

apa102 = {
    spi     = 1,
}

function apa102.init()
    spi.setup(apa102.spi, spi.MASTER, spi.CPOL_LOW, spi.CPHA_LOW, spi.DATABITS_8, 8);
end

function apa102.write(data)
    local stopbits = string.len(data) / 4

    stopbits = stopbits + stopbits % 32

    local stop = string.rep(string.char(0xff), stopbits / 8)

    return spi.send(1, string.char(0x00, 0x00, 0x00, 0x00) .. data .. stop)
end

function apa102.set_all(count, a, r, g, b)
    local a = bit.bor(0xE0, a)
    return apa102.write(string.rep(string.char(a, b, g, r), count))
end

p9813= {
    spi     = 1,
}

function p9813.init()
    spi.setup(p9813.spi, spi.MASTER, spi.CPOL_LOW, spi.CPHA_LOW, spi.DATABITS_8, 8);
end

function p9813.write(data)
    local stopbits = string.len(data) / 4

    stopbits = stopbits + stopbits % 32

    local stop = string.rep(string.char(0xff), stopbits / 8)

    return spi.send(1, string.char(0x00, 0x00, 0x00, 0x00) .. data .. stop)
end

function p9813.set_all(count, a, r, g, b)
    -- 1 1 ~b7 ~b6 ~g7 ~g6 ~r7 ~r6
    local a = bit.bnot(bit.bor(
        bit.rshift(bit.band(0xC0, b), 2),
        bit.rshift(bit.band(0xC0, g), 4),
        bit.rshift(bit.band(0xC0, r), 6),
    ))
    return p9813.write(string.rep(string.char(a, b, g, r), count))
end

power.init()
-- apa102.init()
p9813.init()


power.on()
-- apa102.set_all(30, 31, 0, 0, 255)
p9813.set_all(1, 0, 0, 0, 0)
