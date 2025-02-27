#META {"start":0}
import string
import ZB
import WEBSERVER
import json

var model = SLZB.device_model()
var isEfr32 = model == "SLZB-06M" || model == "SLZB-06Mg24"
var targetCmd = isEfr32 ? 0x0045 : 0x4481 # incomingMessageHandler for efr32 and AF_INCOMING_MSG for cc2652x
var step = 7 # must be '(2 ^ step) - 1' for fast calculation (power of 2)
var zb_devices = {} # create new map

# helper function to build uint16 from 2x uint8
def buildU16(b0, b1)
  return b0 | (b1 << 8)
end

# id - 16 bits of received command. buf - complete packet buffer
def zb_pkt_handler(id, buf)
  #SLZB.log("id: " .. string.hex(id))
  #print(buf)

  if id == targetCmd
    var srcAddr = isEfr32 ? buildU16(buf[20], buf[21]) : buildU16(buf[8], buf[9]) # 16bits sender addr
    var scrAddrS = string.hex(srcAddr) # convert to hex str
    
    if zb_devices.find(scrAddrS)
      zb_devices[scrAddrS] += 1 # inc value
      var actualCount = zb_devices[scrAddrS]
      
      if (actualCount & step) == 0 # log only every 'step' packet (for performance)
        SLZB.log("[" .. scrAddrS .. "] reports: " .. actualCount)
      end
    else
      zb_devices[scrAddrS] = 1 # init walue if not ex
    end
  end

  return false # we can return true if we want block this packet. only for cc2652x
end

def zb_dissconect()
  if ZB.getZbClients() == 0 # wipe stats if there is no clients left
    zb_devices = {} # wipe stats
  end
end

# open <device ip>/script/webhook in your browser
def web_handler(p)
  WEBSERVER.send(200, "application/json", json.dump(zb_devices))
end

ZB.on_disconnect(zb_dissconect)
ZB.on_pkt(zb_pkt_handler)
WEBSERVER.on_webhook(web_handler)