#META {"start":1}
# Use the physical device button to toggle a Zigbee relay
# Short press = toggle on/off, Long press = turn off
# Requires a paired Zigbee relay

import BUTTON
import ZHB

ZHB.waitForStart(0xff)

var relay = ZHB.getDevice("My Relay") # change to your device name
var state = false

def press_handler(press_type)
  if press_type == 0 # short press
    state = !state
    relay.sendOnOff(state ? 1 : 0)
    SLZB.log("Relay " .. (state ? "ON" : "OFF"))
  elif press_type == 1 # long press
    relay.sendOnOff(0)
    state = false
    SLZB.log("Relay OFF (long press)")
  end
end

BUTTON.on_press(0, press_handler)
