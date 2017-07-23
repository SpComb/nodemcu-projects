adxl345_config = {
  ofs_x  = 48, -- 1/64g
  ofs_y  = -6, -- 1/64g
  ofs_z  = 0,  -- 1/64g

  thresh_act    = 10, -- 1/16g
  thresh_inact  = 10, -- 1/16g
  time_inact    = 2,
}
adxl345.init()

adxl345.set_ofs(adxl345_config.ofs_x, adxl345_config.ofs_y, adxl345_config.ofs_z)
adxl345.set_thresh_act(adxl345_config.thresh_act)
adxl345.set_thresh_inact(adxl345_config.thresh_inact)
adxl345.set_time_inact(adxl345_config.time_inact)

adxl345.set_act_inact_ctl(ADXL345_ACT_CTL_AC + ADXL345_ACT_CTL_X + ADXL345_ACT_CTL_Y)
adxl345.set_int_map(0)
adxl345.set_data_format(ADXL345_DATA_FORMAT_FULL_RES + ADXL345_DATA_FORMAT_RANGE_16G)
adxl345.set_fifo_ctl(ADXL345_FIFO_MODE_STREAM, ADXL345_FIFO_TRIGGER_INT1, 16)
adxl345.int_enable(ADXL345_INT_ACTIVITY)
adxl345.power_ctl(ADXL345_POWER_CTL_MEASURE)

adxl345.print_config()

-- Print state, show absolute values
function adxl345_print()
  local fifo_trigger, fifo_entries = adxl345.get_fifo_status()

  print(string.format("ADXL345: FIFO trigger=%s entries=%d ", tostring(fifo_trigger), fifo_entries))

  while fifo_entries > 0 do
    local x, y, z = adxl345.read_xyz()

    print(string.format("ADXL345 @ %2d: X=%+6d Y=%+6d Z=%+6d ", fifo_entries, x, y, z))

    fifo_entries = fifo_entries - 1
  end

  -- clear interrupt
  local int_status = adxl345.read_int()

  print(string.format("ADXL345 INT: %02x", int_status))
end

-- Trigger on changes, show deltas
function adxl345_trigger(event)
  local fifo_trigger, fifo_entries = adxl345.get_fifo_status()

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

    -- XXX: 1/256 <=> 1/16
    if dx1 > adxl345_config.thresh_act * 16 then
      print(string.format("ADXL345 @ %2d: +X %+6d          (d0 %+6d, d1 = %+6d)", i, x, dx0, dx1))
    elseif dx1 < -adxl345_config.thresh_act * 16 then
      print(string.format("ADXL345 @ %2d: -X %+6d          (d0 %+6d, d1 = %+6d)", i, x, dx0, dx1))
    else
      print(string.format("ADXL345 @ %2d:  X %+6d          (d0 %+6d, d1 = %+6d)", i, x, dx0, dx1))
    end

    if dy1 > adxl345_config.thresh_act * 16 then
      print(string.format("ADXL345 @ %2d:          +Y %+6d (d0 %+6d, d1 = %+6d)", i, y, dy0, dy1))
    elseif dy1 < -adxl345_config.thresh_act * 16 then
      print(string.format("ADXL345 @ %2d:          -Y %+6d (d0 %+6d, d1 = %+6d)", i, y, dy0, dy1))
    else
      print(string.format("ADXL345 @ %2d:           Y %+6d (d0 %+6d, d1 = %+6d)", i, y, dy0, dy1))
    end

    x1 = x
    y1 = y
    z1 = z
  end

  -- clear interrupt
  local int_status = adxl345.read_int()

  print(string.format("ADXL345: INT %02x", int_status))
end

if false then
  tmr.alarm(0, 1000, tmr.ALARM_AUTO, function(timer)
    adxl345_print()
  end)
end

if adxl345.int1_pin then
  print("on int1...")
  adxl345.on_int1(function(level, when)
    adxl345_trigger("INT1")
  end)
end
if adxl345.int2_pin then
  adxl345.on_int2(function(level, when)
    adxl345_trigger("INT2")
  end)
end
