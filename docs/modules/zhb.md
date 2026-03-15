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
