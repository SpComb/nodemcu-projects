-- P9813 3ch LED driver
p9813 = {
    spi     = 1,
    count   = 1,
    layout  = "BGR",

    START   = string.char(0x00, 0x00, 0x00, 0x00),
    STOP    = string.char(0x00, 0x00, 0x00, 0x00)
}

function p9813.init(options)
    p9813.layout = options.layout or "BGR"
    p9813.anim_index = 0
    p9813.anim_offset = 0
    p9813.anim_step = 8

    spi.setup(p9813.spi, spi.MASTER, spi.CPOL_LOW, spi.CPHA_LOW, spi.DATABITS_8, 8);
end

-- Write START .. FRAMES STOP
function p9813.send(frames)
    return spi.send(p9813.spi, p9813.START .. frames .. p9813.STOP)
end

-- Return 4-byte frame for 8-big RGB
function p9813.frame(r, g, b)
  local c1, c2, c3

  if p9813.layout == "RGB" then
    c1 = r
    c2 = g
    c3 = b
  elseif p9813.layout == "RBG" then
    c1 = r
    c2 = b
    c3 = g
  elseif p9813.layout == "GBR" then
    c1 = g
    c2 = b
    c3 = r
  elseif p9813.layout == "GRB" then
    c1 = g
    c2 = r
    c3 = b
  elseif p9813.layout == "BRG" then
    c1 = b
    c2 = r
    c3 = g
  elseif p9813.layout == "BGR" then
    c1 = b
    c2 = g
    c3 = r
  else
    error("invalid p9813.layout=" .. p9813.layout)
  end

  -- 1 1 ~b7 ~b6 ~g7 ~g6 ~r7 ~r6
  local a = bit.bor(0xC0,
      bit.rshift(bit.band(0xC0, bit.bnot(c1)), 2),
      bit.rshift(bit.band(0xC0, bit.bnot(c2)), 4),
      bit.rshift(bit.band(0xC0, bit.bnot(c3)), 6)
  )

  return string.char(a, c1, c2, c3)
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
   p9813.anim_offset = p9813.anim_offset + p9813.anim_step

   if p9813.anim_offset > 255 then
     p9813.anim_offset = 0
     p9813.anim_index = p9813.anim_index + 1
   end

   if p9813.anim_index >= p9813.count * 3 then
     p9813.anim_index = 0
   end

   local frames = {}

   for i = 1, p9813.count do
     local anim_chan = p9813.anim_index % 3

     local r = 0
     local g = 0
     local b = 0

     if p9813.anim_index / 3 == i - 1 then

       if anim_chan == 0 then
         r = p9813.anim_offset

       elseif anim_chan == 1 then
         g = p9813.anim_offset

       elseif anim_chan == 2 then
         b = p9813.anim_offset
       end

       print("p9813.tick: index=" .. p9813.anim_index .. " i=" .. i .. " r=" .. r .. " g=" .. g .. " b=" .. b)
     end

     table.insert(frames, p9813.frame(r, g, b))
   end

   p9813.send(table.concat(frames))
end

function p9813.test()
  p9813.send_all(p9813.count, 0, 0, 0)

  tmr.register(0, 100, tmr.ALARM_AUTO, p9813.tick)
  tmr.start(0)
end
