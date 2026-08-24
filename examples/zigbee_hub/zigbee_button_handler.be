#META {"start":0}
# This script uses the "Zigbee Hub" mode and a paired Zigbee button with an encoder to control the state and brightness of WLED LED strip controller.
# A single press of the button turns the LED strip on and off.
# Rotate button clockwise to increase the brightness, counterclockwise to decrease it.
# BUZZER available only on Ultima

import ZHB, BUZZER, WLED, NETWORK

var wName = "192.168.31.134" # WLED device IP
var startBr = nil

NETWORK.waitReady(0xff) # waiting for network interface to be ready
ZHB.waitForStart(0xff) # waiting for Zigbee Hub

# waiting for WLED device to be online
while (startBr == nil)
  # We use "try except" here because WLED.get_state() will throw an exception if the target device is offline.
  try
    startBr = int(WLED.get_state(wName)["bri"])
  except ..
    SLZB.delay(5000)
  end
end

def handleBri(inc)
  if (inc)
    startBr += 20
    
    if (startBr > 255)
      BUZZER.playPreset(BUZZER.Snd_Beep)
      startBr = 255
    end
  else
    startBr -= 20
    
    if (startBr < 0)
      startBr = 0
    end
  end
  
  WLED.set_brightness(wName, startBr)
end

def button_handler(action, dev)
  if (dev.getName() == "your button name")
    if (action == "btn_single_1")
      BUZZER.playPreset(BUZZER.Snd_Notify)
      WLED.toggle(wName)
      
    elif (action == "rotate_right_1")
      handleBri(1)
        
    elif (action == "rotate_left_1")
      handleBri(0)
    end
  end
end

ZHB.on_action(button_handler)