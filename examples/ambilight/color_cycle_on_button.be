#META {"start":1}
# Cycle through LED colors with a Zigbee button
# Single click = next color, Double click = LEDs off
# Ultima devices only! Requires a paired Zigbee button

import ZHB

ZHB.waitForStart(0xff)

var colors = [0xFF0000, 0x00FF00, 0x0000FF, 0xFFFF00, 0xFF00FF, 0x00FFFF]
var idx = 0

def on_action(action, dev)
  if dev.getName() != "My Button" # change to your button name
    return
  end

  if action == "single"
    AMBILIGHT.setColor(colors[idx])
    AMBILIGHT.setBrightness(200)
    AMBILIGHT.setEffect(AMBILIGHT.SOLID)
    idx = (idx + 1) % size(colors)
  elif action == "double"
    AMBILIGHT.setEffect(AMBILIGHT.OFF)
  end
end

ZHB.on_action(on_action)
