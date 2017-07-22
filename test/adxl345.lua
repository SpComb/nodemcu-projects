adxl345.init()

adxl345.write_u8(0x2D, 0x08) -- POWER_CTL measure=1
adxl345.write_u8(0x31, 0x03) -- POWER_CTL range=16g

print(string.format("ADXL345 DEVID       %02x", adxl345.read_u8(0x00)))
print(string.format("ADXL345 BW_RATE     %02x", adxl345.read_u8(0x2C)))
print(string.format("ADXL345 POWER_CTL   %02x", adxl345.read_u8(0x2D)))
print(string.format("ADXL345 DATA_FORMAT %02x", adxl345.read_u8(0x31)))

print(adxl345.read_xyz())
