#META {"start":0}
import string
import ZB
import WEBSERVER
import json

var step = 7 # must be '(2 ^ step) - 1' for fast calculation (power of 2)
var zb_devices = {} # create new map

# id - 16 bits of received command. buf - complete packet buffer
def zb_pkt_handler(id, buf)
  if id == 0x4481 # AF_INCOMING_MSG
    var srcAddr = buf[8] | (buf[9] << 8) # 16bits SrcAddr
    var scrAddrS = string.hex(srcAddr) # convert to hex str
    
    if zb_devices.find(scrAddrS)
      zb_devices[scrAddrS] += 1 # inc value
      var actualCount = zb_devices[scrAddrS]
      
      if (actualCount & step) == 0 # log only every 'step' packet
        SLZB.log("[" .. scrAddrS .. "] reports: " .. actualCount)
      end
    else
      zb_devices[scrAddrS] = 1 # init walue if not ex
    end
  end

  return false # we can return true if we want block this packet
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