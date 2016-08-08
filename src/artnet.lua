artnet = {
    port     = 6454,
    universe = 1,
    dmx      = nil,
}

function artnet.init(dmx)
    artnet.dmx = dmx
    artnet.server = net.createServer(net.UDP)
    artnet.server:on("receive", artnet.on_receive)
    artnet.server:listen(artnet.port, function(socket)
        print("artnet:init: listen done")
    end)
        
    print("artnet:init: listen port=" .. artnet.port)
end

function artnet.on_receive(socket, buf)
    local ip, port = socket.getpeer()

    local magic, opcode, version, seq, phy, universe, length, offset = struct.unpack("c8HHBBHH", buf)

    if magic != "ARTNET\0" then
        print("artnet:recv: from=" .. ip .. ":"  .. port .. ": invalid magic")
    end
        
    print("artnet:recv: from=" .. ip .. ":"  .. port .. " opcode=" .. opcode .. " seq=" .. seq .. " length=" .. length)

    if opcode == 0x5000 then
        local channels = {}

        for i = 0, length do
            value, offset = struct.unpack("B", offset)

            channels[i] = value
        end

        artnet.recv_dmx(universe, channels)
    end
end

function artnet.recv_dmx(universe, channels)
    if universe == artnet.universe then
        artnet.dmx.sendChannels(channels)
    end
end
