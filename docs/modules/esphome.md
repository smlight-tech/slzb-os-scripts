# ESPHOME Module

Control ESPHome devices from Berry scripts via the ESPHome REST API (web_server component). Works with any ESPHome device on the local network, including SMLIGHT SLWF-01 and SLWF-08 controllers.

## Prerequisites

**The ESPHome device must have the `web_server` component enabled** in its YAML configuration:

```yaml
web_server:
  port: 80
```

Without `web_server`, the device won't expose the REST API endpoints that this module uses. The ESPHome native API (port 6053) is **not** supported.

## Setup

### Option A — Configure via UI (recommended)

1. Go to **Scripts Integrations** page
2. Click the **SLWF-01**, **SLWF-08**, or other ESPHome-based tile
3. Add your devices with a name and IP address
4. Enable and save

### Option B — Use IP directly in script

No configuration needed — just pass the device IP to any function:

```berry
import ESPHOME

ESPHOME.turn_on("192.168.1.60", "switch", "relay_1")
```

## Finding Entity IDs

ESPHome entity IDs are derived from the `name` or `id` field in the YAML config. For example:

```yaml
switch:
  - platform: gpio
    name: "Relay 1"
    id: relay_1
```

This creates the entity `relay_1` accessible at `/switch/relay_1`. You can also browse all entities by opening `http://<device-ip>/` in a browser.

## Functions

### ESPHOME.turn_on(device, domain, id)

Turn on an entity.

| Parameter | Type | Description |
|-----------|------|-------------|
| `device` | string | Device name (from UI config) or IP address |
| `domain` | string | Entity domain: `"switch"`, `"light"`, `"fan"`, etc. |
| `id` | string | Entity ID |

**Returns:** `int` — HTTP status code (200 on success)

```berry
import ESPHOME

ESPHOME.turn_on("My Device", "switch", "relay_1")
ESPHOME.turn_on("192.168.1.60", "light", "ceiling")
```

### ESPHOME.turn_off(device, domain, id)

Turn off an entity.

```berry
import ESPHOME

ESPHOME.turn_off("My Device", "switch", "relay_1")
```

### ESPHOME.toggle(device, domain, id)

Toggle an entity on/off.

```berry
import ESPHOME

ESPHOME.toggle("My Device", "switch", "relay_1")
```

### ESPHOME.press(device, id)

Press a button entity.

| Parameter | Type | Description |
|-----------|------|-------------|
| `device` | string | Device name or IP |
| `id` | string | Button entity ID |

```berry
import ESPHOME

ESPHOME.press("My Device", "restart_button")
```

### ESPHOME.set_number(device, id, value)

Set a number entity to a specific value.

| Parameter | Type | Description |
|-----------|------|-------------|
| `device` | string | Device name or IP |
| `id` | string | Number entity ID |
| `value` | int / real | Target value |

```berry
import ESPHOME

ESPHOME.set_number("My Device", "target_temp", 22)
ESPHOME.set_number("My Device", "fan_speed", 75.5)
```

### ESPHOME.set_select(device, id, option)

Set a select entity to a specific option.

| Parameter | Type | Description |
|-----------|------|-------------|
| `device` | string | Device name or IP |
| `id` | string | Select entity ID |
| `option` | string | Option value |

```berry
import ESPHOME

ESPHOME.set_select("My Device", "mode", "cool")
ESPHOME.set_select("My Device", "fan_mode", "auto")
```

### ESPHOME.set_climate(device, id, target_temp [, mode])

Control a climate entity (A/C, thermostat).

| Parameter | Type | Description |
|-----------|------|-------------|
| `device` | string | Device name or IP |
| `id` | string | Climate entity ID |
| `target_temp` | int / real | Target temperature |
| `mode` | string | (optional) Climate mode: `"heat"`, `"cool"`, `"auto"`, `"off"`, etc. |

```berry
import ESPHOME

# Set temperature only
ESPHOME.set_climate("My AC", "climate_1", 22)

# Set temperature and mode
ESPHOME.set_climate("My AC", "climate_1", 24, "cool")
```

### ESPHOME.set_light(device, id, on [, brightness [, r, g, b]])

Control a light entity with optional brightness and RGB color.

| Parameter | Type | Description |
|-----------|------|-------------|
| `device` | string | Device name or IP |
| `id` | string | Light entity ID |
| `on` | bool | `true` to turn on, `false` to turn off |
| `brightness` | int | (optional) Brightness level (0–255) |
| `r` | int | (optional) Red component (0–255) |
| `g` | int | (optional) Green component (0–255) |
| `b` | int | (optional) Blue component (0–255) |

```berry
import ESPHOME

# Turn on
ESPHOME.set_light("My Device", "ceiling", true)

# Turn on with brightness
ESPHOME.set_light("My Device", "ceiling", true, 128)

# Turn on with brightness and color
ESPHOME.set_light("My Device", "led_strip", true, 255, 255, 0, 0)

# Turn off
ESPHOME.set_light("My Device", "ceiling", false)
```

### ESPHOME.get_sensor(device, id)

Read a sensor entity's current value.

| Parameter | Type | Description |
|-----------|------|-------------|
| `device` | string | Device name or IP |
| `id` | string | Sensor entity ID |

**Returns:** `map` with keys:

| Key | Type | Description |
|-----|------|-------------|
| `id` | string | Entity ID |
| `state` | string | Human-readable state (e.g. "23.5 °C") |
| `value` | int / string | Numeric value (int) or string if not numeric |

```berry
import ESPHOME

var s = ESPHOME.get_sensor("My Device", "temperature")
print("Temp: " .. str(s["value"]))
print("State: " .. s["state"])
```

### ESPHOME.get_state(device, domain, id)

Read any entity's state.

| Parameter | Type | Description |
|-----------|------|-------------|
| `device` | string | Device name or IP |
| `domain` | string | Entity domain |
| `id` | string | Entity ID |

**Returns:** `map` with keys `id`, `state`, and optionally `value`

```berry
import ESPHOME

var s = ESPHOME.get_state("My Device", "switch", "relay_1")
print("Relay is: " .. s["state"])   # "ON" or "OFF"
```

### ESPHOME.devices()

List all configured ESPHome device names (from UI config).

**Returns:** `list` of strings

```berry
import ESPHOME

var devs = ESPHOME.devices()
for name : devs
    print(name)
end
```

## SLWF-01 and SLWF-08 Aliases

SMLIGHT products have dedicated module aliases that work identically to ESPHOME:

```berry
import SLWF01
SLWF01.set_climate("Bedroom AC", "climate_1", 22, "cool")

import SLWF08
SLWF08.turn_on("Living Room TV", "switch", "cec_power")
```

See [SLWF01 documentation](slwf01.md) and [SLWF08 documentation](slwf08.md) for product-specific details.

## Examples

### Toggle a relay on button press

```berry
import ESPHOME
import BUTTON

BUTTON.on_press(def ()
    ESPHOME.toggle("My Device", "switch", "relay_1")
end)
```

### A/C control based on Zigbee temperature

```berry
import ESPHOME
import ZB

ZB.on_message(def (msg)
    if msg["cluster"] == 0x0402
        var temp = msg["value"] / 100.0
        if temp > 28
            ESPHOME.set_climate("My AC", "climate_1", 24, "cool")
        elif temp < 18
            ESPHOME.set_climate("My AC", "climate_1", 22, "heat")
        end
    end
end)
```

### Read sensor and log

```berry
import ESPHOME
import TIMER
import SLZB

TIMER.every(60000, def ()
    var s = ESPHOME.get_sensor("My Device", "temperature")
    if s
        SLZB.log("ESPHome temp: " .. s["state"])
    end
end)
```

### Control light color based on weather

```berry
import ESPHOME
import WEATHER
import TIMER

TIMER.every(300000, def ()
    var w = WEATHER.get()
    if w
        var t = w["temp"]
        if t > 30
            ESPHOME.set_light("My Device", "status_led", true, 255, 255, 0, 0)
        elif t < 5
            ESPHOME.set_light("My Device", "status_led", true, 255, 0, 0, 255)
        else
            ESPHOME.set_light("My Device", "status_led", true, 255, 0, 255, 0)
        end
    end
end)
```

## ESPHome Entity Domains

Common domains and their available actions:

| Domain | turn_on | turn_off | toggle | Other |
|--------|:-------:|:--------:|:------:|-------|
| `switch` | yes | yes | yes | |
| `light` | yes | yes | yes | `set_light()` for brightness/color |
| `fan` | yes | yes | yes | |
| `climate` | | | | `set_climate()` for temp/mode |
| `button` | | | | `press()` |
| `number` | | | | `set_number()` for value |
| `select` | | | | `set_select()` for option |
| `sensor` | | | | `get_sensor()` to read |

## Notes

- **Requires `web_server` component** enabled in the ESPHome device's YAML configuration
- The ESPHome native API (protobuf, port 6053) is **not** supported
- Uses HTTP (not HTTPS) to communicate with devices on the local network
- Each function call makes one HTTP request (~2-4 KB temporary RAM, freed immediately)
- Device name lookup is case-insensitive
- If a name contains a dot (`.`), it's treated as an IP/hostname directly
- SLWF-01 and SLWF-08 devices configured in the UI are automatically found by name
- Sensor values are returned as integers (rounded from float) — use `get_state()` and check `state` for the full string representation
- Devices must be on the same network as the SLZB device
