# IR Transmitter — Sending Infrared Commands

> Available since: v3.2.5.dev1 | **Ultima devices with IR LED only**

Send infrared commands to TVs, air conditioners, media players, and other IR-controlled devices.

## Quick Example

```berry
IR.send(IR.NEC, 0x04, 0x08)  # send NEC power command
```

## API Reference

| Function | Description | Returns |
|----------|-------------|---------|
| `IR.send(protocol:int, address:int, command:int)` | Send an IR code using a known protocol (see [Protocol Constants](#protocol-constants)). | — |
| `IR.sendRaw(hexString:string)` | Send raw IR timing data at 38 kHz. Each byte = 50us tick, alternating mark/space. Use for unsupported protocols or replaying captured codes. | `bool` |

## Protocol Constants

| Constant | Value | Description |
|----------|-------|-------------|
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

### Send a Samsung TV command

```berry
IR.send(IR.SAMSUNG, 0x0707, 0x02)
```

### Replay a previously captured raw code

```berry
var raw = "a1b2c3d4e5f6..."  # captured via IR Receiver
IR.sendRaw(raw)
```

## See Also

- [IR Receiver — Receiving](ir_receiver.md) — Capture IR codes to learn and replay
- [AMBILIGHT — LED control](ambilight.md) — Combine: flash LEDs when sending IR
- [ZHB — Zigbee Hub](zhb.md) — Combine: bridge Zigbee buttons to IR commands
- [Example: Send NEC command](../../examples/ir_transmitter/send_nec_command.be)
- [Example: Zigbee button sends IR](../../examples/ir_transmitter/zigbee_button_sends_ir.be)
