# BUZZER — Melody Player

> Available since: v3.2.5.dev1 | **Ultima3 only**

Play melodies on the built-in buzzer using RTTTL format strings.

## Quick Example

```berry
import BUZZER
BUZZER.play("Arkanoid:d=4,o=5,b=140:8g6,16p,16g.6,2a#6,32p,8a6,8g6,8f6,8a6,2g6")
```

## API Reference

| Function | Description |
|----------|-------------|
| `BUZZER.play(melody:string)` | Play a melody string in [RTTTL format](https://en.wikipedia.org/wiki/Ring_Tone_Text_Transfer_Language). |

You can find RTTTL melody strings online — search for "RTTTL ringtones" to find collections of ready-to-use melodies.

## See Also

- [BUTTON — Physical button override](button.md) — Combine: play a sound on button press
- [ZHB — Zigbee Hub](zhb.md) — Combine: play a sound when a Zigbee event occurs
- [GPIO — Direct pin control](gpio.md) — Lower-level `tone()` function for simple frequencies
- [Example: Play melody](../../examples/buzzer/play_melody.be)
- [Example: Doorbell with Zigbee button](../../examples/buzzer/doorbell.be)
