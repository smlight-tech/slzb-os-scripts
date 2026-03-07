#META {"start":1}
import IR
# Log all received IR codes to the console
# Useful for discovering your remote's protocol, address, and command values
# Ultima devices with IR receiver only!

IR.on_receive(def (proto, addr, cmd)
  SLZB.log("IR received — protocol: " .. proto .. " address: " .. addr .. " command: " .. cmd)
end)

SLZB.log("IR receiver listening... point a remote at the device and press buttons")
