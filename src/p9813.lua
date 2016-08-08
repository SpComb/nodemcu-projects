p9813 = {
    spi     = 1,

    anim    = 0,
}

function p9813.init()
    spi.setup(p9813.spi, spi.MASTER, spi.CPOL_LOW, spi.CPHA_LOW, spi.DATABITS_8, 8);
end

function p9813.write(data)
    local start = string.char(0x00, 0x00, 0x00, 0x00)
    local stop = string.char(0x00, 0x00, 0x00, 0x00)

    return spi.send(1, start .. data .. stop)
end

function p9813.set_all(count, r, g, b)
    -- 1 1 ~b7 ~b6 ~g7 ~g6 ~r7 ~r6
    local a = bit.bor(0xC0,
        bit.rshift(bit.band(0xC0, bit.bnot(b)), 2),
        bit.rshift(bit.band(0xC0, bit.bnot(g)), 4),
        bit.rshift(bit.band(0xC0, bit.bnot(r)), 6)
    )
    return p9813.write(string.rep(string.char(a, b, g, r), count))
end

function p9813.tick()
   p9813.anim = p9813.anim + 1

   local v = p9813.anim % 255

   p9813.set_all(1, v, v, v)
end

p9813.init()
p9813.set_all(1, 0, 0, 0)

tmr.register(0, 100, tmr.ALARM_AUTO, p9813.tick)
tmr.start(0)
