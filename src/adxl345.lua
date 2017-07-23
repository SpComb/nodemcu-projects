app.adxl345 = {
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
    fifo_trigger  = nil, -- ADXL345_FIFO_TRIGGER_*
    fifo_samples  = nil, -- 0-32
  }
}

ADXL345_REG_DEVID = 0x00
ADXL345_REG_OFSX = 0x1E
ADXL345_REG_OFSY = 0x1F
ADXL345_REG_OFSZ = 0x20
ADXL345_REG_THRES_ACT = 0x24
ADXL345_REG_THRES_INACT = 0x25
ADXL345_REG_TIME_INACT = 0x26
ADXL345_REG_ACT_INACT_CTL = 0x27
ADXL345_REG_POWER_CTL = 0x2D
ADXL345_REG_INT_ENABLE = 0x2E
ADXL345_REG_INT_MAP = 0x2F
ADXL345_REG_DATA_FORMAT = 0x31
ADXL345_REG_DATA = 0x30 -- X0 X1 Y0 Y1 Z0 Z1
ADXL345_REG_FIFO_CTL = 0x38
ADXL345_REG_FIFO_STATUS = 0x39

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

function app.adxl345.init()
  i2c.setup(app.adxl345.i2c_id, app.adxl345.i2c_sda, app.adxl345.i2c_scl, i2c.SLOW)

  adxl345.setup()

  if app.adxl345.int1_pin then
    gpio.mode(app.adxl345.int1_pin, gpio.INT, gpio.FLOAT)
  end
  if adxl345.int2_pin then
    gpio.mode(app.adxl345.int2_pin, gpio.INT, gpio.FLOAT)
  end
end

function app.adxl345.setup(config)
  if config.ofs_x and config.ofs_y and config.ofs_z then
    adxl345.set_offset(config.ofs_x, config.ofs_y, config.ofs_z)
  end

  if config.thresh_act then
    adxl345.set(ADXL345_REG_THRES_ACT, config.thresh_act)
  end
  if config.thresh_inact then
    adxl345.set(ADXL345_REG_THRES_INACT, config.thresh_inact)
  end
  if config.time_inact then
    adxl345.set(ADXL345_REG_TIME_INACT, config.time_inact)
  end
  if config.act_inact_ctl then
    adxl345.set(ADXL345_REG_ACT_INACT_CTL, config.act_inact_ctl)
  end
  if config.int_map then
    adxl345.set(ADXL345_REG_INT_MAP, config.int_map)
  end
  if config.data_format then
    adxl345.set(ADXL345_REG_DATA_FORMAT, config.data_format)
  end
  if config.fifo_mode and config.fifo_trigger and config.fifo_samples then
    adxl345.set_fifo_ctl(config.fifo_mode, config.fifo_trigger, config.fifo_samples)
  end
end

function app.adxl345.power_ctl(flags)
  adxl345.set(0x2D, bit.bor(
    bit.band(ADXL345_POWER_CTL_FLAGS_MASK, flags)
  ))
end

function app.adxl345.int_disable()
  adxl345.set(0x2E, 0)
end
function app.adxl345.int_enable(mask)
  adxl345.set(0x2E, mask)
end
function app.adxl345.read_int() -- clears interrupt
  return adxl345.get(0x30)
end
function app.adxl345.on_int1(handler)
  gpio.trig(app.adxl345.int1_pin, "up", handler)
end
function app.adxl345.on_int2(handler)
  gpio.trig(app.adxl345.int2_pin, "up", handler)
end

function app.adxl345.print_config()
  print(string.format("ADXL345 DEVID         %02x", adxl345.get(0x00)))
  print(string.format("ADXL345 OFFSET        %+3d %+3d %+3d", adxl345.get_offset()))
  print(string.format("ADXL345 THRESH_ACT    %02x", adxl345.get(0x24)))
  print(string.format("ADXL345 THRESH_INACT  %02x", adxl345.get(0x25)))
  print(string.format("ADXL345 TIME_INACT    %02x", adxl345.get(0x26)))
  print(string.format("ADXL345 ACT_INACT_CTL %02x", adxl345.get(0x27)))
  print(string.format("ADXL345 BW_RATE       %02x", adxl345.get(0x2C)))
  print(string.format("ADXL345 POWER_CTL     %02x", adxl345.get(0x2D)))
  print(string.format("ADXL345 INT_ENABLE    %02x", adxl345.get(0x2E)))
  print(string.format("ADXL345 INT_MAP       %02x", adxl345.get(0x2F)))
  print(string.format("ADXL345 INT_SOURCE    %02x", adxl345.get(0x30)))
  print(string.format("ADXL345 DATA_FORMAT   %02x", adxl345.get(0x31)))
  print(string.format("ADXL345 FIFO_CTL      %02x", adxl345.get(0x38)))
  print(string.format("ADXL345 FIFO_STATUS   %02x", adxl345.get(0x39)))
end

function app.adxl345.start(handlers)
  app.adxl345.set_int_map(0) -- All INT1

  if handlers.activity then
    app.adxl345.int_enable(ADXL345_INT_ACTIVITY)
    app.adxl345.on_int1(function(level, when)
      local int_status = adxl345.read_int()

      if bit.band(int_status, ADXL345_INT_ACTIVITY) ~= 0 then
        handlers.activity()
      end
    end)
  end

  app.adxl345.power_ctl(ADXL345_POWER_CTL_MEASURE)
end

function app.adxl345.read_xyz()
  return adxl345.read()
end

-- Return { {x, y, z} }
function app.adxl345.read_fifo()
  local entries = {}
  local fifo_trigger, fifo_entries = adxl345.get_fifo_status()

  print(string.format("ADXL345: FIFO trigger=%s entries=%d ", tostring(fifo_trigger), fifo_entries))

  for i = 1, fifo_entries do
    local x, y, z = adxl345.read()

    table.insert(entries, {x = x, y = y, z = z})
  end

  return entries
end
