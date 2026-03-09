# AMBILIGHT — LED Strip Control

> Available since: v3.2.5.dev1 | **Ultima devices only**

Control the WS2812B LED ambilight — set effects, colors, brightness, and speed.

## Quick Example

```berry
AMBILIGHT.setColor(0xFF0000)          # red
AMBILIGHT.setBrightness(254)          # full brightness
AMBILIGHT.setEffect(AMBILIGHT.Eff_Solid)  # static color
```

## API Reference

### Effect Control

| Function | Description | Returns |
|----------|-------------|---------|
| `AMBILIGHT.setEffect(effect:int)` | Set LED effect (use effect constants below). | — |
| `AMBILIGHT.getEffect()` | Get current effect. | `int` |

### Brightness

| Function | Description | Returns |
|----------|-------------|---------|
| `AMBILIGHT.setBrightness(bri:int)` | Set brightness, 1–254. | — |
| `AMBILIGHT.getBrightness()` | Get current brightness. | `int` |

### Speed

| Function | Description | Returns |
|----------|-------------|---------|
| `AMBILIGHT.setSpeed(speed:int)` | Set effect animation speed. | — |
| `AMBILIGHT.getSpeed()` | Get current speed. | `int` |

### Colors

| Function | Description | Returns |
|----------|-------------|---------|
| `AMBILIGHT.setColor(color:int)` | Set primary color as `0xRRGGBB`. | — |
| `AMBILIGHT.getColor()` | Get current primary color. | `int` |
| `AMBILIGHT.setColor2(color:int)` | Set secondary color (used by Gradient effect). | — |
| `AMBILIGHT.getColor2()` | Get current secondary color. | `int` |

### Direction

| Function | Description | Returns |
|----------|-------------|---------|
| `AMBILIGHT.setDirection(dir:int)` | `0` = Forward, `1` = Reverse. | — |
| `AMBILIGHT.getDirection()` | Get current direction. | `int` |

## Effect Constants

Type `AMBILIGHT.Eff` in the script editor to autocomplete all visual effects, or `AMBILIGHT.Sys` for system notifications.

| Constant | Value | Description |
|----------|-------|-------------|
| `AMBILIGHT.Eff_Solid` | 0 | Static solid color |
| `AMBILIGHT.Eff_Off` | 1 | LEDs off |
| `AMBILIGHT.Eff_Blur` | 2 | Moving dot with blur trail |
| `AMBILIGHT.Eff_Rainbow` | 3 | Rotating rainbow |
| `AMBILIGHT.Eff_Breathing` | 4 | Pulsing brightness |
| `AMBILIGHT.Eff_ColorWipe` | 5 | Fill LEDs one-by-one, then clear |
| `AMBILIGHT.Eff_Comet` | 6 | Moving dot with fading tail |
| `AMBILIGHT.Eff_Fire` | 7 | Fire simulation |
| `AMBILIGHT.Eff_Twinkle` | 8 | Random sparkles |
| `AMBILIGHT.Eff_Police` | 9 | Alternating red/blue halves |
| `AMBILIGHT.Eff_Chase` | 10 | Group of LEDs chasing |
| `AMBILIGHT.Eff_ColorCycle` | 11 | All LEDs shift through hues |
| `AMBILIGHT.Eff_Gradient` | 12 | Scrolling blend between color and color2 |
| `AMBILIGHT.Eff_Strobe` | 13 | Fast on/off flash |
| `AMBILIGHT.Sys_Warning` | 14 | 3 yellow blinks, then reverts |
| `AMBILIGHT.Sys_Error` | 15 | 3 red blinks, then reverts |
| `AMBILIGHT.Sys_Ok` | 16 | 3 green blinks, then reverts |
| `AMBILIGHT.Sys_Info` | 17 | 3 blue blinks, then reverts |

## Notes

- All `set*` functions apply immediately and save to config.
- System effects (`Sys_*`) are one-shot: they blink 3 times and automatically revert to the previous effect.
- Color values are 24-bit RGB packed as uint32: `0xRRGGBB`.
- The `color2` field is only used by the Gradient effect.
- Direction applies to: Blur, Rainbow, Color Wipe, Comet, Chase, Gradient.

## Examples

### Gradient between two colors

```berry
AMBILIGHT.setColor(0xFF0000)    # red
AMBILIGHT.setColor2(0x0000FF)   # blue
AMBILIGHT.setSpeed(30)
AMBILIGHT.setEffect(AMBILIGHT.Eff_Gradient)
```

### Flash a success notification

```berry
AMBILIGHT.setEffect(AMBILIGHT.Sys_Ok)
# LEDs blink green 3 times, then return to previous effect
```

### Read current state

```berry
var effect = AMBILIGHT.getEffect()
var bri = AMBILIGHT.getBrightness()
var color = AMBILIGHT.getColor()
SLZB.log("Effect: " .. effect .. " Brightness: " .. bri)
```

## See Also

- [IR Receiver](ir_receiver.md) — Combine: trigger LED effects from IR remote
- [IR Transmitter](ir_transmitter.md) — Another Ultima-only module
- [BUTTON — Physical button](button.md) — Combine: change LED effect on button press
- [ZHB — Zigbee Hub](zhb.md) — Combine: change LED color based on Zigbee sensor data
- [Example: Effects demo](../../examples/ambilight/effects_demo.be)
- [Example: Cycle colors with Zigbee button](../../examples/ambilight/color_cycle_on_button.be)
