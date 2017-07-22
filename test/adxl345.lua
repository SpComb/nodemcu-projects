adxl345.init()

adxl345.set_offset(adxl345.offset_x, adxl345.offset_y, adxl345.offset_z)
adxl345.write_u8(0x24, adxl345.threshold_active)   -- THRESH_ACT @ 1g/16
adxl345.write_u8(0x25, adxl345.threshold_inactive) -- THRESH_ACT @ 1g/16
adxl345.write_u8(0x26, adxl345.time_inactive)      -- THRESH_ACT @ 1s/1
adxl345.write_u8(0x27, 0xE0 + 0x0E) -- ACT_INACT_CTL ACT=dc-xy INACT=dc-xy
adxl345.write_u8(0x31, 0x08 + 0x03) -- DATA_FORMAT FULL_RES=1 Range=16g
adxl345.write_u8(0x2F, 0x00) -- INT_MAP Activity=INT1 Inactivity=INT1

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

adxl345.write_u8(0x2D, 0x08) -- POWER_CTL measure=1
adxl345.write_u8(0x2E, 0x10) -- INT_ENABLE Activity !Inactivity

print(string.format("ADXL345 POWER_CTL     %02x", adxl345.read_u8(0x2D)))
print(string.format("ADXL345 INT_ENABLE    %02x", adxl345.read_u8(0x2E)))

tmr.alarm(0, 100, tmr.ALARM_AUTO, function(timer)
  local int = adxl345.read_u8(0x30)
  local x, y, z = adxl345.read_xyz()
  print(string.format("ADXL345 X=%+6d Y=%+6d Z=%+6d (int %02x)", x, y, z, int))
end)
adxl345.on_int1(function(level, when)
  print(string.format("ADXL INT1 level=%d when=%d", level, when))
end)
adxl345.on_int2(function(level, when)
  print(string.format("ADXL INT2 level=%d when=%d", level, when))
end)
