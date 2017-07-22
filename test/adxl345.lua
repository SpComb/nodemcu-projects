adxl345.init()

adxl345.set_offset(adxl345.offset_x, adxl345.offset_y, adxl345.offset_z)
adxl345.write_u8(0x24, adxl345.threshold_active)   -- THRESH_ACT @ 1g/16
adxl345.write_u8(0x25, adxl345.threshold_inactive) -- THRESH_ACT @ 1g/16
adxl345.write_u8(0x26, adxl345.time_inactive)      -- THRESH_ACT @ 1s/1
adxl345.write_u8(0x27, 0xE0 + 0x0E) -- ACT_INACT_CTL ACT=dc-xy INACT=dc-xy
adxl345.write_u8(0x31, 0x08 + 0x03) -- DATA_FORMAT FULL_RES=1 Range=16g
adxl345.write_u8(0x2F, 0x00) -- INT_MAP Activity=INT1 Inactivity=INT1
adxl345.write_u8(0x38, 0x80 + 16) -- FIFO_CTL FIFO_MODE=Stream Trigger=0 Samples=16

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

-- Print state, show absolute values
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

-- Trigger on changes, show deltas
function adxl345_trigger(event)
  local fifo_status = adxl345.read_u8(0x39)
  local fifo_trigger = bit.band(fifo_status, 0x80) ~= 0
  local fifo_entries = bit.band(fifo_status, 0x3f)

  print(string.format("ADXL345 @ %s: FIFO trigger=%s entries=%d ", event, tostring(fifo_trigger), fifo_entries))

  local x0, y0, z0 = adxl345.read_xyz()

  print(string.format("ADXL345:       X=%+6d Y=%+6d Z=%+6d ", x0, y0, z0))

  local x1 = x0
  local y1 = y0
  local z1 = z0

  for i = 1, fifo_entries do
    local x, y, z = adxl345.read_xyz()
    local dx0 = x - x0
    local dx1 = x - x1
    local dy0 = y - y0
    local dy1 = y - y1
    local dz0 = z - z0
    local dz1 = z - z1

    if dx1 > adxl345.threshold_active * 16 then
      print(string.format("ADXL345 @ %2d: +X %+6d          (d0 %+6d, d1 = %+6d)", i, x, dx0, dx1))
    elseif dx1 < -adxl345.threshold_active * 16 then
      print(string.format("ADXL345 @ %2d: -X %+6d          (d0 %+6d, d1 = %+6d)", i, x, dx0, dx1))
    else
      print(string.format("ADXL345 @ %2d:  X %+6d          (d0 %+6d, d1 = %+6d)", i, x, dx0, dx1))
    end

    if dy1 > adxl345.threshold_active * 16 then
      print(string.format("ADXL345 @ %2d:          +Y %+6d (d0 %+6d, d1 = %+6d)", i, y, dy0, dy1))
    elseif dy1 < -adxl345.threshold_active * 16 then
      print(string.format("ADXL345 @ %2d:          -Y %+6d (d0 %+6d, d1 = %+6d)", i, y, dy0, dy1))
    else
      print(string.format("ADXL345 @ %2d:           Y %+6d (d0 %+6d, d1 = %+6d)", i, y, dy0, dy1))
    end

    x1 = x
    y1 = y
    z1 = z
  end

  -- clear interrupt
  local int_status = adxl345.read_u8(0x30)

  print(string.format("ADXL345: INT %02x", int_status))
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
