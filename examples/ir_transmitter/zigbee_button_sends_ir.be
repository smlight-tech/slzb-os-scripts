#META {"start":1}
# Use a Zigbee button to send IR commands to a TV
# Single click = power, Double click = mute
# Ultima devices with IR transmitter only!

import ZHB

ZHB.waitForStart(0xff)

def on_action(action, dev)
  if dev.getName() != "My Button" # change to your button name
    return
  end

  if action == "single"
    IR.send(IR.NEC, 0x04, 0x08) # power
    SLZB.log("IR: Power sent")
  elif action == "double"
    IR.send(IR.NEC, 0x04, 0x0A) # mute
    SLZB.log("IR: Mute sent")
  end
end

ZHB.on_action(on_action)
