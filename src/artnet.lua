-- reset state
if artnet and artnet.udp_socket then
  artnet.udp_socket:close()
end

artnet = {
    udp_port      = 6454,
    universe = 0,     -- bits 4.. only, bits 0..3 are from the port number

    oem               = 0x0000,
    esta_manufacturer = 0x0000,
    name_short        = "NodeMCU-ARTNET",
    name_long         = "",
    version           = 0x0000, -- uint32
}

function artnet.pack_string(length, s)
  return s .. string.rep("\0", length - string.len(s))
end

function artnet.init(options)
    artnet.ports = {}
    artnet.outputs = {}
    artnet.universe = bit.band((options.universe or 0), 0xFFF0)
    artnet.version = (options.version or 0)
    artnet.udp_socket = net.createUDPSocket()
    artnet.udp_socket:on("receive", artnet.on_receive)
    artnet.udp_socket:listen(artnet.udp_port)

    print("artnet:init: listen UDP port=" .. artnet.udp_port)
end

-- Patch output port at address 0..15
function artnet.patch_output(addr, driver, description)
  table.insert(artnet.ports, {
    addr   = addr,
    output = true,
  })
  artnet.outputs[addr] = {
    driver    = driver,
    sequence  = 0,     -- TODO: reset on timeout
  }

  print("artnet:init: patch output port=" .. table.maxn(artnet.outputs) .. " at addr=" .. addr .. ": " .. description)

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

function artnet.info_port_count()
  return table.maxn(artnet.outputs)
end

function artnet.info_port_type(port)
  info = artnet.ports[port]

  if info and info.output then
    return 0x80 + 0 -- output + DMX512
  else
    return 0
  end
end

function artnet.info_output_status(port)
  info = artnet.ports[port]

  if info and info.output then
    return 0x80 -- output
  else
    return 0
  end
end

-- XXX: bit.band(artnet.universe, 0x0F)
function artnet.info_output_addr(port)
  info = artnet.ports[port]

  if info then
    return info.addr
  else
    return 0
  end
end

-- Send reply packet to client
function artnet.send(port, ip, opcode, params)
  print("artnet:send " .. ip .. ":" .. port .. ": opcode=" .. opcode)

  local buf = struct.pack("c8 <H", "Art-Net\0", opcode)

  buf = buf .. table.concat(params)

  artnet.udp_socket:send(port, ip, buf)
end

function artnet.send_poll_reply(port, ip)
    artnet.send(port, ip, 0x2100, {
        struct.pack("c4",     artnet.info_ipaddr()),      -- IpAddress
        struct.pack("<H",     artnet.udp_port),           -- PortNumber
        struct.pack(">H",     artnet.version),            -- VersInfo
        struct.pack("B",      bit.arshift(artnet.universe, 8)), -- NetSwitch
        struct.pack("B",      bit.band(artnet.universe, 0xF0)), -- SubSwitch
        struct.pack(">H",     artnet.oem ),                -- Oem
        struct.pack("B",      0 ),                        -- Ubea
        struct.pack("B",      0 ),                        -- Status1 Configuration flags
        struct.pack("<H",     artnet.esta_manufacturer ), -- EstaMan ESTA Manufacturer
        artnet.pack_string(18, artnet.name_short),        -- ShortName
        artnet.pack_string(64, artnet.name_long),         -- LongName
        artnet.pack_string(64, artnet.info_report()),     -- NodeReport
        struct.pack(">H",      artnet.info_port_count()), -- NumPorts
        struct.pack("BBBB",                               -- PortTypes
          artnet.info_port_type(1),
          artnet.info_port_type(2),
          artnet.info_port_type(3),
          artnet.info_port_type(4)
        ),
        struct.pack("BBBB",                               -- GoodInput
          0,
          0,
          0,
          0
        ),
        struct.pack("BBBB",                               -- GoodOutput
          artnet.info_output_status(1),
          artnet.info_output_status(2),
          artnet.info_output_status(3),
          artnet.info_output_status(4)
        ),
        struct.pack("BBBB",                               -- SwIn
          0,
          0,
          0,
          0
        ),
        struct.pack("BBBB",                               -- SwOut
          artnet.info_output_addr(1),
          artnet.info_output_addr(2),
          artnet.info_output_addr(3),
          artnet.info_output_addr(4)
        ),
        struct.pack("B",      0),                         -- SwVideo
        struct.pack("B",      0),                         -- SwMacro
        struct.pack("B",      0),                         -- SwRemote
        struct.pack("B",      0),                         -- Spare1
        struct.pack("B",      0),                         -- Spare2
        struct.pack("B",      0),                         -- Spare3
        struct.pack("B",      0),                         -- Style ?
        struct.pack("c6",     artnet.info_mac()),         -- Mac
        struct.pack("c4",     artnet.info_ipaddr()),      -- BindIp
        struct.pack("B",      0),                         -- BindIndex
        struct.pack("B",      0x2 + 0x1),                 -- Status2 DHCP capable + DHCP configured
        --struct.pack("c26",    ...)                         -- Filler
    })
end

function artnet.on_receive(sock, buf, port, ip)
    local magic, opcode, version, offset = struct.unpack("c8 <H >H", buf)

    if magic ~= "Art-Net\0" then
        print("artnet:recv " .. ip .. ":" .. port .. ": invalid magic")

    elseif opcode == 0x2000 then
        flags, priority, offset = struct.unpack("BB", buf, offset)

        print("artnet:recv " .. ip .. ":" .. port .. ": poll flags=" .. flags .. " priority=" .. priority)

        artnet.recv_poll(port, ip, flags, priority)

    elseif opcode == 0x5000 then
        seq, phy, universe, length, offset = struct.unpack("BB <H >H", buf, offset)

        print("artnet:recv " .. ip .. ":" .. port .. ": dmx seq=" .. seq .. " phy=" .. phy .. " universe=" .. universe .. " length=" .. length)

        artnet.recv_dmx(port, ip, universe, seq, string.sub(buf, offset))
    else
        print("artnet:recv " .. ip .. ":" .. port .. ": unkonwn opcode=" .. opcode .. " version=" .. version)
    end
end

function artnet.recv_poll(port, ip, flags, priority)
  artnet.send_poll_reply(port, ip)
end

function artnet.recv_dmx(port, ip, universe, sequence, data)
  -- universe handling
  if bit.band(universe, 0xFFF0) ~= artnet.universe then
    return
  end

  output = artnet.outputs[bit.band(universe, 0xF)]

  if not output then
    return
  end

  -- sequence handling
  if sequence == 0 then
    -- reset
    output.sequence = sequence

  elseif sequence <= output.sequence and output.sequence - sequence < 128 then
    -- skip duplicated or reordered frame
    return
  else
    output.sequence = sequence
  end

  -- output
  output.driver.artnet_dmx(data)
end
