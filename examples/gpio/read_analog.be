#META {"start":0}
# Read voltage on an analog GPIO pin every 2 seconds
# Range: 0-4096 (0V - 3.3V)
# Change sensor_pin to match your wiring

import GPIO

var sensor_pin = 4

GPIO.pinMode(sensor_pin, GPIO.MOD_INPUT)

while true
  var raw = GPIO.analogRead(sensor_pin)
  var voltage = (raw * 3.3) / 4096

  SLZB.log("Raw: " .. raw .. " Voltage: " .. voltage .. "V")

  SLZB.delay(2000)
end
