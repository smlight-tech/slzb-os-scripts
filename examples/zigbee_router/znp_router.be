#META {"start":1}
# Zigbee router on a TI radio (CC2652 / CC2674) with Z-Stack coordinator (ZNP) firmware, without reflashing it:
# the script configures the radio over the Z-Stack Monitor and Test API (MT) and joins it to a Zigbee network
# as a router.
#
# Before the start:
# - radio mode on the Mode page: Zigbee coordinator (the network socket), not Zigbee Hub
# - nothing connected to this radio (Zigbee2MQTT / ZHA of this coordinator): they would form their own network again
# - open permit join on the network the radio has to join
#
# The script holds the radio UART while it runs (ZB.suspend) and answers the Basic cluster reads of the interview.
# The routing itself runs in the radio. After a radio / device restart the radio is back in the network only with
# the script running ("start": 1 above). Stopping the script hands the UART back to the Zigbee socket.
import ZB
import string

var CHIP = 1                 # radio module number
var CHANNELS = 0x07FFF800    # channels to search, bit n = channel n: 11..26
var EXT_PAN_ID = nil         # extended PAN ID of the network to join ("00124b0001abcdef"), nil = the first open network
var REJOIN = false           # true: leave the network the radio is in and search again
var MANUFACTURER = "SMLIGHT"
var MODEL = "SLZB ZNP router"

class ZnpRouter
  var chip, rx, queue, attrs, tsn

  # Z-Stack device states (ZDO_STATE_CHANGE_IND)
  static DEV_ROUTER = 7

  # NV items
  static NV_STARTUP_OPTION = 0x0003
  static NV_APS_USE_EXT_PANID = 0x0047
  static NV_BDB_NODE_IS_ON_A_NETWORK = 0x0055
  static NV_PRECFGKEYS_ENABLE = 0x0063
  static NV_PANID = 0x0083
  static NV_CHANLIST = 0x0084
  static NV_LOGICAL_TYPE = 0x0087

  def init(chip)
    self.chip = chip
    self.rx = bytes()
    self.queue = []
    self.tsn = 0

    var zstr = def (s)
      var b = bytes()
      b.add(size(s), 1)
      return b + bytes().fromstring(s)
    end

    # Basic cluster: attribute -> [ZCL type, value]
    self.attrs = {
      0x0000: [0x20, bytes("03")],                # ZCL version
      0x0001: [0x20, bytes("01")],                # application version
      0x0003: [0x20, bytes("01")],                # hardware version
      0x0004: [0x42, zstr(MANUFACTURER)],
      0x0005: [0x42, zstr(MODEL)],
      0x0007: [0x30, bytes("01")],                # power source: mains (single phase)
      0x4000: [0x42, zstr("znp-router")],         # software build
    }
  end

  # ---- MT frames: FE <len> <cmd0> <cmd1> <data> <fcs = xor of len .. data> ----

  def send(cmd0, cmd1, data)
    var f = bytes("FE")
    f.add(size(data), 1)
    f.add(cmd0, 1)
    f.add(cmd1, 1)
    f = f + data

    var fcs = 0
    for i: 1 .. size(f) - 1
      fcs ^= f[i]
    end
    f.add(fcs, 1)

    ZB.writeBytes(self.chip, f)
  end

  # a complete frame [cmd0, cmd1, data] out of the received bytes, nil while none
  def parse()
    while size(self.rx) > 0 && self.rx[0] != 0xFE
      self.rx = self.rx[1 .. -1]             # bytes before a start byte
    end

    var rx = self.rx
    if size(rx) < 5 return nil end

    var len = rx[1]
    if size(rx) < len + 5 return nil end

    var fcs = 0
    for i: 1 .. len + 3
      fcs ^= rx[i]
    end

    if fcs != rx[len + 4]                    # a 0xFE inside other data: look for the next one
      self.rx = rx[1 .. -1]
      return self.parse()
    end

    self.rx = rx[len + 5 .. -1]
    return [rx[2], rx[3], rx[4 .. len + 3]]
  end

  # the next frame from the radio, nil after timeout_ms
  def read(timeout_ms)
    var deadline = SLZB.millis() + timeout_ms

    while true
      var f = self.parse()
      if f != nil return f end
      if SLZB.millis() >= deadline return nil end

      var b = ZB.readBytes(self.chip)
      if size(b) > 0
        self.rx = self.rx + b
      else
        SLZB.delay(10)
      end
    end
  end

  # the next frame, those kept by wait() first
  def next(timeout_ms)
    if size(self.queue) > 0 return self.queue.pop(0) end
    return self.read(timeout_ms)
  end

  def keep(f)
    self.queue.push(f)
    if size(self.queue) > 20 self.queue.pop(0) end
  end

  # the data of the frame cmd0 / cmd1, nil after timeout_ms. Other frames are kept for the main loop
  def wait(cmd0, cmd1, timeout_ms)
    for i: 0 .. size(self.queue) - 1
      var f = self.queue[i]
      if f[0] == cmd0 && f[1] == cmd1
        self.queue.remove(i)
        return f[2]
      end
    end

    var deadline = SLZB.millis() + timeout_ms

    while true
      var left = deadline - SLZB.millis()
      if left <= 0 return nil end

      var f = self.read(left)
      if f == nil return nil end
      if f[0] == cmd0 && f[1] == cmd1 return f[2] end

      self.keep(f)
    end
  end

  # SREQ -> the data of its SRSP (cmd0 0x2x -> 0x6x), nil without an answer
  def request(cmd0, cmd1, data, timeout_ms)
    self.send(cmd0, cmd1, data)
    return self.wait((cmd0 & 0x1F) | 0x60, cmd1, timeout_ms)
  end

  # ---- MT commands ----

  def ping()
    return self.request(0x21, 0x01, bytes(), 1000) != nil     # SYS_PING
  end

  # SYS_RESET_REQ, true when the radio reported its restart (SYS_RESET_IND)
  def reset()
    self.queue = []
    self.send(0x41, 0x00, bytes("00"))
    return self.wait(0x41, 0x80, 6000) != nil
  end

  def nv_read(id)
    var d = bytes()
    d.add(id, 2)
    d.add(0, 1)                                                 # offset

    var r = self.request(0x21, 0x08, d, 2000)                  # SYS_OSAL_NV_READ: status, len, value
    if r == nil || r[0] != 0 || r[1] == 0 return nil end
    return r[2 .. 1 + r[1]]
  end

  def nv_write(id, value)
    var d = bytes()
    d.add(id, 2)
    d.add(0, 1)                                                 # offset
    d.add(size(value), 1)
    d = d + value

    var r = self.request(0x21, 0x09, d, 2000)                  # SYS_OSAL_NV_WRITE
    if r == nil || r[0] != 0
      SLZB.log(format("[ZNP router] NV item 0x%04X not written (%s)", id, r == nil ? "no answer" : str(r[0])))
      return false
    end
    return true
  end

  # UTIL_GET_DEVICE_INFO: status, IEEE (8), short address (2), device types (bit 0 coordinator, 1 router, 2 end device), state
  def device_info()
    var r = self.request(0x27, 0x00, bytes(), 1000)
    if r == nil || r[0] != 0 return nil end
    return {"ieee": r[1 .. 8], "short": r.get(9, 2), "types": r[11], "state": r[12]}
  end

  # AF_REGISTER: endpoint 1, Home Automation, range extender, in: Basic + Identify
  def register_ep()
    var d = bytes()
    d.add(1, 1)
    d.add(0x0104, 2)
    d.add(0x0008, 2)
    d.add(0, 1)          # device version
    d.add(0, 1)          # latency
    d.add(2, 1)
    d.add(0x0000, 2)
    d.add(0x0003, 2)
    d.add(0, 1)          # no output clusters

    var r = self.request(0x24, 0x00, d, 2000)
    return r != nil && (r[0] == 0 || r[0] == 0xB8)              # 0xB8: registered before
  end

  # ---- configuration and joining ----

  # role router from scratch: clear the network state and the configuration, write the router settings
  def configure(chanMask, extPan)
    SLZB.log("[ZNP router] configuring the radio as a router (its network and configuration are cleared)")

    if !self.nv_write(self.NV_STARTUP_OPTION, bytes("03")) return false end    # clear state + config at the next start
    if !self.reset() return false end

    var ch = bytes()
    ch.add(chanMask, 4)

    if !self.nv_write(self.NV_LOGICAL_TYPE, bytes("01")) return false end
    if !self.nv_write(self.NV_PANID, bytes("FFFF")) return false end           # any PAN
    if !self.nv_write(self.NV_APS_USE_EXT_PANID, extPan) return false end
    if !self.nv_write(self.NV_PRECFGKEYS_ENABLE, bytes("00")) return false end # network key from the trust center
    if !self.nv_write(self.NV_CHANLIST, ch) return false end

    return self.reset()                                          # the logical type is read at the start
  end

  # APP_CNF_BDB_SET_CHANNEL: primary = chanMask, secondary none
  def set_channels(chanMask)
    var p = bytes("01")
    p.add(chanMask, 4)
    var s = bytes("00")
    s.add(0, 4)

    return self.request(0x2F, 0x08, p, 1000) != nil && self.request(0x2F, 0x08, s, 1000) != nil
  end

  # ZDO_STATE_CHANGE_IND DEV_ROUTER within timeout_ms; other frames are kept
  def wait_router(timeout_ms)
    var deadline = SLZB.millis() + timeout_ms

    while SLZB.millis() < deadline
      var f = self.read(deadline - SLZB.millis())
      if f == nil return false end

      if f[0] == 0x45 && f[1] == 0xC0                          # ZDO_STATE_CHANGE_IND
        if f[2][0] == self.DEV_ROUTER return true end

      elif f[0] == 0x4F && f[1] == 0x80                        # APP_CNF_BDB_COMMISSIONING_NOTIFICATION: status, mode, remaining
        # network steering (mode 1) ended without success: 2 no open network, 7 trust center link key exchange failed, ...
        # (other modes report e.g. 13 "network restored": not a failure)
        if f[2][1] == 1 && f[2][0] >= 2
          SLZB.log("[ZNP router] network steering: no network let the radio in (status " .. f[2][0] .. ")")
          return false
        end

      else
        self.keep(f)
      end
    end

    return false
  end

  # one network steering pass (APP_CNF_BDB_START_COMMISSIONING, mode network steering)
  def steer()
    SLZB.log("[ZNP router] searching for an open network...")

    var r = self.request(0x2F, 0x05, bytes("02"), 2000)
    if r == nil || r[0] != 0 return false end

    return self.wait_router(90000)
  end

  # the radio in the network as a router: true, false when it cannot be a router at all
  def start(chanMask, extPan, rejoin)
    if !self.ping()
      SLZB.log("[ZNP router] the radio does not answer MT commands: Z-Stack coordinator firmware needed")
      return false
    end

    var info = self.device_info()
    if info == nil || !(info["types"] & 0x02)
      SLZB.log("[ZNP router] this radio firmware has no router role compiled in: flash the router firmware instead")
      return false
    end

    var lt = self.nv_read(self.NV_LOGICAL_TYPE)
    if rejoin || lt == nil || lt[0] != 1
      if !self.configure(chanMask, extPan)
        SLZB.log("[ZNP router] configuration failed")
        return false
      end
    end

    if !self.set_channels(chanMask) || !self.register_ep()
      SLZB.log("[ZNP router] radio setup failed")
      return false
    end

    var onNwk = self.nv_read(self.NV_BDB_NODE_IS_ON_A_NETWORK)

    if onNwk != nil && onNwk[0] == 1
      var r = self.request(0x25, 0x40, bytes("6400"), 5000)    # ZDO_STARTUP_FROM_APP, 100 ms: the network kept in NV
      if r != nil && r[0] == 0 && self.wait_router(30000)
        info = self.device_info()
        SLZB.log(format("[ZNP router] back in the network, address 0x%04X", info != nil ? info["short"] : 0))
        return true
      end
      SLZB.log("[ZNP router] the saved network did not come back, searching again")
    end

    while !self.steer()
      SLZB.log("[ZNP router] open permit join on the network to join; next try in 10 s")
      SLZB.delay(10000)
    end

    info = self.device_info()
    if info != nil
      SLZB.log(format("[ZNP router] joined as a router, address 0x%04X, IEEE %s", info["short"], info["ieee"].reverse().tohex()))
    end
    return true
  end

  # ---- running ----

  # AF_INCOMING_MSG: group (2), cluster (2), source (2), source ep, dest ep, broadcast, LQI, security, time (4), seq, len, ZCL frame
  def on_af(d)
    var cluster = d.get(2, 2)
    var src = d.get(4, 2)
    var srcEp = d[6]
    var dstEp = d[7]
    var zcl = d[17 .. 16 + d[16]]

    if cluster != 0x0000 || size(zcl) < 3 return end
    var fc = zcl[0]
    if (fc & 0x07) != 0 || zcl[2] != 0x00 return end            # a global, not manufacturer specific Read Attributes only

    var z = bytes()
    z.add(0x18, 1)                                              # global, server to client, no default response
    z.add(zcl[1], 1)                                            # sequence number of the request
    z.add(0x01, 1)                                              # Read Attributes Response

    var i = 3
    while i + 1 < size(zcl)
      var id = zcl.get(i, 2)
      var a = self.attrs.find(id)
      z.add(id, 2)

      if a == nil
        z.add(0x86, 1)                                          # UNSUPPORTED_ATTRIBUTE
      else
        z.add(0x00, 1)
        z.add(a[0], 1)
        z = z + a[1]
      end
      i += 2
    end

    self.tsn = (self.tsn + 1) & 0xFF

    var req = bytes()
    req.add(src, 2)
    req.add(srcEp, 1)
    req.add(dstEp, 1)
    req.add(cluster, 2)
    req.add(self.tsn, 1)
    req.add(0, 1)                                               # options
    req.add(30, 1)                                              # radius
    req.add(size(z), 1)
    req = req + z

    self.request(0x24, 0x01, req, 1000)                         # AF_DATA_REQUEST
  end

  # until the radio restarts (SYS_RESET_IND: a Leave, a crash)
  def serve()
    while true
      var f = self.next(1000)

      if f == nil
        continue
      elif f[0] == 0x44 && f[1] == 0x81                         # AF_INCOMING_MSG
        self.on_af(f[2])
      elif f[0] == 0x45 && f[1] == 0xC0                         # ZDO_STATE_CHANGE_IND
        SLZB.log("[ZNP router] radio state " .. f[2][0])
      elif f[0] == 0x41 && f[1] == 0x80                         # SYS_RESET_IND
        SLZB.log("[ZNP router] the radio restarted")
        return
      end
    end
  end
end

# extended PAN ID as written ("00124b0001abcdef", "0x..", "00:12:..") -> 8 bytes little endian, all zero for nil
def ext_pan_bytes(s)
  var b = bytes("0000000000000000")
  if s == nil return b end

  var hex = string.replace(string.replace(string.tolower(s), "0x", ""), ":", "")
  if size(hex) != 16 raise "value_error", "EXT_PAN_ID: 16 hex digits expected" end
  return bytes(hex).reverse()
end

if !ZB.isCC(CHIP)
  SLZB.log("[ZNP router] radio " .. CHIP .. " is not a TI CC chip")
  return
end
if ZB.getFirmwareType(CHIP) != ZB.FW_COORDINATOR
  SLZB.log("[ZNP router] radio " .. CHIP .. " needs the Zigbee coordinator firmware")
  return
end
if ZB.getZbClients(CHIP) > 0
  SLZB.log("[ZNP router] disconnect Zigbee2MQTT / ZHA from radio " .. CHIP .. " first")
  return
end

SLZB.delay(6000)

var extPan = ext_pan_bytes(EXT_PAN_ID)

ZB.suspend(CHIP, true)                                          # the UART is the script's now
ZB.readBytes(CHIP)                                              # drop what came before

var router = ZnpRouter(CHIP)
var rejoin = REJOIN

while true
  if !router.start(CHANNELS, extPan, rejoin) break end
  rejoin = false
  router.serve()
end

ZB.suspend(CHIP, false)
