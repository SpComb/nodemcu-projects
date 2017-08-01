apa102 = {
    spi     = 1,
}

function apa102.init()
    spi.setup(apa102.spi, spi.MASTER, spi.CPOL_LOW, spi.CPHA_LOW, spi.DATABITS_8, 8);
end

-- write string of 32-bit A R G B frames
-- A is 0xE0 | 0x00-0x3F
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

-- unpack and send repeated RGB frames
function apa102.send_dmx(data)
  local offset = 1
  local frames = { }

  while offset < string.len(data) do
      r, g, b, offset = struct.unpack("BBB", data, offset)

      table.insert(frames, string.char(0xFF, b, g, r))
  end

  apa102.write(table.concat(frames))
end
