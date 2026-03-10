# SLWF03 Module

Control SMLIGHT SLWF-03 WLED controllers from Berry scripts. This module is an alias for the [WLED module](wled.md) — all functions are identical, just use `SLWF03` instead of `WLED`.

## Setup

### Option A — Configure via UI (recommended)

1. Go to **Scripts Integrations** page
2. Click the **SLWF-03** tile
3. Add your devices with a name and IP address
4. Enable and save

### Option B — Use IP directly in script

No configuration needed — just pass the device IP to any function:

```berry
import SLWF03

SLWF03.on("192.168.1.50")
```

## Functions

### SLWF03.on(device)

Turn the device on.

| Parameter | Type | Description |
|-----------|------|-------------|
| `device` | string | Device name (from UI config) or IP address |

**Returns:** `int` — HTTP status code (200 on success)

```berry
import SLWF03

SLWF03.on("Kitchen Strip")
SLWF03.on("192.168.1.50")
```

### SLWF03.off(device)

Turn the device off.

```berry
import SLWF03

SLWF03.off("Kitchen Strip")
```

### SLWF03.toggle(device)

Toggle the device on/off.

```berry
import SLWF03

SLWF03.toggle("Kitchen Strip")
```

### SLWF03.set_brightness(device, brightness)

Set brightness level.

| Parameter | Type | Description |
|-----------|------|-------------|
| `device` | string | Device name or IP |
| `brightness` | int | Brightness level (0–255) |

```berry
import SLWF03

SLWF03.set_brightness("Kitchen Strip", 128)
```

### SLWF03.set_color(device, color)

Set the color of the first segment.

| Parameter | Type | Description |
|-----------|------|-------------|
| `device` | string | Device name or IP |
| `color` | int | RGB color as hex (e.g. `0xFF0000` for red) |

```berry
import SLWF03

SLWF03.set_color("Kitchen Strip", 0xFF0000)   # red
SLWF03.set_color("Kitchen Strip", 0x00FF00)   # green
SLWF03.set_color("Kitchen Strip", 0x0000FF)   # blue
SLWF03.set_color("Kitchen Strip", 0xFFFFFF)   # white
```

### SLWF03.set_effect(device, effect_id)

Set the LED effect by ID.

| Parameter | Type | Description |
|-----------|------|-------------|
| `device` | string | Device name or IP |
| `effect_id` | int | WLED effect ID (0 = Solid, 1 = Blink, etc.) |

```berry
import SLWF03

SLWF03.set_effect("Kitchen Strip", 0)    # Solid
SLWF03.set_effect("Kitchen Strip", 38)   # Rainbow
SLWF03.set_effect("Kitchen Strip", 9)    # Chase
```

### SLWF03.set_palette(device, palette_id)

Set the color palette for the current effect.

| Parameter | Type | Description |
|-----------|------|-------------|
| `device` | string | Device name or IP |
| `palette_id` | int | WLED palette ID |

```berry
import SLWF03

SLWF03.set_palette("Kitchen Strip", 6)   # Party palette
```

### SLWF03.set_speed(device, speed)

Set the effect speed.

| Parameter | Type | Description |
|-----------|------|-------------|
| `device` | string | Device name or IP |
| `speed` | int | Speed (0–255) |

```berry
import SLWF03

SLWF03.set_speed("Kitchen Strip", 200)
```

### SLWF03.set_state(device, json_string)

Send a raw JSON state to the WLED API for full control. See [WLED JSON API](https://kno.wled.ge/interfaces/json-api/) for all available fields.

| Parameter | Type | Description |
|-----------|------|-------------|
| `device` | string | Device name or IP |
| `json_string` | string | Raw JSON string for `/json/state` |

```berry
import SLWF03

# Turn on with brightness 200 and red color in one request
SLWF03.set_state("Kitchen Strip", '{"on":true,"bri":200,"seg":[{"col":[[255,0,0]]}]}')
```

### SLWF03.get_state(device)

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
import SLWF03

var state = SLWF03.get_state("Kitchen Strip")
print(state["on"])     # 1 or 0
print(state["bri"])    # 0-255
print(state["color"])  # e.g. 16711680 (0xFF0000)
```

### SLWF03.devices()

List all configured device names (from UI config).

**Returns:** `list` of strings

```berry
import SLWF03

var devs = SLWF03.devices()
for name : devs
    print(name)
end
```

## Examples

### Night light on button press

```berry
import SLWF03
import BUTTON

BUTTON.on_press(def ()
    SLWF03.set_color("Bedroom Strip", 0xFF8C00)
    SLWF03.set_brightness("Bedroom Strip", 30)
    SLWF03.on("Bedroom Strip")
end)
```

### Flash red on Zigbee alert

```berry
import SLWF03
import ZB
import TIMER

ZB.on_message(def (msg)
    if msg["cluster"] == 0x0500
        SLWF03.set_color("Alert Strip", 0xFF0000)
        SLWF03.set_effect("Alert Strip", 1)
        SLWF03.on("Alert Strip")
        TIMER.once(10000, def ()
            SLWF03.off("Alert Strip")
        end)
    end
end)
```

### Cycle through all configured devices

```berry
import SLWF03

var devs = SLWF03.devices()
for name : devs
    SLWF03.set_color(name, 0x00FF00)
    SLWF03.on(name)
end
```

## Notes

- SLWF03 is an alias for the WLED module — all functions are identical
- Uses HTTP (not HTTPS) to communicate with devices on the local network
- Each function call makes one HTTP request (~2-4 KB temporary RAM, freed immediately)
- Device name lookup is case-insensitive
- If a name contains a dot (`.`), it's treated as an IP/hostname directly
- Devices must be on the same network as the SLZB device
- `set_state()` gives full access to the WLED JSON API for advanced use cases
