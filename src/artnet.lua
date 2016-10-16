artnet = {
    port     = 6454,
    universe = 1,
    dmx      = nil,

    name_short  = "NodeMCU-ARTNET",
    name_long = ""
}

function artnet.pack_string(length, s)
  return s .. string.rep("\0", length - string.len(s))
end

function artnet.init(dmx)
    artnet.dmx = dmx
    artnet.server = net.createServer(net.UDP)
    artnet.server:on("receive", artnet.on_receive)
    artnet.server:listen(artnet.port)

    print("artnet:init: listen port=" .. artnet.port)
end

function artnet.info_mac()
  -- local mac = wifi.sta.getmac()

  return "\0\0\0\0\0\0"
end

function artnet.info_ipaddr()
  -- local ip, = wifi.sta.getip()

  return "\0\0\0\0"
end

function artnet.info_report()
  return string.rep("\0", 64)
end

-- Send reply packet to client
--
-- this is not per ArtNet spec, but the NodeMCU net library is really weird for UDP..
function artnet.send(opcode, params)
  local buf = struct.pack("<c8H", "ART-NET\0", opcode)

  buf = buf .. table.concat(params)

  artnet.server:send(buf)
end

function artnet.send_poll_reply()
    artnet.send(0x2100, {
        struct.pack("c4",     artnet.info_ipaddr()),      -- IpAddress
        struct.pack("H",      artnet.port),               -- PortNumber
        struct.pack("H",      app.version),               -- VersInfo
        struct.pack("H",      0x0000 ),                   -- NetSwitch & SubSwitch
        struct.pack("H",      0x0000 ),                   -- Oem
        struct.pack("B",      0 ),                        -- Ubea
        struct.pack("B",      0 ),                        -- Status1  Configuration flags
        struct.pack("H",      0x0000 ),                   -- EstaMan  ESTA Manufacturer
        artnet.pack_string(18, artnet.name_short),        -- ShortName
        artnet.pack_string(64, artnet.name_long),         -- LongName
        artnet.pack_string(64, artnet.info_report()),     -- NodeReport
        struct.pack("H",      1 ),                        -- NumPorts
        struct.pack("BBBB",   0, 0, 0, 0x80 + 0x0),       -- PortTypes
        struct.pack("BBBB",   0, 0, 0, 0),                -- GoodInput
        struct.pack("BBBB",   0, 0, 0, 0x80),             -- GoodOutput
        struct.pack("BBBB",   0, 0, 0, 0),                -- SwIn
        struct.pack("BBBB",   3, 2, 1, 0),                -- SwOut
        struct.pack("B",      0),                         -- SwVideo
        struct.pack("B",      0),                         -- SwMacro
        struct.pack("B",      0),                         -- SwRemote
        struct.pack("BBBB",   0, 0, 0, 0),                -- Spare{1-3)
        struct.pack("B",      0),                         -- Style ?
        struct.pack("c6",     artnet.info_mac()),         -- Mac
        struct.pack("c4",     artnet.info_ipaddr()),      -- BindIp
        struct.pack("B",      0),                         -- BindIndex
        struct.pack("B",      0x2 + 0x1),                 -- Status2 DHCP capable + DHCP configured
        --struct.pack("c26",    ...)                         -- Filler
    })
end

function artnet.on_receive(_, buf)
    local magic, opcode, version, offset = struct.unpack("<c8HH", buf)

    if magic ~= "ART-NET\0" then
        print("artnet:recv: invalid magic")

    elseif opcode == 0x2000 then
        flags, priority, offset = struct.unpack("BB", buf, offset)

        print("artnet:recv poll: flags=" .. flags .. " priority=" .. priority)

        artnet.recv_poll(flags, priority)

    elseif opcode == 0x5000 then
        seq, phy, universe, length, offset = struct.unpack("BBHH", buf, offset)

        print("artnet:recv dmx: seq=" .. seq .. " phy=" .. phy .. " universe=" .. universe .. " length=" .. length)

        local channels = {}

        for i = 0, length do
            value, offset = struct.unpack("B", offset)

            channels[i] = value
        end

        artnet.recv_dmx(universe, channels)
    else
        print("artnet:recv unkonwn opcode=" .. opcode .. " version=" .. version)
    end
end

function artnet.recv_poll(flags, priority)
  artnet.send_poll_reply()
end

function artnet.recv_dmx(universe, channels)
    if universe == artnet.universe then
        artnet.dmx.sendChannels(channels)
    end
end
