# SLWF01 Module

Control SMLIGHT SLWF-01 A/C controllers from Berry scripts. This module is an alias for the [ESPHOME module](esphome.md) — all functions are identical, just use `SLWF01` instead of `ESPHOME`.

## Prerequisites

The SLWF-01 device must have the `web_server` component enabled in its ESPHome configuration.

## Setup

### Option A — Configure via UI (recommended)

1. Go to **Scripts Integrations** page
2. Click the **SLWF-01** tile
3. Add your devices with a name and IP address
4. Enable and save

### Option B — Use IP directly in script

```berry
import SLWF01

SLWF01.set_climate("192.168.1.60", "climate_1", 22, "cool")
```

## Common A/C Functions

### Set temperature and mode

```berry
import SLWF01

SLWF01.set_climate("Bedroom AC", "climate_1", 22, "cool")
SLWF01.set_climate("Bedroom AC", "climate_1", 24, "heat")
SLWF01.set_climate("Bedroom AC", "climate_1", 23, "auto")
```

### Turn off A/C

```berry
import SLWF01

SLWF01.set_climate("Bedroom AC", "climate_1", 0, "off")
```

### Read temperature sensor

```berry
import SLWF01

var s = SLWF01.get_sensor("Bedroom AC", "temperature")
print("Current temp: " .. s["state"])
```

## All Available Functions

Since SLWF01 is an alias for ESPHOME, all functions are available:

| Function | Description |
|----------|-------------|
| `turn_on(device, domain, id)` | Turn on an entity |
| `turn_off(device, domain, id)` | Turn off an entity |
| `toggle(device, domain, id)` | Toggle an entity |
| `press(device, id)` | Press a button |
| `set_number(device, id, value)` | Set a number value |
| `set_select(device, id, option)` | Set a select option |
| `set_climate(device, id, temp [, mode])` | Control climate/A/C |
| `set_light(device, id, on [, bri [, r, g, b]])` | Control a light |
| `get_sensor(device, id)` | Read a sensor |
| `get_state(device, domain, id)` | Read any entity state |
| `devices()` | List configured devices |

See the [ESPHOME module documentation](esphome.md) for full details on each function.

## Examples

### Auto-cool on high Zigbee temperature

```berry
import SLWF01
import ZB

ZB.on_message(def (msg)
    if msg["cluster"] == 0x0402
        var temp = msg["value"] / 100.0
        if temp > 28
            SLWF01.set_climate("Bedroom AC", "climate_1", 24, "cool")
        elif temp < 20
            SLWF01.set_climate("Bedroom AC", "climate_1", 0, "off")
        end
    end
end, 600000)
```

### Turn on A/C on button press

```berry
import SLWF01
import BUTTON

BUTTON.on_press(def ()
    SLWF01.set_climate("Bedroom AC", "climate_1", 22, "cool")
end)
```

### Log temperature to Google Sheets

```berry
import SLWF01
import GSHEETS
import TIMER

TIMER.setInterval(def()
    var s = SLWF01.get_sensor("Bedroom AC", "temperature")
    if s
        GSHEETS.append("bedroom_temp", s["value"])
    end
end)
```

## Notes

- SLWF01 is an alias for the ESPHOME module — all functions are identical
- Requires `web_server` component enabled on the SLWF-01 device
- Uses HTTP on the local network
- Each call makes one HTTP request (~2-4 KB temporary RAM, freed immediately)
- Entity IDs (like `climate_1`) depend on your ESPHome YAML configuration
