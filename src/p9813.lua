-- P9813 3ch LED driver
p9813 = {
    spi     = 1,
    count   = 1,

    START   = string.char(0x00, 0x00, 0x00, 0x00),
    STOP    = string.char(0x00, 0x00, 0x00, 0x00)
}

function p9813.init()
    p9813.anim = 0

    spi.setup(p9813.spi, spi.MASTER, spi.CPOL_LOW, spi.CPHA_LOW, spi.DATABITS_8, 8);
end

-- Write START .. FRAMES STOP
function p9813.send(frames)
    return spi.send(p9813.spi, p9813.START .. frames .. p9813.STOP)
end

-- Return 4-byte frame for 8-big RGB
function p9813.frame(r, g, b)
  -- 1 1 ~b7 ~b6 ~g7 ~g6 ~r7 ~r6
  local a = bit.bor(0xC0,
      bit.rshift(bit.band(0xC0, bit.bnot(b)), 2),
      bit.rshift(bit.band(0xC0, bit.bnot(g)), 4),
      bit.rshift(bit.band(0xC0, bit.bnot(r)), 6)
  )

  return string.char(a, b, g, r)
end

function p9813.send_all(count, r, g, b)
    return p9813.send(string.rep(p9813.frame(r, g, b), count))
end

-- ArtNET output
function p9813.artnet_dmx(data)
  local offset = 1
  local frames = { }

  while offset < string.len(data) do
      r, g, b, offset = struct.unpack("BBB", data, offset)

      table.insert(frames, p9813.frame(r, g, b))
  end

  p9813.send(table.concat(frames))
end

function p9813.tick()
   p9813.anim = p9813.anim + 1

   local v = p9813.anim % 255

   p9813.send_all(p9813.count, v, v, v)
end

function p9813.test()
  p9813.send_all(p9813.count, 0, 0, 0)

  tmr.register(0, 100, tmr.ALARM_AUTO, p9813.tick)
  tmr.start(0)
end
