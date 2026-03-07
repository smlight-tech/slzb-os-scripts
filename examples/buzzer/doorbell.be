#META {"start":1}
# Play a doorbell sound when a Zigbee button is pressed
# Ultima3 only! Requires a paired Zigbee button

import BUZZER, ZHB

ZHB.waitForStart(0xff)

def on_action(action, dev)
  if dev.getName() == "Door Button" && action == "single"
    BUZZER.play("Doorbell:d=4,o=5,b=100:8e6,8c6")
  end
end

ZHB.on_action(on_action)
