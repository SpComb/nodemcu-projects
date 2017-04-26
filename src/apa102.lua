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
