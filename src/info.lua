version_major, version_minor, version_dev, chip_id, flash_id, flash_size, flash_mode, flash_speed = node.info()

print("Version: " .. version_major .. "." .. version_minor .. "." .. version_dev)
print("Flash: id=" .. flash_id .. ", size=" .. flash_size .. ", mode=" .. flash_mode .. ", speed=" .. flash_speed)
