adxl345 = {
  i2c_id    = 0,
  i2c_sda   = 12,
  i2c_scl   = 11,
  i2c_addr  = 0x53, -- SDO pulled to ground

  int1_pin  = 3,
  int2_pin  = nil,

  devid     = 0xE5,

  offset_x  = 48,
  offset_y  = -6,
  offset_z  = 0,

  threshold_active   = 10, -- 50 * 16 / 256,
  threshold_inactive = 10, -- 50 * 16 / 256,
  time_inactive      = 2,
}

function adxl345.init()
  i2c.setup(adxl345.i2c_id, adxl345.i2c_sda, adxl345.i2c_scl, i2c.SLOW)

  if adxl345.int1_pin then
    gpio.mode(adxl345.int1_pin, gpio.INT, gpio.FLOAT)
  end
  if adxl345.int2_pin then
    gpio.mode(adxl345.int2_pin, gpio.INT, gpio.FLOAT)
  end
end

function adxl345.on_int1(handler)
  if adxl345.int1_pin then
    gpio.trig(adxl345.int1_pin, "up", handler)
  end
end
function adxl345.on_int2(handler)
  if adxl345.int2_pin then
    gpio.trig(adxl345.int2_pin, "up", handler)
  end
end

function adxl345.send(...)
  i2c.start(adxl345.i2c_id)
  i2c.address(adxl345.i2c_id, adxl345.i2c_addr, i2c.TRANSMITTER)
  i2c.write(adxl345.i2c_id, ...)
  i2c.stop(adxl345.i2c_id)
end

function adxl345.recv(len)
  local data

  i2c.start(adxl345.i2c_id)
  i2c.address(adxl345.i2c_id, adxl345.i2c_addr, i2c.RECEIVER)
  data = i2c.read(adxl345.i2c_id, len)
  i2c.stop(adxl345.i2c_id)

  return data
end

function adxl345.read_struct(reg, fmt)
  local len = struct.size(fmt)

  adxl345.send(reg)

  return struct.unpack(fmt, adxl345.recv(len))
end

function adxl345.write_struct(reg, fmt, ...)
  adxl345.send(reg, struct.pack(fmt, ...))
end

function adxl345.read_u8(reg)
  local val, _ = adxl345.read_struct(reg, "B")

  return val
end
function adxl345.write_u8(reg, val)
  return adxl345.write_struct(reg, "B", val)
end

function adxl345.set_offset(x, y, z)
  adxl345.write_struct(0x1E, "<bbb", x, y, z)
end

function adxl345.read_xyz()
  local x, y, z = adxl345.read_struct(0x32, "<hhh")

  return x, y, z
end
