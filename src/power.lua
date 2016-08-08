power = {
    gpio    = 1,
}

function power.init()
    gpio.mode(power.gpio, gpio.OUTPUT)
end

function power.on()
    gpio.write(1, gpio.HIGH)
end
function power.off()
    gpio.write(1, gpio.LOW)
end

power.init()
power.on()
