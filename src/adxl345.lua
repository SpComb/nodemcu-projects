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

    act_inact_ctl = nil, -- adxl345.ACT/INACT_CTL_*
    int_enable    = nil, -- adxl345.INT_*
    int_map       = nil, -- adxl345.INT_* -> INT2, otherwise INT1
    data_format   = nil,

    fifo_mode     = nil, -- adxl345.FIFO_MODE_*
    fifo_trigger  = nil, -- adxl345.FIFO_TRIGGER_*
    fifo_samples  = nil, -- 0-32
  }
}

function app.adxl345.init()
  i2c.setup(app.adxl345.i2c_id, app.adxl345.i2c_sda, app.adxl345.i2c_scl, i2c.SLOW)

  if app.adxl345.int1_pin then
    gpio.mode(app.adxl345.int1_pin, gpio.INT, gpio.FLOAT)
  end
  if adxl345.int2_pin then
    gpio.mode(app.adxl345.int2_pin, gpio.INT, gpio.FLOAT)
  end
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
  adxl345.config({int_map = 0}) -- All INT1

  if handlers.activity then
    adxl345.set_int_enable(adxl345.INT_ACTIVITY)
    app.adxl345.on_int1(function(level, when)
      local int_status = adxl345.read_interrupts()

      if bit.band(int_status, adxl345.INT_ACTIVITY) ~= 0 then
        handlers.activity()
      end
    end)
  end

  adxl345.set_power_ctl(adxl345.POWER_CTL_MEASURE)
end
