adxl345.init()

adxl345.set_offset(adxl345.offset_x, adxl345.offset_y, adxl345.offset_z)
adxl345.write_u8(0x24, adxl345.threshold_active)   -- THRESH_ACT @ 1g/16
adxl345.write_u8(0x25, adxl345.threshold_inactive) -- THRESH_ACT @ 1g/16
adxl345.write_u8(0x26, adxl345.time_inactive)      -- THRESH_ACT @ 1s/1
adxl345.write_u8(0x27, 0xE0 + 0x0E) -- ACT_INACT_CTL ACT=dc-xy INACT=dc-xy
adxl345.write_u8(0x31, 0x08 + 0x03) -- DATA_FORMAT FULL_RES=1 Range=16g
adxl345.write_u8(0x2F, 0x00) -- INT_MAP Activity=INT1 Inactivity=INT1
adxl345.write_u8(0x38, 0xC0 + 8) -- FIFO_CTL FIFO_MODE=Trigger Trigger=0 Samples=8

print(string.format("ADXL345 DEVID         %02x", adxl345.read_u8(0x00)))
print(string.format("ADXL345 OFFSET        %+3d %+3d %+3d", adxl345.read_struct(0x1E, "<bbb")))
print(string.format("ADXL345 THRESH_ACT    %02x", adxl345.read_u8(0x24)))
print(string.format("ADXL345 THRESH_INACT  %02x", adxl345.read_u8(0x25)))
print(string.format("ADXL345 TIME_INACT    %02x", adxl345.read_u8(0x26)))
print(string.format("ADXL345 ACT_INACT_CTL %02x", adxl345.read_u8(0x27)))
print(string.format("ADXL345 BW_RATE       %02x", adxl345.read_u8(0x2C)))
print(string.format("ADXL345 POWER_CTL     %02x", adxl345.read_u8(0x2D)))
print(string.format("ADXL345 INT_ENABLE    %02x", adxl345.read_u8(0x2E)))
print(string.format("ADXL345 INT_MAP       %02x", adxl345.read_u8(0x2F)))
print(string.format("ADXL345 INT_SOURCE    %02x", adxl345.read_u8(0x30)))
print(string.format("ADXL345 DATA_FORMAT   %02x", adxl345.read_u8(0x31)))
print(string.format("ADXL345 FIFO_CTL      %02x", adxl345.read_u8(0x38)))
print(string.format("ADXL345 FIFO_STATUS   %02x", adxl345.read_u8(0x39)))

adxl345.write_u8(0x2D, 0x08) -- POWER_CTL measure=1
adxl345.write_u8(0x2E, 0x10) -- INT_ENABLE Activity !Inactivity

print(string.format("ADXL345 POWER_CTL     %02x", adxl345.read_u8(0x2D)))
print(string.format("ADXL345 INT_ENABLE    %02x", adxl345.read_u8(0x2E)))

function adxl345_print()
  local fifo_status = adxl345.read_u8(0x39)
  local fifo_trigger = bit.band(fifo_status, 0x80) ~= 0
  local fifo_entries = bit.band(fifo_status, 0x3f)

  print(string.format("ADXL345: FIFO trigger=%s entries=%d ", tostring(fifo_trigger), fifo_entries))

  while fifo_entries > 0 do
    local x, y, z = adxl345.read_xyz()

    print(string.format("ADXL345 @ %2d: X=%+6d Y=%+6d Z=%+6d ", fifo_entries, x, y, z))

    fifo_entries = fifo_entries - 1
  end

  -- clear interrupt
  local int_status = adxl345.read_u8(0x30)

  print(string.format("ADXL345 INT: %02x", int_status))
end

function adxl345_trigger(event)
  local fifo_status = adxl345.read_u8(0x39)
  local fifo_trigger = bit.band(fifo_status, 0x80) ~= 0
  local fifo_entries = bit.band(fifo_status, 0x3f)

  print(string.format("ADXL345 @ %s: FIFO trigger=%s entries=%d ", event, tostring(fifo_trigger), fifo_entries))

  local x1, y1, z1 = adxl345.read_xyz()

  print(string.format("ADXL345 @ %2d:  X=%+6d  Y=%+6d  Z=%+6d ", fifo_entries, x1, y1, z1))

  while fifo_entries > 1 do
    local x2, y2, z2 = adxl345.read_xyz()
    local dx = x2 - x1
    local dy = y2 - y1
    local dz = z2 - z1
    x1 = x2
    y1 = y2
    z1 = z2

    fifo_entries = fifo_entries - 1

    print(string.format("ADXL345 @ %2d: dX=%+6d dY=%+6d dZ=%+6d ", fifo_entries, dx, dy, dz))
  end

  if fifo_trigger then
    -- reset trigger
    adxl345.write_u8(0x38, 0) -- FIFO_CTL FIFO_MODE=Bypass Trigger=0 Samples=0
    tmr.delay(5)
    adxl345.write_u8(0x38, 0xC0 + 8) -- FIFO_CTL FIFO_MODE=Trigger Trigger=0 Samples=8

    local fifo_ctl = adxl345.read_u8(0x38)
    local fifo_status = adxl345.read_u8(0x39)
    local fifo_trigger = bit.band(fifo_status, 0x80) ~= 0
    local fifo_entries = bit.band(fifo_status, 0x3f)

    print(string.format("ADXL345 reset trigger: FIFO ctl=%02x trigger=%s entries=%d ", fifo_ctl, tostring(fifo_trigger), fifo_entries))
  end

  -- clear interrupt
  local int_status = adxl345.read_u8(0x30)

  print(string.format("ADXL345 INT: %02x", int_status))
end

if false then
    tmr.alarm(0, 1000, tmr.ALARM_AUTO, function(timer)
    adxl345_print()
  end)
end

adxl345.on_int1(function(level, when)
  adxl345_trigger("INT1")
end)
adxl345.on_int2(function(level, when)
  adxl345_trigger("INT2")
end)
