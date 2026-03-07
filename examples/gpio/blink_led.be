#META {"start":0}
# Blink an LED on and off every second
# Change led_pin to match your device's LED GPIO

import GPIO

var led_pin = 46 # blue LED on SLZB-06p7u

GPIO.pinMode(led_pin, GPIO.MOD_OUTPUT)

while true
  GPIO.digitalWrite(led_pin, 1) # LED on
  SLZB.delay(1000)
  GPIO.digitalWrite(led_pin, 0) # LED off
  SLZB.delay(1000)
end
