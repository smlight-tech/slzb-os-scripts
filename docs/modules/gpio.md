# GPIO — Direct GPIO Control

> Available since: v3.1.6.dev3

Read and write digital/analog GPIO pins, generate PWM and frequency signals.

**Use with EXTREME caution** — incorrect pin usage can damage your device.

## Quick Example

```berry
import GPIO

var led_pin = 46  # blue LED on SLZB-06p7u
GPIO.pinMode(led_pin, GPIO.MOD_OUTPUT)
GPIO.digitalWrite(led_pin, 1)  # turn on
```

## Constants

| Constant | Description |
|----------|-------------|
| `GPIO.MOD_OUTPUT` | Output mode |
| `GPIO.MOD_INPUT` | Input mode |

## API Reference

| Function | Description | Returns |
|----------|-------------|---------|
| `GPIO.pinMode(pin, mode)` | Set pin mode. **Must be called before using the pin.** | — |
| `GPIO.digitalRead(pin)` | Read digital state (HIGH/LOW). | `bool` |
| `GPIO.digitalWrite(pin, state)` | Set digital output state. | — |
| `GPIO.analogRead(pin)` | Read voltage on the pin. Range: 0–4096 (maps to 0–3.3V). | `int` |
| `GPIO.analogWrite(pin, dutycycle)` | Generate PWM with the given duty cycle (0–100%). | — |
| `GPIO.tone(pin, freq)` | Generate a frequency signal on the pin. | — |
| `GPIO.noTone(pin)` | Stop frequency generation on the pin. | — |

## See Also

- [BUZZER — Play melodies](buzzer.md) — Higher-level audio output (Ultima3)
- [BUTTON — Physical button override](button.md) — Intercept hardware button presses
