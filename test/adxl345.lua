adxl345.init()

adxl345.set_offset(adxl345.offset_x, adxl345.offset_y, adxl345.offset_z)
adxl345.write_u8(0x31, 0x08 + 0x03) -- POWER_CTL FULL_RES=1 Range=16g
adxl345.write_u8(0x2D, 0x08) -- POWER_CTL measure=1

print(string.format("ADXL345 DEVID       %02x", adxl345.read_u8(0x00)))
print(string.format("ADXL345 OFFSET      %+3d %+3d %+3d", adxl345.read_struct(0x1E, "<bbb")))
print(string.format("ADXL345 BW_RATE     %02x", adxl345.read_u8(0x2C)))
print(string.format("ADXL345 POWER_CTL   %02x", adxl345.read_u8(0x2D)))
print(string.format("ADXL345 DATA_FORMAT %02x", adxl345.read_u8(0x31)))

print(adxl345.read_xyz())
