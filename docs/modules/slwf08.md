# SLWF08 Module

Control SMLIGHT SLWF-08 HDMI-CEC controllers from Berry scripts. This module is an alias for the [ESPHOME module](esphome.md) — all functions are identical, just use `SLWF08` instead of `ESPHOME`.

## Prerequisites

The SLWF-08 device must have the `web_server` component enabled in its ESPHome configuration.

## Setup

### Option A — Configure via UI (recommended)

1. Go to **Scripts Integrations** page
2. Click the **SLWF-08** tile
3. Add your devices with a name and IP address
4. Enable and save

### Option B — Use IP directly in script

```berry
import SLWF08

SLWF08.turn_on("192.168.1.70", "switch", "cec_power")
```

## Common HDMI-CEC Functions

### Power on/off TV

```berry
import SLWF08

SLWF08.turn_on("Living Room TV", "switch", "cec_power")
SLWF08.turn_off("Living Room TV", "switch", "cec_power")
```

### Toggle power

```berry
import SLWF08

SLWF08.toggle("Living Room TV", "switch", "cec_power")
```

### Change HDMI input

```berry
import SLWF08

SLWF08.set_number("Living Room TV", "hdmi_input", 2)
```

### Set volume

```berry
import SLWF08

SLWF08.set_number("Living Room TV", "volume", 30)
```

### Press a button (e.g. mute)

```berry
import SLWF08

SLWF08.press("Living Room TV", "mute")
```

## All Available Functions

Since SLWF08 is an alias for ESPHOME, all functions are available:

| Function | Description |
|----------|-------------|
| `turn_on(device, domain, id)` | Turn on an entity |
| `turn_off(device, domain, id)` | Turn off an entity |
| `toggle(device, domain, id)` | Toggle an entity |
| `press(device, id)` | Press a button |
| `set_number(device, id, value)` | Set a number value |
| `set_select(device, id, option)` | Set a select option |
| `set_climate(device, id, temp [, mode])` | Control climate |
| `set_light(device, id, on [, bri [, r, g, b]])` | Control a light |
| `get_sensor(device, id)` | Read a sensor |
| `get_state(device, domain, id)` | Read any entity state |
| `devices()` | List configured devices |

See the [ESPHOME module documentation](esphome.md) for full details on each function.

## Examples

### Turn on TV on button press

```berry
import SLWF08
import BUTTON

BUTTON.on_press(def ()
    SLWF08.turn_on("Living Room TV", "switch", "cec_power")
end, 60000)
```

### Turn off TV at night

```berry
import SLWF08
import TIMER
import TIME

TIMER.setInterval(def()
    var t = TIME.getAll()
    if t["hour"] == 23 && t["min"] == 0
        SLWF08.turn_off("Living Room TV", "switch", "cec_power")
    end
end, 30000)
```

### Switch input on Zigbee button

```berry
import SLWF08
import ZB

var current_input = 1

ZB.on_message(def (msg)
    if msg["cluster"] == 0x0006
        current_input = current_input == 1 ? 2 : 1
        SLWF08.set_number("Living Room TV", "hdmi_input", current_input)
    end
end)
```

### Notify when TV turns on

```berry
import SLWF08
import TELEGRAM
import TIMER

TIMER.setInterval(def()
    var s = SLWF08.get_state("Living Room TV", "switch", "cec_power")
    if s && s["state"] == "ON"
        TELEGRAM.send("TV is on!")
    end
end)
```

## Notes

- SLWF08 is an alias for the ESPHOME module — all functions are identical
- Requires `web_server` component enabled on the SLWF-08 device
- Uses HTTP on the local network
- Each call makes one HTTP request (~2-4 KB temporary RAM, freed immediately)
- Entity IDs (like `cec_power`, `hdmi_input`) depend on your ESPHome YAML configuration
- Browse `http://<device-ip>/` to see all available entities
