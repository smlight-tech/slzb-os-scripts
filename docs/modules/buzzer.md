# BUZZER — Melody Player

> Available since: v3.2.5.dev1 | **Ultima3 only**

Play melodies on the built-in buzzer using RTTTL format strings or built-in sound presets.

## Quick Example

```berry
import BUZZER

# Play a preset sound
BUZZER.playPreset(BUZZER.Snd_Doorbell)

# Play a custom RTTTL melody
BUZZER.play("Arkanoid:d=4,o=5,b=140:8g6,16p,16g.6,2a#6,32p,8a6,8g6,8f6,8a6,2g6")
```

## API Reference

| Function | Description |
|----------|-------------|
| `BUZZER.play(melody:string)` | Play a melody string in [RTTTL format](https://en.wikipedia.org/wiki/Ring_Tone_Text_Transfer_Language). |
| `BUZZER.playPreset(id:int)` | Play a built-in sound preset by ID. Returns `true` on success, `false` if ID is invalid. |

## Sound Presets

Use the constants below with `BUZZER.playPreset()`:

| Constant | ID | Sound |
|----------|----|-------|
| `BUZZER.Snd_Doorbell` | 0 | Classic two-tone doorbell |
| `BUZZER.Snd_Alert` | 1 | Urgent alert / alarm |
| `BUZZER.Snd_Success` | 2 | Positive confirmation |
| `BUZZER.Snd_Error` | 3 | Error / failure signal |
| `BUZZER.Snd_Warning` | 4 | Warning beep |
| `BUZZER.Snd_Notify` | 5 | Gentle notification |
| `BUZZER.Snd_Siren` | 6 | Emergency siren pattern |
| `BUZZER.Snd_Chime` | 7 | Pleasant chime |
| `BUZZER.Snd_Beep` | 8 | Single short beep |
| `BUZZER.Snd_DoubleBeep` | 9 | Double short beep |
| `BUZZER.Snd_Startup` | 10 | Device startup sound |
| `BUZZER.Snd_Shutdown` | 11 | Device shutdown sound |
| `BUZZER.Snd_Tetris` | 12 | Tetris theme |
| `BUZZER.Snd_Mario` | 13 | Mario theme |
| `BUZZER.Snd_Arkanoid` | 14 | Arkanoid theme |

## Notes

- Playback is non-blocking — the melody plays in the background without blocking script execution.
- Maximum RTTTL string length: 512 characters.
- You can find RTTTL melody strings online — search for "RTTTL ringtones" to find collections of ready-to-use melodies.
- Presets can also be triggered via HTTP API: `POST /api2?action=13` with `preset=<id>` parameter.

## See Also

- [BUTTON — Physical button override](button.md) — Combine: play a sound on button press
- [ZHB — Zigbee Hub](zhb.md) — Combine: play a sound when a Zigbee event occurs
- [GPIO — Direct pin control](gpio.md) — Lower-level `tone()` function for simple frequencies
- [Example: Play melody](../../examples/buzzer/play_melody.be)
- [Example: Doorbell with Zigbee button](../../examples/buzzer/doorbell.be)
