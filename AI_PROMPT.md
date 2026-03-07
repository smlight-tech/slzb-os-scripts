# SLZB-OS Berry Scripting — AI Agent Reference

Berry scripts run on SMLIGHT Zigbee coordinators (SLZB-06x, MRx, Ultima). Scripts start with `#META {"start":1}` (auto) or `#META {"start":0}` (manual). Space after `#META` required. `SLZB` module is auto-loaded, all others need `import`. Event callbacks: no `delay()`, no infinite loops, return fast. `SLZB.log()` max 1024 chars. Only one script can use HTTP at a time. For detailed docs, read the linked files for the modules you need.

## SLZB — Core (auto-loaded, no import needed)
```
SLZB.delay(ms)          # pause execution, max ~1193 hours
SLZB.log(text)          # print to debug console (max 1024 chars!)
SLZB.reboot()           # reboot device
SLZB.millis() → int     # ms since boot
SLZB.freeHeap() → int   # free RAM bytes
SLZB.deviceModel() → str  # e.g. "SLZB-06P7" (since v2.8.2.dev1)
```
Details: [docs/modules/slzb.md](docs/modules/slzb.md)

## ZB — Zigbee Chip (v2.8.0) `import ZB`
```
ZB.reboot()                    # reboot zigbee chip
ZB.writeBytes(bytes) → int     # send raw bytes, returns count
ZB.readBytes() → bytes         # read bytes (call ZB.suspend(true) first!)
ZB.availableBytes() → int      # bytes available to read
ZB.getZbClients() → int        # connected socket clients
ZB.suspend(bool)               # stop/resume socket processing
ZB.flashMode()                 # enter firmware mode
ZB.routerPairMode()            # start pairing (router firmware)
# Events (since v2.8.2.dev0):
ZB.on_pkt(def(id, buf) end)           # packet received; return true to block (CC2652x only)
ZB.on_connect(def(ip, id) end)        # client connected; return true to reject
ZB.on_disconnect(def(id) end)         # client disconnected
```
Details: [docs/modules/zb.md](docs/modules/zb.md)

## ZHB — Zigbee Hub (v2.9.6) `import ZHB`
```
ZHB.waitForStart(timeout)                # wait for hub init, 255=forever
ZHB.getDevice(name|nwk|ieee) → ZigbeeDevice  # get by name(str), addr(int), or IEEE(str "0x...")
ZHB.permitJoin(time, addr?)              # open network (since v3.0.6)
# ZigbeeDevice methods:
dev.sendOnOff(state, ch?)       # 1=on, 0=off, ch defaults to 1
dev.sendBri(1-254, ch?)         # brightness
dev.sendColor("#rrggbb", ch?)   # or "r,g,b"
dev.sendColorTemp(mireds, ch?)  # color temperature
dev.sendCmd(ep, cluster, cmd, payload?)  # raw ZCL command
dev.readAttr(ep, cluster, attr, ...) → int  # request attribute read, returns ZCL txn (since v3.0.6)
dev.getVal(ep, cluster, attr) → value|nil  # last reported value
dev.getName() → str             # user-set name
dev.getModel() → str            # device model
dev.getManuf() → str            # manufacturer
dev.getNwk() → int              # network address
dev.getLqi() → int               # link quality
dev.getBattery() → int           # battery %
dev.getLastSeen() → int          # last packet timestamp
dev.matcher(manuf, model) → bool # match device type (case sensitive)
dev.bindToHub(ep, cl) → bool               # (since v3.0.6)
dev.bindToDevice(ep, cl, ieee, dstEp) → bool  # (since v3.0.6)
dev.bindToGroup(ep, cl, groupAddr) → bool     # (since v3.0.6)
# Event:
ZHB.on_action(def(action, dev) end)  # button/encoder actions
# action strings: "single","double","long","btn_single_1","rotate_right_1" etc.
```
Details: [docs/modules/zhb.md](docs/modules/zhb.md) | Button guide: [docs/guides/zigbee-button-actions.md](docs/guides/zigbee-button-actions.md)

## HTTP — HTTP Client (v2.9.8) `import HTTP`
```
HTTP.open(url, "get"|"post", bufferSize) → bool  # HTTPS supported (no cert verify). buffer 0 = stream mode
HTTP.perform() → int              # execute, returns status code
HTTP.getResponse() → str          # response text (max buffer size)
HTTP.setPostData(str) → bool      # set POST body
HTTP.setHeader(name, value) → bool
HTTP.setUrl(url) → bool           # reuse: change URL
HTTP.setMethod(method) → bool     # reuse: change method
HTTP.isOpened() → bool
HTTP.close()                      # always close when done!
# Stream mode (buffer=0, since v3.1.6.dev3):
HTTP.streamReadBytes(count, bytesBuffer) → int
HTTP.streamReadString(count) → str
HTTP.streamFlush(count)
HTTP.streamGetLen() → int
```
Details: [docs/modules/http.md](docs/modules/http.md)

## WEBSERVER — Webhooks (v2.8.2.dev0) `import WEBSERVER`
```
# Webhook URL: http://<device-ip>/script/webhook
WEBSERVER.getArg(index|name) → str   # get param value, "" if missing
WEBSERVER.hasArg(name) → bool
WEBSERVER.send(code, contentType, body)  # use only inside on_webhook!
WEBSERVER.on_webhook(def(argCount) end)  # event: request received
```
Details: [docs/modules/webserver.md](docs/modules/webserver.md)

## TIME — Clock/NTP (v3.0.6) `import TIME`
```
TIME.waitSync(timeout) → bool    # wait for NTP, 255=forever
TIME.getAll() → map|nil          # {year, month, day, hour, min, sec, weekday} weekday: 0=Sun
TIME.getTime() → map             # {hour, min, sec}
```
Details: [docs/modules/time.md](docs/modules/time.md)

## FS — File System (v3.0.6) `import FS`
```
FS.exists(path) → bool
FS.open(path, mode) → File       # see Berry docs for File class
FS.deleteFile(path) → bool       # files only, not folders
FS.deleteDir(path)               # non-recursive, no subfolders
```
Details: [docs/modules/fs.md](docs/modules/fs.md)

## GPIO — Pin Control (v3.1.6.dev3) `import GPIO`
```
GPIO.MOD_OUTPUT, GPIO.MOD_INPUT  # constants
GPIO.pinMode(pin, mode)          # must call before using pin!
GPIO.digitalRead(pin) → bool
GPIO.digitalWrite(pin, state)
GPIO.analogRead(pin) → int       # 0-4096 (0-3.3V)
GPIO.analogWrite(pin, dutycycle)  # PWM
GPIO.tone(pin, freq)             # frequency generator
GPIO.noTone(pin)                 # stop frequency
```
Details: [docs/modules/gpio.md](docs/modules/gpio.md)

## MQTT — Messaging (v3.2.4) `import MQTT`
```
# Requires MQTT enabled in device web UI
MQTT.waitConnect(timeout) → bool         # 255=forever
MQTT.isConnected() → bool
MQTT.subscribe(topic) → bool             # → <base_topic>/topic
MQTT.subscribeCustom(topic) → bool       # exact topic
MQTT.publish(topic, payload) → bool      # → <base_topic>/topic
MQTT.publishCustom(topic, payload) → bool  # exact topic
MQTT.on_message(def(topic, data) end)    # event: message received
```
Details: [docs/modules/mqtt.md](docs/modules/mqtt.md)

## BUZZER — Melodies (v3.2.5.dev1, Ultima3 only) `import BUZZER`
```
BUZZER.play(rtttlString)   # e.g. "Name:d=4,o=5,b=140:8g6,16p,2a#6"
```
Details: [docs/modules/buzzer.md](docs/modules/buzzer.md)

## BUTTON — Physical Button (v3.2.5.dev1) `import BUTTON`
```
BUTTON.on_press(0, def(type) end)  # type: 0=short, 1=long. Disables default button actions!
```
Details: [docs/modules/button.md](docs/modules/button.md)

## AMBILIGHT — LED Strip (v3.2.5.dev1, Ultima only) `import AMBILIGHT`
```
AMBILIGHT.setEffect(effect)      AMBILIGHT.getEffect() → int
AMBILIGHT.setBrightness(1-254)   AMBILIGHT.getBrightness() → int
AMBILIGHT.setSpeed(speed)        AMBILIGHT.getSpeed() → int
AMBILIGHT.setColor(0xRRGGBB)     AMBILIGHT.getColor() → int
AMBILIGHT.setColor2(0xRRGGBB)    AMBILIGHT.getColor2() → int    # gradient only
AMBILIGHT.setDirection(0|1)      AMBILIGHT.getDirection() → int  # 0=fwd, 1=rev
# Effect constants:
# SOLID=0 OFF=1 BLUR=2 RAINBOW=3 BREATHING=4 COLOR_WIPE=5 COMET=6
# FIRE=7 TWINKLE=8 POLICE=9 CHASE=10 COLOR_CYCLE=11 GRADIENT=12
# STROBE=13 SYS_WARNING=14 SYS_ERROR=15 SYS_OK=16 SYS_INFO=17
# SYS_* effects blink 3x then revert. All set* save to config immediately.
```
Details: [docs/modules/ambilight.md](docs/modules/ambilight.md)

## IR Transmitter (v3.2.5.dev1, Ultima only) `import IR`
```
IR.send(protocol, address, command)  # send by protocol
IR.sendRaw(hexString) → bool        # raw 38kHz timing, each byte=50us tick
# Protocols: APPLE=3 DENON=4 JVC=5 LG=6 NEC=8 NEC2=9 ONKYO=10
# PANASONIC=11 RC5=17 RC6=18 SAMSUNG=20 SHARP=23 SONY=24
```
Details: [docs/modules/ir_transmitter.md](docs/modules/ir_transmitter.md)

## IR Receiver (v3.2.5.dev1, Ultima only) `import IR`
```
IR.on_receive(def(protocol, address, command) end)  # event: IR received
IR.getProtocol() → int    # 0=UNKNOWN
IR.getAddress() → int
IR.getCommand() → int
IR.getRaw() → str          # raw timing hex, use with IR.sendRaw() to replay
```
Details: [docs/modules/ir_receiver.md](docs/modules/ir_receiver.md)
