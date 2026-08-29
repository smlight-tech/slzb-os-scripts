# RF — Sub-1 GHz RF Transceiver (Sniff & Replay)

> Available since: v3.3.5 | **SLZB Ultima with the RF Transceiver Add-On (CC1101) only**

Capture, replay and store simple OOK/ASK radio commands on 315 / 433 / 868 / 915 MHz: gate and garage remotes, wireless sockets, doorbells, blinds, alarm key fobs. Commands are handled as **raw pulse sequences**, so no protocol decoding is needed — whatever the receiver captured can be sent back as is.

The add-on must be installed and selected as add-on type **"RF Transceiver"** on the *Mode* page (reboot required). Everything the module does is also available on the *RF Transceiver* web page and via `POST /api2?action=21`.

## Quick Example

```berry
import RF

# log every captured command
RF.on_receive(def (raw, rssi, pulses)
  SLZB.log("RF: " .. pulses .. " pulses, RSSI " .. rssi .. " dBm")
  SLZB.log(raw)
end)

# replay a command saved on the RF page, 3 times
RF.sendSaved("gate_open", 3)
```

## Raw Command Format

A raw command is a comma separated list of pulse durations in **microseconds**, alternating *carrier ON* / *carrier OFF*, starting with *carrier ON*:

```
"350,1050,350,1050,1050,350,350,1050,..."
```

- Timing resolution is 20 µs (both when capturing and when sending).
- Maximum 1024 pulses per command, maximum 5 s of air time per `send()`.
- Between repetitions the longest "carrier OFF" pulse of the command (or 10 ms) is inserted as a gap.
- Rolling-code remotes (KeeLoq, Somfy RTS, ...) **cannot** be replayed — every transmission is different.

## API Reference

### Status & Settings

| Function | Description |
|----------|-------------|
| `RF.isPresent() -> bool` | `true` if the CC1101 add-on was detected at boot. All other functions return `false` / empty values when it is not. |
| `RF.getStatus() -> string` | Current state: `"rx"` (listening), `"idle"`, `"tx"`, `"no_chip"`, `"not_init"`. |
| `RF.isBusy() -> bool` | `true` while a transmission is queued / in progress (`send()` returns `false` meanwhile). |
| `RF.getFrequency() -> int` | Receiver frequency in Hz (also the default TX frequency). |
| `RF.setFrequency(hz:int) -> bool` | Change frequency (runtime only, not persisted). Allowed bands: 300–348, 387–464, 779–928 MHz. Use the `RF.Freq_*` constants. |
| `RF.getRxEnabled() -> bool` | `true` if the receiver (sniffer) is running. |
| `RF.setRxEnabled(en:bool) -> bool` | Start / stop the receiver (runtime only). Stopping it saves ~3 % CPU and stops `on_receive` events. |

### Sending

| Function | Description |
|----------|-------------|
| `RF.send(raw:string, freq_hz:int?, repeats:int=1) -> bool` | Transmit a raw command. `freq_hz` = `0` or omitted → current frequency; `repeats` 1..10, default 1. Non-blocking: the command is queued and sent by the RF task, the receiver resumes automatically afterwards. Returns: `bool` — `false` if busy, invalid command or add-on missing. |
| `RF.sendSaved(name:string, repeats:int?) -> bool` | Transmit a command saved on the device (see below / RF page). Uses the frequency the command was saved with. |

### Last Received Command

The receiver keeps the last valid capture (noise and captures shorter than 20 pulses / 10 ms are discarded).

| Function | Description |
|----------|-------------|
| `RF.getRaw() -> string` | Raw pulse string of the last captured command, `""` if none. |
| `RF.getRssi() -> int` | Peak RSSI of the last capture, dBm. |
| `RF.getPulses() -> int` | Number of pulses in the last capture. |
| `RF.getDuration() -> int` | Air time of the last capture, µs. |
| `RF.getLastFrequency() -> int` | Frequency (Hz) the last command was captured on. |
| `RF.clear() -> nil` | Forget the last captured command. |

### Saved Commands

Commands are stored as `/rf/<name>.json` on the device and shared with the *RF Transceiver* web page. Names: letters, digits, `_`, `-`, max 24 characters.

| Function | Description |
|----------|-------------|
| `RF.save(name:string, raw:string, freq_hz:int?) -> bool` | Save a raw command under a name (`freq_hz` `0`/omitted → current frequency). Overwrites an existing command. |
| `RF.saveLast(name:string) -> bool` | Save the last captured command under a name (frequency taken from the capture). |
| `RF.remove(name:string) -> bool` | Delete a saved command. |
| `RF.getSaved(name:string) -> string` | Raw pulse string of a saved command, `""` if it does not exist. |
| `RF.list() -> list<string>` | Names of all saved commands. |

### Events

| Function | Description |
|----------|-------------|
| `RF.on_receive(callback:function(raw:string, rssi:int, pulses:int) -> nil) -> nil` | Register a callback fired for every captured command. Fires only while the receiver is enabled. |

## Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `RF.Freq_315` | 315000000 | 315 MHz (US/Asia remotes) |
| `RF.Freq_433` | 433920000 | 433.92 MHz (most common) |
| `RF.Freq_868` | 868350000 | 868.35 MHz (EU) |
| `RF.Freq_915` | 915000000 | 915 MHz (US ISM) |

## Notes

- Sending and receiving share one radio: during `send()` the receiver is paused and restarted automatically.
- `send()` / `sendSaved()` are asynchronous — they return `true` as soon as the command is queued. Wait for `RF.isBusy()` to become `false` before queuing the next one (only one command can be queued at a time).
- Captures are also published to the web UI (SSE `RF_CODE`) and to MQTT topic `status/rf` as `{"raw","freq","rssi","count","dur","seq"}`.
- Frequency and receiver state set from a script are not saved to the config; use the *RF Transceiver* page for persistent settings.
- HTTP API equivalent: `POST /api2?action=21` with `code=<raw>` or `name=<saved>` (+ optional `freq`, `repeats`).

## Examples

### Learn a button and save it by name

```berry
import RF

var learning = "socket_on"   # name to save the next capture under

RF.on_receive(def (raw, rssi, pulses)
  if learning != "" && rssi > -80
    if RF.saveLast(learning)
      SLZB.log("Saved '" .. learning .. "' (" .. pulses .. " pulses)")
    end
    learning = ""
  end
end)
```

### Zigbee button controls a 433 MHz socket

```berry
import RF
import ZHB
ZHB.waitForStart(0xff)

var button = ZHB.getDevice("Kitchen Button")

ZHB.on_action(def (action, dev)
  if button != nil && dev.getNwk() == button.getNwk()
    if action == "single"
      RF.sendSaved("socket_on", 3)
    elif action == "double"
      RF.sendSaved("socket_off", 3)
    end
  end
end)
```

### React to a specific remote (compare a captured signature)

Raw captures of the same button differ slightly in timing, so compare a coarse signature (pulse count + rough duration) instead of the full string:

```berry
import RF

def near(a, b, tol) return a > b - tol && a < b + tol end

RF.on_receive(def (raw, rssi, pulses)
  # gate remote: ~ 25 frames x 25 pulses, about 1.2 s
  if near(pulses, 625, 60) && near(RF.getDuration(), 1200000, 200000)
    SLZB.log("Gate remote pressed")
    BUZZER.playPreset(BUZZER.Snd_Beep)
  end
end)
```

### Send on another frequency

```berry
import RF
RF.send("500,1500,500,1500,1500,500", RF.Freq_868, 2)   # receiver returns to its own frequency afterwards
```

## See Also

- [IR Receiver](ir_receiver.md) / [IR Transmitter](ir_transmitter.md) — the same learn & replay idea for infrared
- [ZHB — Zigbee Hub](zhb.md) — Combine: control RF devices from Zigbee buttons
- [BUTTON — Physical button](button.md) — Combine: send an RF command on button press
- [MQTT](mqtt.md) — Combine: bridge RF captures to your MQTT broker
