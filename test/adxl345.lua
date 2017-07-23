adxl345_config = {
  ofs_x  = 48, -- 1/64g
  ofs_y  = -6, -- 1/64g
  ofs_z  = 0,  -- 1/64g

  thresh_act    = 10, -- 1/16g
  thresh_inact  = 10, -- 1/16g
  time_inact    = 2,

  act_inact_ctl = ADXL345_ACT_CTL_AC + ADXL345_ACT_CTL_X + ADXL345_ACT_CTL_Y,
  int_map  = 0,
  data_format = ADXL345_DATA_FORMAT_FULL_RES + ADXL345_DATA_FORMAT_RANGE_16G,
  fifo_mode = ADXL345_FIFO_MODE_STREAM,
  fifo_trigger = ADXL345_FIFO_TRIGGER_INT1,
  fifo_samples = 16,
}

-- Print state, show absolute values
function adxl345_print()
  for i, xyz in ipairs(app.adxl345.read_fifo()) do
    print(string.format("ADXL345: X=%+6d Y=%+6d Z=%+6d @ %d ", xyz.x, xyz.y, xyz.z, i))
  end
end

-- Trigger on changes, show deltas
function adxl345_trigger(event)
  local x0, y0, z0
  local x1, y1, z1

  for i, xyz in ipairs(app.adxl345.read_fifo()) do
    local x = xyz.x
    local y = xyz.y
    local z = xyz.z

    print(string.format("ADXL345:  X=%+6d  Y=%+6d  Z=%+6d @ %d", x, y, z, i))

    if i == 1 then
      x0 = x
      y0 = y
      z0 = z
    else
      local ex, ey

      local dx0 = x - x0
      local dy0 = y - y0
      local dz0 = z - z0

      local dx1 = x - x1
      local dy1 = y - y1
      local dz1 = z - z1

      -- 1/256 <=> 1/16
      if dx1 * 16 > adxl345_config.thresh_act * 256 then
        ex = "+X"
      elseif dx1 * 16 < -adxl345_config.thresh_act * 256 then
        ex = "-X"
      else
        ex = "  "
      end

      if dy1 * 16 > adxl345_config.thresh_act * 256 then
        ey = "+Y"
      elseif dy1 * 16 < -adxl345_config.thresh_act * 256 then
        ey = "-Y"
      else
        ey = "  "
      end

      print(string.format("ADXL345: %s %+6d %s %+6d", ex, dx1, ey, dy1))
    end

    x1 = x
    y1 = y
    z1 = z
  end

  -- clear interrupt
  local int_status = app.adxl345.read_int()

  print(string.format("ADXL345: INT %02x", int_status))
end

app.adxl345.init()
app.adxl345.setup(adxl345_config)
app.adxl345.int_enable(ADXL345_INT_ACTIVITY)
app.adxl345.power_ctl(ADXL345_POWER_CTL_MEASURE)
app.adxl345.print_config()

tmr.alarm(0, 1000, tmr.ALARM_AUTO, function(timer)
  adxl345_print()
end)

if app.adxl345.int1_pin then
  app.adxl345.on_int1(function(level, when)
    adxl345_trigger("INT1")
  end)
end
if app.adxl345.int2_pin then
  app.adxl345.on_int2(function(level, when)
    adxl345_trigger("INT2")
  end)
end
