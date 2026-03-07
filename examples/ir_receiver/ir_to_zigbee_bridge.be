#META {"start":1}
# Bridge IR remote buttons to Zigbee device control
# Example: use a TV remote to control a Zigbee lamp
# Ultima devices with IR receiver only!

import IR, ZHB

ZHB.waitForStart(0xff)

var lamp = ZHB.getDevice("Living Room Lamp") # change to your device name

# Change protocol, address, and command values to match your remote
# Use the log_ir_codes.be example first to discover these values
IR.on_receive(def (proto, addr, cmd)
  if proto == IR.NEC && addr == 0x04
    if cmd == 0x08 # power button
      lamp.sendOnOff(1)
      SLZB.log("Lamp ON")
    elif cmd == 0x0A # mute button
      lamp.sendOnOff(0)
      SLZB.log("Lamp OFF")
    elif cmd == 0x15 # volume up
      lamp.sendBri(254)
      SLZB.log("Lamp BRIGHT")
    elif cmd == 0x09 # volume down
      lamp.sendBri(50)
      SLZB.log("Lamp DIM")
    end
  end
end)

SLZB.log("IR-to-Zigbee bridge active")
