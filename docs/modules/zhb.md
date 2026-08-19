# ZHB — Zigbee Hub (Device Control)

> Available since: v2.9.6. Individual additions noted below.

Access and control your Zigbee devices — relays, lamps, sensors, buttons — directly from Berry scripts.

## Quick Example

```berry
import ZHB

ZHB.waitForStart(0xff)

var relay = ZHB.getDevice("Kitchen Relay")
relay.sendOnOff(1)  # turn on
```

## API Reference

### Module Functions

| Function | Description | Returns |
|----------|-------------|---------|
| `ZHB.getDevice(identifier:string\|int)` | Get device by name (`string`), network address (`int`), or IEEE address (`string`, format `"0x0000000000000000"`). | `ZigbeeDevice` (or error if not found) |
| `ZHB.waitForStart(timeout:int)` | Block until Zigbee Hub is fully started. Max 254 seconds. Use `255` to wait forever. | — |
| `ZHB.permitJoin(time:int, addr:int?)` | Open network for new devices. `time`: 1–254 sec, `0` = close, `255` = permanent. `addr` (optional): specific device address. *(since v3.0.6)* | — |
| `ZHB.mqttAction(topic:string, payload:string)` | Run a Zigbee Hub MQTT command locally (same handlers as a real MQTT message on `{base}/cmd/...` or `{base}/write/...`, incl. ZCN converters). *(since v3.3.8: returns a request id for `ZHB.await()`)* | request id (`int`) for cmd/write topics, `nil` otherwise |
| `ZHB.await(seq:int, timeoutMs:int?)` | Block until the device answers the request `seq`. See *Waiting for a Response* below. *(since v3.3.8)* | `bool` |
| `ZHB.on_response(seq:int, callback:function, timeoutMs:int?)` | Non-blocking variant: `callback(ok, status)`. *(since v3.3.8)* | `bool` |
| `ZHB.lastStatus()` | Raw ZCL status of the last `ZHB.await()`. *(since v3.3.8)* | `int` / `nil` |

### ZigbeeDevice Class

#### Device Information

| Function | Description | Returns |
|----------|-------------|---------|
| `getName()` | User-set device name | `string` |
| `getModel()` | Device model | `string` |
| `getManuf()` | Device manufacturer | `string` |
| `getNwk()` | Network address | `int` |
| `getPS()` | Power source | `int` |
| `getBattery()` | Battery percentage | `int` |
| `getIAS()` | IAS type | `int` |
| `getLastSeen()` | Timestamp of last received packet | `int` |
| `getLqi()` | Link quality indicator | `int` |
| `matcher(manufacturer:string, model:string)` | Check if device matches manufacturer and model. **Case sensitive.** | `bool` |

#### Control Commands

| Function | Description |
|----------|-------------|
| `sendOnOff(state:int, channel:int?)` | Turn on (`1`), off (`0`), or toggle (`2`). `channel` optional, defaults to 1. |
| `sendBri(brightness:int, channel:int?)` | Set brightness (1–254). `channel` optional. |
| `sendColor(color:string, channel:int?)` | Set color. Format: `"#rrggbb"` or `"r,g,b"`. `channel` optional. |
| `sendColorTemp(mireds:int, channel:int?)` | Set color temperature in [mireds](https://en.wikipedia.org/wiki/Mired). `channel` optional. |
| `sendCmd(endpoint:int, cluster:int, command:int, payload:bytes?)` | Send any ZCL command. `payload` (`bytes`) optional. Returns ZCL transaction number (`int`). |
| `readAttr(endpoint:int, cluster:int, attr:int, ...)` | Request attribute read. Does **not** wait for response. Supports multiple attributes. Returns ZCL transaction number (`int`). *(since v3.0.6)* |

```berry
dev.sendOnOff(1)         # turn on relay
dev.sendOnOff(0)         # turn off relay
dev.sendOnOff(2)         # toggle relay (on→off or off→on)
dev.sendOnOff(1, 2)      # turn on relay channel 2
dev.sendColor("#0062ff") # send hex color
dev.sendColor("0,0,255") # send RGB color
dev.sendColorTemp(180)   # daylight color temperature
dev.sendCmd(1, 6, 1)     # turn on via raw ZCL command

# readAttr examples:
dev.readAttr(1, 0x0b04, 0x0505)                # request AC voltage (Electrical Measurement cluster)
dev.readAttr(1, 0x0b04, 0x0505, 0x0508, 0x050b) # request voltage, current, and power at once
```

#### Reading Values

| Function | Description | Returns |
|----------|-------------|---------|
| `getVal(endpoint:int, cluster:int, attribute:int)` | Last saved value from the device. Returns `nil` if not yet reported. | `bool` / `float` / `int` / `string` / `bytes` |

```berry
# Read temperature from a sensor (cluster 0x0402, attribute 0)
var temp = sensor.getVal(1, 0x0402, 0)

# Read on/off state of a relay (cluster 6, attribute 0)
var state = relay.getVal(1, 6, 0)
```

#### Waiting for a Response *(since v3.3.8)*

Every send function (`sendOnOff`, `sendBri`, `sendColor`, `sendColorTemp`, `sendCmd`,
`sendTuyaData`, `readAttr`, `writeAttr`, `confReporting`) returns a ZCL transaction
number (`seq`). The `ZHB` module offers two ways to get the device's answer for it
(the target device is resolved from `seq` automatically):

| Function | Description | Returns |
|----------|-------------|---------|
| `ZHB.await(seq:int, timeoutMs:int?)` | **Blocking.** Waits until the response for `seq` arrives. Default timeout 3000 ms, max 30000. | `true` only when the device answered with ZCL **SUCCESS**; `false` on any error status, timeout or failed send |
| `ZHB.lastStatus()` | Raw ZCL status of the last `ZHB.await()` in this script (for diagnostics after a `false`). | `int` (`0` = success) or `nil` on timeout / failed send |
| `ZHB.on_response(seq:int, callback:function, timeoutMs:int?)` | **Non-blocking.** `callback(ok, status)` is called when the response (or timeout) arrives: `ok` — `bool` like `await()`, `status` — raw ZCL status or `nil` on timeout. | `bool` — `false` if `seq` is unknown or too many pending waits |

`ZHB.mqttAction()` is awaitable too: for `cmd`/`write` topics it returns a request id and the
wait resolves on the **next** response from the target endpoint/cluster (the MQTT/ZCN handlers
behind it may send several packets, so there is no single transaction number to match).

Which response counts:

- commands (`sendOnOff`, `sendCmd`, ...) — the ZCL *Default Response*;
- `mqttAction("<base>/cmd/...")` / `mqttAction("<base>/write/...")` — the first response from
  that endpoint/cluster after the call;
- `readAttr` — the *Read Attributes Response*; by the time `await()` returns / the callback
  runs, the values are already stored, read them with `getVal()`;
- `writeAttr` — *Write Attributes Response*; `confReporting` — *Configure Reporting Response*.

```berry
import ZHB
var relay = ZHB.getDevice("0xa4c1389ffb198304")

# synchronous style - plain sequential code
if ZHB.await(relay.sendOnOff(1))
  SLZB.log("relay is on")
else
  SLZB.log("relay failed, ZCL status: " .. str(ZHB.lastStatus()))  # nil = no answer
end

if ZHB.await(sensor.readAttr(1, 0x0402, 0), 2000)
  SLZB.log("temperature: " .. sensor.getVal(1, 0x0402, 0))
end

# MQTT-style action (goes through ZCN converters like a real MQTT message)
if ZHB.await(ZHB.mqttAction("zhub/cmd/a4c1389ffb198304/1/0006/01", ""))
  SLZB.log("relay confirmed the ON command")
end

# asynchronous style - the script continues, the callback fires later
ZHB.on_response(relay.sendOnOff(2), def (ok, status)
  if ok
    SLZB.log("toggled " .. relay.getName())
  elif status == nil
    SLZB.log("toggle timed out")
  else
    SLZB.log("toggle refused, ZCL status " .. status)
  end
end)
```

Rules:

- `ZHB.await()` **cannot** be called inside ZCN converter callbacks or `ZHB.on_message`
  handlers — those run on the Zigbee Hub task that delivers responses, so blocking there
  would deadlock. It raises an error instead; use `ZHB.on_response()` in that context.
- While a script is blocked in `ZHB.await()` its other callbacks (TIMER, ZCN, on_message,
  on_response) **keep running** as usual — the wait only pauses the code that called `await()`.
- Commands sent with the "disable default response" flag never get a Default Response:
  `await()` returns `false` (`lastStatus()` is `nil`) / the callback receives `status = nil`.
- Call `await()`/`on_response()` right after the send: `seq` is an 8-bit rolling counter and
  only the last 16 requests are remembered.
- Up to 16 pending waits at a time across all scripts.

#### Binding *(since v3.0.6)*

| Function | Description | Returns |
|----------|-------------|---------|
| `bindToHub(srcEp:int, srcCl:int)` | Bind endpoint/cluster to the hub. | `bool` |
| `bindToDevice(srcEp:int, srcCl:int, dstIeee:string, dstEp:int)` | Bind to another device. `dstIeee` in hex string format. | `bool` |
| `bindToGroup(srcEp:int, srcCl:int, dstGroupAddr:int)` | Bind to a group address. | `bool` |

### Identifying Devices in Callbacks

ZigbeeDevice has **no `getIeee()` method**. To identify which device triggered an `on_action` callback, look up the device by IEEE once at startup, then compare by network address (`getNwk()`) inside the callback:

```berry
# Look up once at startup
var btn = ZHB.getDevice("0xe456acfffe603d1e")

def on_action(action, dev)
  # Compare by network address — works even if device has no name
  if dev.getNwk() == btn.getNwk() && action == "single"
    SLZB.log("Button pressed!")
  end
end
ZHB.on_action(on_action)
```

If the device has a **custom name** set, you can also match by name:

```berry
var btn = ZHB.getDevice("My Button")
var btnName = btn.getName()

def on_action(action, dev)
  if dev.getName() == btnName && action == "single"
    SLZB.log("Button pressed!")
  end
end
ZHB.on_action(on_action)
```

> **Important:** Many devices have **no custom name** — `getName()` returns `""`. In that case, always use the IEEE/NWK matching pattern above.

### Events

#### ZHB.on_action(callback:function) *(since v3.2.6.dev1)*

Called when a Zigbee device sends an action — button click, double click, long press, rotary encoder rotation, etc.

Callback receives two arguments:
- `action` (`string`) — e.g. `"single"`, `"btn_double_1"`, `"rotate_right_1"`
- `dev` (`ZigbeeDevice`) — the device that triggered the action

```berry
var btn = ZHB.getDevice("0xe456acfffe603d1e")

def on_action(action, dev)
  if dev.getNwk() == btn.getNwk()
    SLZB.log("[" .. action .. "] from button")
  end
end

ZHB.on_action(on_action)
```

For the full guide with action string tables and advanced examples, see the [Zigbee Button & Action Events guide](../guides/zigbee-button-actions.md).

## See Also

- [Full Guide: Zigbee Button & Action Events](../guides/zigbee-button-actions.md)
- [ZB — Low-level Zigbee Access](zb.md)
- [MQTT — Publish device state](mqtt.md) — Combine ZHB + MQTT for notifications
- [HTTP — Send alerts](http.md) — Combine ZHB + HTTP for webhook notifications
- [Example: Simple Thermostat](../../examples/zigbee_hub/simple_thermostat.be)
