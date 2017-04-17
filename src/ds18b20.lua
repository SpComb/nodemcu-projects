DS18B20_FAMILY = 0x28
DS18B20_SCAN_INTERVAL = 20 -- ms

ds18b20 = {
    pin  = 2,
}

function ds18b20.init()
  ds18b20.search_timer = tmr.create()

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
end

function ds18b20.search_device(addr)
  if not addr:len() == 8 then
    return print("ds18b20.search: invalid addr")
  end

  if not addr:byte(8) == ow.crc8(addr:sub(1,7)) then
    return print("ds18b20.search: invalid crc")
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
end

function ds18b20.search_done()
  print("ds18b20.search: done")
end
