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

## API Reference

Since SLWF01 is an alias for ESPHOME, all functions are available:

| Function | Description |
|----------|-------------|
| `SLWF01.turn_on(device:string, domain:string, id:string) -> int` | Turn on an entity |
| `SLWF01.turn_off(device:string, domain:string, id:string) -> int` | Turn off an entity |
| `SLWF01.toggle(device:string, domain:string, id:string) -> int` | Toggle an entity |
| `SLWF01.press(device:string, id:string) -> int` | Press a button |
| `SLWF01.set_number(device:string, id:string, value:int\|real) -> int` | Set a number value |
| `SLWF01.set_select(device:string, id:string, option:string) -> int` | Set a select option |
| `SLWF01.set_climate(device:string, id:string, target_temp:int\|real, mode:string?) -> int` | Control climate/A/C |
| `SLWF01.set_light(device:string, id:string, on:bool, brightness:int?, r:int?, g:int?, b:int?) -> int` | Control a light |
| `SLWF01.get_sensor(device:string, id:string) -> map` | Read a sensor |
| `SLWF01.get_state(device:string, domain:string, id:string) -> map` | Read any entity state |
| `SLWF01.devices() -> list<string>` | List configured devices |

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
