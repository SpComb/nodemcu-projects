-- ATX PSU
atx_psu = {
    gpio    = 1,
}

function atx_psu.init()
    gpio.mode(atx_psu.gpio, gpio.OUTPUT)
end

function atx_psu.on()
    gpio.write(atx_psu.gpio, gpio.HIGH)
end
function atx_psu.off()
    gpio.write(atx_psu.gpio, gpio.LOW)
end
