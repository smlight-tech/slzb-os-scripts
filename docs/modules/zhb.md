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
| `ZHB.getDevice(identifier)` | Get device by name (`string`), network address (`int`), or IEEE address (`string`, format `"0x0000000000000000"`). | `ZigbeeDevice` (or error if not found) |
| `ZHB.waitForStart(timeout)` | Block until Zigbee Hub is fully started. Max 254 seconds. Use `255` to wait forever. | — |
| `ZHB.permitJoin(time, addr)` | Open network for new devices. `time`: 1–254 sec, `0` = close, `255` = permanent. `addr` (optional): specific device address. *(since v3.0.6)* | — |

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
| `matcher(manufacturer, model)` | Check if device matches manufacturer and model. **Case sensitive.** | `bool` |

#### Control Commands

| Function | Description |
|----------|-------------|
| `sendOnOff(state, channel?)` | Turn on (`1`) or off (`0`). `channel` optional, defaults to 1. |
| `sendBri(brightness, channel?)` | Set brightness (1–254). `channel` optional. |
| `sendColor(color, channel?)` | Set color. Format: `"#rrggbb"` or `"r,g,b"`. `channel` optional. |
| `sendColorTemp(mireds, channel?)` | Set color temperature in [mireds](https://en.wikipedia.org/wiki/Mired). `channel` optional. |
| `sendCmd(endpoint, cluster, command, payload?)` | Send any ZCL command. `payload` (`bytes`) optional. Returns ZCL transaction number (`int`). |
| `readAttr(endpoint, cluster, attr, ...)` | Request attribute read. Does **not** wait for response. Supports multiple attributes. *(since v3.0.6)* |

```berry
dev.sendOnOff(1)         # turn on relay
dev.sendOnOff(0)         # turn off relay
dev.sendOnOff(1, 2)      # turn on relay channel 2
dev.sendColor("#0062ff") # send hex color
dev.sendColor("0,0,255") # send RGB color
dev.sendColorTemp(180)   # daylight color temperature
dev.sendCmd(1, 6, 1)     # turn on via raw ZCL command
```

#### Reading Values

| Function | Description | Returns |
|----------|-------------|---------|
| `getVal(endpoint, cluster, attribute)` | Last saved value from the device. Returns `nil` if not yet reported. | `bool` / `float` / `int` / `string` / `bytes` |

```berry
# Read temperature from a sensor (cluster 0x0402, attribute 0)
var temp = sensor.getVal(1, 0x0402, 0)

# Read on/off state of a relay (cluster 6, attribute 0)
var state = relay.getVal(1, 6, 0)
```

#### Binding *(since v3.0.6)*

| Function | Description | Returns |
|----------|-------------|---------|
| `bindToHub(srcEp, srcCl)` | Bind endpoint/cluster to the hub. | `bool` |
| `bindToDevice(srcEp, srcCl, dstIeee, dstEp)` | Bind to another device. `dstIeee` in hex string format. | `bool` |
| `bindToGroup(srcEp, srcCl, dstGroupAddr)` | Bind to a group address. | `bool` |

### Events

#### ZHB.on_action(callback)

Called when a Zigbee device sends an action — button click, double click, long press, rotary encoder rotation, etc.

Callback receives two arguments:
- `action` (`string`) — e.g. `"single"`, `"btn_double_1"`, `"rotate_right_1"`
- `dev` (`ZigbeeDevice`) — the device that triggered the action

```berry
def on_action(action, dev)
  SLZB.log("[" .. dev.getName() .. "] " .. action)
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
