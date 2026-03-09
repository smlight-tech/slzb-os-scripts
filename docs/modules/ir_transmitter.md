# IR Transmitter — Sending Infrared Commands

> Available since: v3.2.5.dev1 | **Ultima devices with IR LED only**

Send infrared commands to TVs, air conditioners, media players, and other IR-controlled devices.

## Quick Example

```berry
IR.send(IR.Proto_Nec, 0x04, 0x08)  # send NEC power command
```

## API Reference

| Function | Description | Returns |
|----------|-------------|---------|
| `IR.send(protocol:int, address:int, command:int)` | Send an IR code using a known protocol (see [Protocol Constants](#protocol-constants)). | — |
| `IR.sendRaw(hexString:string)` | Send raw IR timing data at 38 kHz. Each byte = 50us tick, alternating mark/space. Use for unsupported protocols or replaying captured codes. | `bool` |

## Protocol Constants

Type `IR.Proto` in the script editor to autocomplete all protocols.

| Constant | Value | Description |
|----------|-------|-------------|
| `IR.Proto_Apple` | 3 | Apple remote |
| `IR.Proto_Denon` | 4 | Denon (includes Sharp) |
| `IR.Proto_Jvc` | 5 | JVC |
| `IR.Proto_Lg` | 6 | LG |
| `IR.Proto_Nec` | 8 | NEC (most common, includes Apple and Onkyo) |
| `IR.Proto_Nec2` | 9 | NEC with full frame repeat |
| `IR.Proto_Onkyo` | 10 | Onkyo |
| `IR.Proto_Panasonic` | 11 | Panasonic (Kaseikyo) |
| `IR.Proto_Rc5` | 17 | RC5 |
| `IR.Proto_Rc6` | 18 | RC6 |
| `IR.Proto_Samsung` | 20 | Samsung |
| `IR.Proto_Sharp` | 23 | Sharp |
| `IR.Proto_Sony` | 24 | Sony |

## Examples

### Send a Samsung TV command

```berry
IR.send(IR.Proto_Samsung, 0x0707, 0x02)
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
