adxl345 = {
  i2c_id    = 0,
  i2c_sda   = 12,
  i2c_scl   = 11,
  i2c_addr  = 0x53, -- SDO pulled to ground

  int1_pin  = 3,
  int2_pin  = nil,

  devid     = 0xE5,

  config    = {
    ofs_x         = nil, -- 1/64g
    ofs_y         = nil, -- 1/64g
    ofs_z         = nil, -- 1/64g

    thresh_act    = nil, -- 1/16g
    thresh_inact  = nil, -- 1/16g
    time_inact    = nil, -- seconds

    act_inact_ctl = nil, -- ADXL345_ACT/INACT_CTL_*
    int_enable    = nil, -- ADXL345_INT_*
    int_map       = nil, -- ADXL345_INT_* -> INT2, otherwise INT1
    data_format   = nil,

    fifo_mode     = nil, -- ADXL345_FIFO_MODE_*
    fifo_int      = nil, -- ADXL345_FIFO_INT_*
    fifo_samples  = nil, -- 0-32
  }
}

ADXL345_ACT_CTL_DC   = 0x00
ADXL345_ACT_CTL_AC   = 0x80
ADXL345_ACT_CTL_X    = 0x40
ADXL345_ACT_CTL_Y    = 0x20
ADXL345_ACT_CTL_Z    = 0x10
ADXL345_INACT_CTL_DC = 0x00
ADXL345_INACT_CTL_AC = 0x08
ADXL345_INACT_CTL_X  = 0x04
ADXL345_INACT_CTL_Y  = 0x02
ADXL345_INACT_CTL_Z  = 0x01

ADXL345_POWER_CTL_FLAGS_MASK  = 0x3C
ADXL345_POWER_CTL_WAKEUP_MASK = 0x02
ADXL345_POWER_CTL_LINK        = 0x20
ADXL345_POWER_CTL_AUTO_SLEEP  = 0x10
ADXL345_POWER_CTL_MEASURE     = 0x08
ADXL345_POWER_CTL_SLEEP       = 0x04

ADXL345_INT_DATA_READY = 0x80
ADXL345_INT_SINGLE_TAP = 0x40
ADXL345_INT_DOUBLE_TAP = 0x20
ADXL345_INT_ACTIVITY   = 0x10
ADXL345_INT_INACTIVITY = 0x08
ADXL345_INT_FREE_FALL  = 0x04
ADXL345_INT_WATERMARK  = 0x02
ADXL345_INT_OVERRUN    = 0x01

ADXL345_DATA_FORMAT_SELF_TEST  = 0x80
ADXL345_DATA_FORMAT_SPI        = 0x40
ADXL345_DATA_FORMAT_INT_INVERT = 0x20
ADXL345_DATA_FORMAT_FULL_RES   = 0x08
ADXL345_DATA_FORMAT_JUSTIFY    = 0x04
ADXL345_DATA_FORMAT_RANGE_2G   = 0x00
ADXL345_DATA_FORMAT_RANGE_4G   = 0x01
ADXL345_DATA_FORMAT_RANGE_8G   = 0x02
ADXL345_DATA_FORMAT_RANGE_16G  = 0x03

ADXL345_FIFO_MODE_MASK    = 0xC0
ADXL345_FIFO_TRIGGER_MASK = 0x20
ADXL345_FIFO_SAMPLES_MASK = 0x1F
ADXL345_FIFO_MODE_BYPASS  = 0x00
ADXL345_FIFO_MODE_FIFO    = 0x40
ADXL345_FIFO_MODE_STREAM  = 0x80
ADXL345_FIFO_MODE_TRIGGER = 0xC0
ADXL345_FIFO_TRIGGER_INT1 = 0x00
ADXL345_FIFO_TRIGGER_INT2 = 0x20

ADXL345_FIFO_STATUS_TRIG         = 0x80
ADXL345_FIFO_STATUS_ENTRIES_MASK = 0x3F -- XXX: or 0x7F?

function adxl345.init(config)
  adxl345.config = config

  i2c.setup(adxl345.i2c_id, adxl345.i2c_sda, adxl345.i2c_scl, i2c.SLOW)

  if adxl345.int1_pin then
    gpio.mode(adxl345.int1_pin, gpio.INT, gpio.FLOAT)
  end
  if adxl345.int2_pin then
    gpio.mode(adxl345.int2_pin, gpio.INT, gpio.FLOAT)
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

function adxl345.set_ofs(x, y, z)
  adxl345.write_struct(0x1E, "<bbb", x, y, z)
end
function adxl345.get_ofs()
  local x, y, z = adxl345.read_struct(0x1E, "<bbb")

  return x, y, z -- 1/64
end

function adxl345.get_thresh_act()
  return adxl345.read_u8(0x24) -- 1/16
end
function adxl345.set_thresh_act(g16)
  adxl345.write_u8(0x24, g16)
end

function adxl345.get_thresh_inact()
  return adxl345.read_u8(0x25) -- 1/16
end
function adxl345.set_thresh_inact(g16)
  adxl345.write_u8(0x25, g16)
end

function adxl345.set_time_inact(s)
  adxl345.write_u8(0x26, s)
end
function adxl345.set_act_inact_ctl(flags)
  adxl345.write_u8(0x26, flags)
end
function adxl345.set_int_map(flags)
  adxl345.write_u8(0x2F, flags)
end
function adxl345.set_data_format(flags)
  adxl345.write_u8(0x31, flags)
end
function adxl345.set_fifo_ctl(mode, trigger, samples)
  adxl345.write_u8(0x38, bit.bor(
    bit.band(ADXL345_FIFO_MODE_MASK, mode),
    bit.band(ADXL345_FIFO_TRIGGER_MASK, trigger),
    bit.band(ADXL345_FIFO_SAMPLES_MASK, samples)
  ))
end
function adxl345.get_fifo_status()
  local fifo_status = adxl345.read_u8(0x39)

  local fifo_trigger = bit.band(fifo_status, ADXL345_FIFO_STATUS_TRIG)
  local fifo_entries = bit.band(fifo_status, ADXL345_FIFO_STATUS_ENTRIES_MASK)

  return fifo_trigger ~= 0, fifo_entries
end

function adxl345.setup(config)
  if config.ofs_x and config.ofs_y and config.ofs_z then
    adxl345.set_ofs(config.ofs_x, config.ofs_y, config.ofs_z)
  end

  if config.thresh_act then
    adxl345.set_thresh_act(config.thresh_act)
  end
  if config.thresh_inact then
    adxl345.set_thresh_inact(config.thresh_inact)
  end
  if config.time_inact then
    adxl345.set_time_inact(config.time_inact)
  end
  if config.act_inact_ctl then
    adxl345.set_act_inact_ctl(config.act_inact_ctl)
  end
  if config.int_map then
    adxl345.set_int_map(config.int_map)
  end
  if config.data_format then
    adxl345.set_data_format(config.data_format)
  end
  if config.fifo_mode and config.fifo_int and config.fifo_samples then
    adxl345.set_fifo_ctl(config.fifo_mode, config.fifo_int, config.fifo_samples)
  end
end

function adxl345.power_ctl(flags)
  adxl345.write_u8(0x2D, bit.bor(
    bit.band(ADXL345_POWER_CTL_FLAGS_MASK, flags)
  ))
end

function adxl345.int_disable()
  adxl345.write_u8(0x2E, 0)
end
function adxl345.int_enable(mask)
  adxl345.write_u8(0x2E, mask)
end
function adxl345.read_int() -- clears interrupt
  return adxl345.read_u8(0x30)
end
function adxl345.on_int1(handler)
  gpio.trig(adxl345.int1_pin, "up", handler)
end
function adxl345.on_int2(handler)
  gpio.trig(adxl345.int2_pin, "up", handler)
end

function adxl345.print_config()
  print(string.format("ADXL345 DEVID         %02x", adxl345.read_u8(0x00)))
  print(string.format("ADXL345 OFFSET        %+3d %+3d %+3d", adxl345.get_ofs()))
  print(string.format("ADXL345 THRESH_ACT    %02x", adxl345.get_thresh_act()))
  print(string.format("ADXL345 THRESH_INACT  %02x", adxl345.get_thresh_inact()))
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
end

function adxl345.read_xyz()
  local x, y, z = adxl345.read_struct(0x32, "<hhh")

  return x, y, z
end
