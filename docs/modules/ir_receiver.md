# IR Receiver — Receiving Infrared Commands

> Available since: v3.2.5.dev1 | **Ultima devices with IR sensor only**

Listen for incoming infrared signals from remote controls and other IR devices. Use for automation triggers, learning/replaying codes, or bridging IR remotes to Zigbee.

## Quick Example

```berry
IR.on_receive(def (proto, addr, cmd)
  SLZB.log("IR: protocol=" .. proto .. " addr=" .. addr .. " cmd=" .. cmd)
end)
```

## API Reference

### Events

| Function | Description |
|----------|-------------|
| `IR.on_receive(callback:function)` | Register a callback that fires on every received IR code. Callback: `def (protocol:int, address:int, command:int)`. |

### Reading Last Received Code

| Function | Description | Returns |
|----------|-------------|---------|
| `IR.getProtocol()` | Protocol number of the last received code (`0` = UNKNOWN). | `int` |
| `IR.getAddress()` | Device address of the last received code. | `int` |
| `IR.getCommand()` | Command code of the last received code. | `int` |
| `IR.getRaw()` | Raw timing data as hex string. Use with `IR.sendRaw()` to replay unknown protocols. | `string` |

## Protocol Constants

The `protocol` argument in `on_receive` and the return of `IR.getProtocol()` use these values. Type `IR.Proto` in the script editor to autocomplete all protocols.

| Constant | Value | Description |
|----------|-------|-------------|
| `IR.Proto_Unknown` | 0 | Unknown protocol — use `IR.getRaw()` to capture raw data |
| `IR.Proto_Apple` | 3 | Apple remote |
| `IR.Proto_Denon` | 4 | Denon (includes Sharp) |
| `IR.Proto_Jvc` | 5 | JVC |
| `IR.Proto_Lg` | 6 | LG |
| `IR.Proto_Nec` | 8 | NEC (most common) |
| `IR.Proto_Nec2` | 9 | NEC with full frame repeat |
| `IR.Proto_Onkyo` | 10 | Onkyo |
| `IR.Proto_Panasonic` | 11 | Panasonic (Kaseikyo) |
| `IR.Proto_Rc5` | 17 | RC5 |
| `IR.Proto_Rc6` | 18 | RC6 |
| `IR.Proto_Samsung` | 20 | Samsung |
| `IR.Proto_Sharp` | 23 | Sharp |
| `IR.Proto_Sony` | 24 | Sony |

## Examples

### React to a specific remote button

```berry
IR.on_receive(def (proto, addr, cmd)
  if proto == IR.Proto_Nec && addr == 0x04 && cmd == 0x08
    SLZB.log("Power button pressed!")
    AMBILIGHT.setEffect(AMBILIGHT.Sys_Ok)
  end
end)
```

### Learn and replay a code

Capture with the receiver, replay with the [transmitter](ir_transmitter.md):

```berry
var lastRaw = ""

# Capture
IR.on_receive(def (proto, addr, cmd)
  lastRaw = IR.getRaw()
  SLZB.log("Learned! Protocol: " .. proto)
end)

# Replay later
if lastRaw != ""
  IR.sendRaw(lastRaw)
end
```

### Bridge an IR remote to Zigbee

```berry
import ZHB
ZHB.waitForStart(0xff)

var lamp = ZHB.getDevice("Living Room Lamp")

IR.on_receive(def (proto, addr, cmd)
  if proto == IR.Proto_Nec && addr == 0x04
    if cmd == 0x08
      lamp.sendOnOff(1)   # power button → lamp on
    elif cmd == 0x0A
      lamp.sendOnOff(0)   # mute button → lamp off
    end
  end
end)
```

## See Also

- [IR Transmitter — Sending](ir_transmitter.md) — Send IR commands and replay captured codes
- [AMBILIGHT — LED control](ambilight.md) — Combine: trigger LED effects from IR remote
- [ZHB — Zigbee Hub](zhb.md) — Combine: control Zigbee devices from IR remote
- [BUTTON — Physical button](button.md)
- [Example: Log IR codes (discovery)](../../examples/ir_receiver/log_ir_codes.be)
- [Example: IR-to-Zigbee bridge](../../examples/ir_receiver/ir_to_zigbee_bridge.be)
