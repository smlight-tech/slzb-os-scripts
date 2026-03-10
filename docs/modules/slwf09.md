# SLWF09 Module

Control SMLIGHT SLWF-09 WLED controllers from Berry scripts. This module is an alias for the [WLED module](wled.md) — all functions are identical, just use `SLWF09` instead of `WLED`.

## Setup

### Option A — Configure via UI (recommended)

1. Go to **Scripts Integrations** page
2. Click the **SLWF-09** tile
3. Add your devices with a name and IP address
4. Enable and save

### Option B — Use IP directly in script

No configuration needed — just pass the device IP to any function:

```berry
import SLWF09

SLWF09.on("192.168.1.50")
```

## Functions

### SLWF09.on(device)

Turn the device on.

| Parameter | Type | Description |
|-----------|------|-------------|
| `device` | string | Device name (from UI config) or IP address |

**Returns:** `int` — HTTP status code (200 on success)

```berry
import SLWF09

SLWF09.on("Living Room")
SLWF09.on("192.168.1.50")
```

### SLWF09.off(device)

Turn the device off.

```berry
import SLWF09

SLWF09.off("Living Room")
```

### SLWF09.toggle(device)

Toggle the device on/off.

```berry
import SLWF09

SLWF09.toggle("Living Room")
```

### SLWF09.set_brightness(device, brightness)

Set brightness level.

| Parameter | Type | Description |
|-----------|------|-------------|
| `device` | string | Device name or IP |
| `brightness` | int | Brightness level (0–255) |

```berry
import SLWF09

SLWF09.set_brightness("Living Room", 128)
```

### SLWF09.set_color(device, color)

Set the color of the first segment.

| Parameter | Type | Description |
|-----------|------|-------------|
| `device` | string | Device name or IP |
| `color` | int | RGB color as hex (e.g. `0xFF0000` for red) |

```berry
import SLWF09

SLWF09.set_color("Living Room", 0xFF0000)   # red
SLWF09.set_color("Living Room", 0x00FF00)   # green
SLWF09.set_color("Living Room", 0x0000FF)   # blue
SLWF09.set_color("Living Room", 0xFFFFFF)   # white
```

### SLWF09.set_effect(device, effect_id)

Set the LED effect by ID.

| Parameter | Type | Description |
|-----------|------|-------------|
| `device` | string | Device name or IP |
| `effect_id` | int | WLED effect ID (0 = Solid, 1 = Blink, etc.) |

```berry
import SLWF09

SLWF09.set_effect("Living Room", 0)    # Solid
SLWF09.set_effect("Living Room", 38)   # Rainbow
SLWF09.set_effect("Living Room", 9)    # Chase
```

### SLWF09.set_palette(device, palette_id)

Set the color palette for the current effect.

| Parameter | Type | Description |
|-----------|------|-------------|
| `device` | string | Device name or IP |
| `palette_id` | int | WLED palette ID |

```berry
import SLWF09

SLWF09.set_palette("Living Room", 6)   # Party palette
```

### SLWF09.set_speed(device, speed)

Set the effect speed.

| Parameter | Type | Description |
|-----------|------|-------------|
| `device` | string | Device name or IP |
| `speed` | int | Speed (0–255) |

```berry
import SLWF09

SLWF09.set_speed("Living Room", 200)
```

### SLWF09.set_state(device, json_string)

Send a raw JSON state to the WLED API for full control. See [WLED JSON API](https://kno.wled.ge/interfaces/json-api/) for all available fields.

| Parameter | Type | Description |
|-----------|------|-------------|
| `device` | string | Device name or IP |
| `json_string` | string | Raw JSON string for `/json/state` |

```berry
import SLWF09

# Turn on with brightness 200 and red color in one request
SLWF09.set_state("Living Room", '{"on":true,"bri":200,"seg":[{"col":[[255,0,0]]}]}')
```

### SLWF09.get_state(device)

Read the current state from the device.

| Parameter | Type | Description |
|-----------|------|-------------|
| `device` | string | Device name or IP |

**Returns:** `map` with keys:
| Key | Type | Description |
|-----|------|-------------|
| `on` | int | 1 = on, 0 = off |
| `bri` | int | Brightness (0–255) |
| `color` | int | First segment color as 0xRRGGBB |
| `fx` | int | Effect ID |
| `sx` | int | Effect speed |
| `pal` | int | Palette ID |

```berry
import SLWF09

var state = SLWF09.get_state("Living Room")
print(state["on"])     # 1 or 0
print(state["bri"])    # 0-255
print(state["color"])  # e.g. 16711680 (0xFF0000)
```

### SLWF09.devices()

List all configured device names (from UI config).

**Returns:** `list` of strings

```berry
import SLWF09

var devs = SLWF09.devices()
for name : devs
    print(name)
end
```

## Examples

### Night light on button press

```berry
import SLWF09
import BUTTON

BUTTON.on_press(def ()
    SLWF09.set_color("Bedroom Strip", 0xFF8C00)
    SLWF09.set_brightness("Bedroom Strip", 30)
    SLWF09.on("Bedroom Strip")
end)
```

### Flash red on Zigbee alert

```berry
import SLWF09
import ZB
import TIMER

ZB.on_message(def (msg)
    if msg["cluster"] == 0x0500
        SLWF09.set_color("Alert Strip", 0xFF0000)
        SLWF09.set_effect("Alert Strip", 1)
        SLWF09.on("Alert Strip")
        TIMER.once(10000, def ()
            SLWF09.off("Alert Strip")
        end)
    end
end)
```

### Cycle through all configured devices

```berry
import SLWF09

var devs = SLWF09.devices()
for name : devs
    SLWF09.set_color(name, 0x00FF00)
    SLWF09.on(name)
end
```

## Notes

- SLWF09 is an alias for the WLED module — all functions are identical
- Uses HTTP (not HTTPS) to communicate with devices on the local network
- Each function call makes one HTTP request (~2-4 KB temporary RAM, freed immediately)
- Device name lookup is case-insensitive
- If a name contains a dot (`.`), it's treated as an IP/hostname directly
- Devices must be on the same network as the SLZB device
- `set_state()` gives full access to the WLED JSON API for advanced use cases
