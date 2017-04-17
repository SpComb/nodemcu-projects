DS18B20_FAMILY = 0x28
DS18B20_SCAN_INTERVAL = 20 -- ms

DS18B20_CMD_CONVERT = 0x44
DS18B20_CMD_WRITE = 0x4E
DS18B20_CMD_READ = 0xBE

ds18b20 = {
    pin  = 2,
}

function ds18b20.init()
  ds18b20.search_timer = tmr.create()
  ds18b20.devices = {}

  ow.setup(ds18b20.pin)
end

-- Start a timed search
function ds18b20.search(func)
  ow.target_search(ds18b20.pin, DS18B20_FAMILY)
  ow.reset_search(ds18b20.pin)

  ds18b20.search_start()

  ds18b20.search_timer:register(DS18B20_SCAN_INTERVAL, tmr.ALARM_SEMI, function(timer)
    local rom_code = ow.search(ds18b20.pin)

    if rom_code then
      ds18b20.search_device(rom_code)
      ds18b20.search_timer:start()
    else
      ds18b20.search_timer:unregister()
      ds18b20.search_done()
    end
  end)

  ds18b20.search_timer:start()
end

function ds18b20.search_start()
  print("ds18b20.search: start")

  -- mark
  for addr, flag in pairs(ds18b20.devices) do
    ds18b20.devices[addr] = false
  end
end

function ds18b20.search_device(addr)
  if addr:len() ~= 8 then
    return print("ds18b20.search: invalid addr")
  end

  if addr:byte(8) ~= ow.crc8(addr:sub(1,7)) then
    return print("ds18b20.search: crc fault")
  end

  print("ds18b20.search: " .. string.format("[%02x]%02x:%02x:%02x:%02x:%02x:%02x<%02x>",
    addr:byte(1),
    addr:byte(2),
    addr:byte(3),
    addr:byte(4),
    addr:byte(5),
    addr:byte(6),
    addr:byte(7),
    addr:byte(8)
  ))

  if ds18b20.devices[addr] == nil then
    ds18b20.on_attach(addr)
  end

  ds18b20.devices[addr] = true
end

function ds18b20.search_done()
  print("ds18b20.search: done")

  -- sweep
  for addr, flag in pairs(ds18b20.devices) do
    if not flag then
      ds18b20.devices[addr] = nil
      ds18b20.on_detach(addr)
    end
  end
end

-- Device was added
function ds18b20.on_attach(addr)
  print("ds18b20.on attach: " .. addr)
end

-- Device was removed
function ds18b20.on_detach(addr)
  print("ds18b20.on detach: " .. addr)
end

-- Send a broadcast command to all slave devices without reading any response
function ds18b20.broadcast(cmd)
  local power = 0

  if ow.reset(ds18b20.pin) == 0 then
    print("ds18b20.broadcast: reset fault")
  end

  ow.skip(ds18b20.pin)
  ow.write(ds18b20.pin, cmd, power)
end

-- Send a unicast command to a slave device, and read response of size bytes as string
function ds18b20.command(addr, cmd, size)
  local power = 0

  if ow.reset(ds18b20.pin) == 0 then
    print("ds18b20.broadcast: reset fault")
  end

  ow.select(ds18b20.pin, addr)
  ow.write(ds18b20.pin, cmd, power)

  string = ow.read_bytes(ds18b20.pin, size)

  return string
end

-- Send command for all devices to measure
function ds18b20.measure_all()
  ds18b20.broadcast(DS18B20_CMD_CONVERT)
end

-- Read temperature for device at address
-- Returns 16-bit signed temperature in 1/16th degrees C
-- Returns nil on error
function ds18b20.read(addr)
  local data = ds18b20.command(addr, DS18B20_CMD_READ, 9)

  if data:byte(9) ~= ow.crc8(data:sub(1, 8)) then
    -- device is disconnected?
    print("ds18b20.read: crc fault")
    return nil
  end

  local temp = struct.unpack("< i2", data, 1)
  local temp_c = bit.arshift(temp, 4)
  local temp_d = bit.band(temp, 0xF)

  print("ds18b20.read: temp=" .. temp .. " " .. temp_c .. " + " .. temp_d .. "/16")

  return temp
end
