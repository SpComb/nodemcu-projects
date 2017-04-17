DS18B20_FAMILY = 0x28
DS18B20_SEARCH_INTERVAL = 10 * 1000 -- ms between each search
DS18B20_SEARCH_STEP = 10 -- ms between each device search step

DS18B20_READ_INTERVAL = 10 * 1000 -- ms between each device read loop
DS18B20_READ_DELAY = 750 -- ms between measurement and read
DS18B20_READ_STEP = 10 -- ms between each device read step

DS18B20_CMD_CONVERT = 0x44
DS18B20_CMD_WRITE = 0x4E
DS18B20_CMD_READ = 0xBE

DS18B20_CONFIG_RESOLUTION_MASK = 0x60
DS18B20_CONFIG_RESOLUTION_9 = 0x00
DS18B20_CONFIG_RESOLUTION_10 = 0x20
DS18B20_CONFIG_RESOLUTION_11 = 0x40
DS18B20_CONFIG_RESOLUTION_12 = 0x60

if ds18b20 then
  if ds18b20.search_timer then
    ds18b20.search_timer:unregister()
  end
end

ds18b20 = {
    pin  = 2,
}

function ds18b20.init()
  ds18b20.search_timer = tmr.create()
  ds18b20.read_timer = tmr.create()
  ds18b20.devices = {}

  ow.setup(ds18b20.pin)
end

-- Start periodic tasks
function ds18b20.start(read_func)
  ds18b20.search() -- immediately search, and then repeat

  if read_func then
    ds18b20.read_func = read_func
    ds18b20.read_start() -- immediately read, then repeat
  end
end

-- Start searching in interval
function ds18b20.start_search()
  ds18b20.search_timer:register(DS18B20_SEARCH_INTERVAL, tmr.ALARM_SEMI, function(timer)
    ds18b20.search()
  end)
  ds18b20.search_timer:start()
end

-- Start a search
-- Calls search_start(); N * search_device(device); search_done()
function ds18b20.search()
  ow.target_search(ds18b20.pin, DS18B20_FAMILY)
  ow.reset_search(ds18b20.pin)

  ds18b20.search_start()

  ds18b20.search_timer:register(DS18B20_SEARCH_STEP, tmr.ALARM_SEMI, function(timer)
    local rom_code = ow.search(ds18b20.pin)

    if rom_code then
      ds18b20.search_device(rom_code)
      ds18b20.search_timer:start()
    else
      ds18b20.search_done()
      ds18b20.start_search() -- next search
    end
  end)

  ds18b20.search_timer:start()
end

-- Search started
function ds18b20.search_start()
  print("ds18b20.search: start")

  -- mark
  for addr, flag in pairs(ds18b20.devices) do
    ds18b20.devices[addr] = false
  end
end

-- Search found device
function ds18b20.search_device(addr)
  if addr:len() ~= 8 then
    return print("ds18b20.search: invalid addr")
  end

  if addr:byte(8) ~= ow.crc8(addr:sub(1,7)) then
    return print("ds18b20.search: crc fault")
  end

  print("ds18b20.search: " .. ds18b20.device_string(addr))

  if ds18b20.devices[addr] == nil then
    ds18b20.device_attach(addr)
  end

  ds18b20.devices[addr] = true
end

-- Search is done, no more devices
function ds18b20.search_done()
  print("ds18b20.search: done")

  -- sweep
  -- TODO: debounce for transient faults
  for addr, flag in pairs(ds18b20.devices) do
    if not flag then
      ds18b20.devices[addr] = nil
      ds18b20.device_detach(addr)
    end
  end
end

-- Device was added
function ds18b20.device_attach(addr)
  print("ds18b20.device_attach: " .. ds18b20.device_string(addr))
end

-- Device was removed
function ds18b20.device_detach(addr)
  print("ds18b20.device_detach: " .. ds18b20.device_string(addr))
end

function ds18b20.device_string(addr)
  return string.format("%02x.%02x:%02x:%02x:%02x:%02x:%02x",
    addr:byte(1),
    addr:byte(2),
    addr:byte(3),
    addr:byte(4),
    addr:byte(5),
    addr:byte(6),
    addr:byte(7)
  )
end

function ds18b20.info()
  devices = {}

  for addr, state in pairs(ds18b20.devices) do
    table.insert(devices, ds18b20.device_string(addr))
  end

  return {
    Devices   = devices,
  }
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
function ds18b20.command(addr, cmd, data, size)
  local power = 0

  if ow.reset(ds18b20.pin) == 0 then
    print("ds18b20.broadcast: reset fault")
  end

  ow.select(ds18b20.pin, addr)
  ow.write(ds18b20.pin, cmd, power)

  if data then
    os.write_bytes(ds18b20.pin, data, power)
  end

  if size then
    string = ow.read_bytes(ds18b20.pin, size)

    return string
  end
end

-- Send command for all devices to measure
function ds18b20.measure_all()
  ds18b20.broadcast(DS18B20_CMD_CONVERT)
end

-- Read temperature for device at address
-- Returns 16-bit signed temperature in 1/16th degrees C
-- Returns nil on error
function ds18b20.read(addr)
  local data = ds18b20.command(addr, DS18B20_CMD_READ, nil, 9)

  local temp, alarm_high, alarm_low, config, crc = struct.unpack("< i2 b b B x x x B", data)

  if crc ~= ow.crc8(data:sub(1, 8)) then
    -- device is disconnected?
    print("ds18b20.read: crc error")
    return nil
  end

  local config_resolution = bit.band(config, DS18B20_CONFIG_RESOLUTION_MASK)
  local temp_c = bit.arshift(temp, 4)
  local temp_d = bit.band(temp, 0xF)

  print("ds18b20.read: " .. string.format("config={res=0x%x} temp=%d (%d + %d/16 C) alarm={high=%d, low=%d}",
    config_resolution,
    temp,
    temp_c, temp_d,
    alarm_high, alarm_low
  ))

  return temp
end

-- Write configuration for device at address
--  alarm_high: 8-bit signed high temperature in degrees C
--  alarm_low: 8-bit signed low temperature in degrees C
--  config: 8-bit wide config register with DS18B20_CONFIG_* bits
function ds18b20.write(addr, alarm_high, alarm_low, config)
  local data = struct.pack("< b b B",
    alarm_high,
    alarm_low,
    bit.band(config, DS18B20_CONFIG_RESOLUTION_MASK)
  )

  ds18b20.command(addr, DS18B20_CMD_WRITE, nil, nil)
end

-- After interval, read starts
function ds18b20.start_read()
  ds18b20.read_timer:alarm(DS18B20_READ_INTERVAL, tmr.ALARM_SINGLE, function(timer)
    ds18b20.read_start()
  end)
end

-- Start read by measuring, then after delay, step reads
function ds18b20.read_start()
  ds18b20.measure_all()

  ds18b20.read_timer:alarm(DS18B20_READ_DELAY, tmr.ALARM_SINGLE, function(timer)
    ds18b20.read_step(nil)
  end)
end

-- Step each device to read it
-- Once done, re-starts the read after interval
function ds18b20.read_step(step_device)
  local device = next(ds18b20.devices, step_device) -- XXX: unsafe against concurrent adds

  if device then
    local temp = ds18b20.read(device)

    -- report
    ds18b20.read_func(ds18b20.device_string(device), temp)

    ds18b20.read_timer:alarm(DS18B20_READ_STEP, tmr.ALARM_SINGLE, function(timer)
      ds18b20.read_step(device)
    end)
  else
    ds18b20.start_read() -- next interval
  end
end
