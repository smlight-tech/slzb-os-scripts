# IR — Infrared Control

> Available since: v3.2.5.dev1 | **Ultima devices only**

Send and receive infrared commands using known protocols or raw timing data.

## Quick Example

```berry
# Send an NEC power command
IR.send(IR.NEC, 0x04, 0x08)
```

## API Reference

### Sending

| Function | Description | Returns |
|----------|-------------|---------|
| `IR.send(protocol, address, command)` | Send an IR code using a known protocol. | — |
| `IR.sendRaw(hexString)` | Send raw IR timing data at 38 kHz. Each byte = 50us tick, alternating mark/space. | `bool` |

### Receiving

| Function | Description | Returns |
|----------|-------------|---------|
| `IR.getProtocol()` | Last received protocol number (`0` = UNKNOWN). | `int` |
| `IR.getAddress()` | Last received device address. | `int` |
| `IR.getCommand()` | Last received command code. | `int` |
| `IR.getRaw()` | Last received raw timing data as hex string. | `string` |

### Events

| Function | Description |
|----------|-------------|
| `IR.on_receive(callback)` | Register a callback for IR reception. Callback: `def (protocol, address, command)`. |

## Protocol Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `IR.UNKNOWN` | 0 | Unknown protocol |
| `IR.APPLE` | 3 | Apple remote |
| `IR.DENON` | 4 | Denon (includes Sharp) |
| `IR.JVC` | 5 | JVC |
| `IR.LG` | 6 | LG |
| `IR.NEC` | 8 | NEC (most common, includes Apple and Onkyo) |
| `IR.NEC2` | 9 | NEC with full frame repeat |
| `IR.ONKYO` | 10 | Onkyo |
| `IR.PANASONIC` | 11 | Panasonic (Kaseikyo) |
| `IR.RC5` | 17 | RC5 |
| `IR.RC6` | 18 | RC6 |
| `IR.SAMSUNG` | 20 | Samsung |
| `IR.SHARP` | 23 | Sharp |
| `IR.SONY` | 24 | Sony |

## Examples

### Learn and replay an IR code

```berry
var lastRaw = ""

IR.on_receive(def (proto, addr, cmd)
  lastRaw = IR.getRaw()
  SLZB.log("Learned! Protocol: " .. proto)
end)

# later, replay:
if lastRaw != ""
  IR.sendRaw(lastRaw)
end
```

### React to a specific remote button

```berry
IR.on_receive(def (proto, addr, cmd)
  if proto == IR.NEC && addr == 0x04 && cmd == 0x08
    SLZB.log("Power button pressed!")
    AMBILIGHT.setEffect(AMBILIGHT.SYS_OK)
  end
end)
```

## See Also

- [AMBILIGHT — LED control](ambilight.md) — Combine: trigger LED effects from IR remote
- [ZHB — Zigbee Hub](zhb.md) — Combine: control Zigbee devices from IR remote
- [BUTTON — Physical button](button.md)
