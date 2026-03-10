# WLED Module

Control WLED-powered LED strips from Berry scripts. Works with any WLED device on the local network, including SMLIGHT SLWF-03 and SLWF-09 controllers.

## Setup

### Option A — Configure via UI (recommended)

1. Go to **Scripts Integrations** page
2. Click the **WLED** tile (or **SLWF-03** / **SLWF-09**)
3. Add your devices with a name and IP address
4. Enable and save

### Option B — Use IP directly in script

No configuration needed — just pass the device IP to any function:

```berry
import WLED

WLED.on("192.168.1.50")
```

## Functions

### WLED.on(device)

Turn the device on.

| Parameter | Type | Description |
|-----------|------|-------------|
| `device` | string | Device name (from UI config) or IP address |

**Returns:** `int` — HTTP status code (200 on success)

```berry
import WLED

WLED.on("Kitchen Strip")
WLED.on("192.168.1.50")
```

### WLED.off(device)

Turn the device off.

```berry
import WLED

WLED.off("Kitchen Strip")
```

### WLED.toggle(device)

Toggle the device on/off.

```berry
import WLED

WLED.toggle("Kitchen Strip")
```

### WLED.set_brightness(device, brightness)

Set brightness level.

| Parameter | Type | Description |
|-----------|------|-------------|
| `device` | string | Device name or IP |
| `brightness` | int | Brightness level (0–255) |

```berry
import WLED

WLED.set_brightness("Kitchen Strip", 128)
```

### WLED.set_color(device, color)

Set the color of the first segment.

| Parameter | Type | Description |
|-----------|------|-------------|
| `device` | string | Device name or IP |
| `color` | int | RGB color as hex (e.g. `0xFF0000` for red) |

```berry
import WLED

WLED.set_color("Kitchen Strip", 0xFF0000)   # red
WLED.set_color("Kitchen Strip", 0x00FF00)   # green
WLED.set_color("Kitchen Strip", 0x0000FF)   # blue
WLED.set_color("Kitchen Strip", 0xFFFFFF)   # white
```

### WLED.set_effect(device, effect_id)

Set the LED effect by ID.

| Parameter | Type | Description |
|-----------|------|-------------|
| `device` | string | Device name or IP |
| `effect_id` | int | WLED effect ID (0 = Solid, 1 = Blink, etc.) |

```berry
import WLED

WLED.set_effect("Kitchen Strip", 0)    # Solid
WLED.set_effect("Kitchen Strip", 38)   # Rainbow
WLED.set_effect("Kitchen Strip", 9)    # Chase
```

See the full list of effects in your WLED web interface or at [WLED Effects List](https://kno.wทled.ge/features/effects/).

### WLED.set_palette(device, palette_id)

Set the color palette for the current effect.

| Parameter | Type | Description |
|-----------|------|-------------|
| `device` | string | Device name or IP |
| `palette_id` | int | WLED palette ID |

```berry
import WLED

WLED.set_palette("Kitchen Strip", 6)   # Party palette
```

### WLED.set_speed(device, speed)

Set the effect speed.

| Parameter | Type | Description |
|-----------|------|-------------|
| `device` | string | Device name or IP |
| `speed` | int | Speed (0–255) |

```berry
import WLED

WLED.set_speed("Kitchen Strip", 200)
```

### WLED.set_state(device, json_string)

Send a raw JSON state to the WLED API for full control. See [WLED JSON API](https://kno.wled.ge/interfaces/json-api/) for all available fields.

| Parameter | Type | Description |
|-----------|------|-------------|
| `device` | string | Device name or IP |
| `json_string` | string | Raw JSON string for `/json/state` |

```berry
import WLED

# Turn on with brightness 200 and red color in one request
WLED.set_state("Kitchen Strip", '{"on":true,"bri":200,"seg":[{"col":[[255,0,0]]}]}')
```

### WLED.get_state(device)

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
import WLED

var state = WLED.get_state("Kitchen Strip")
print(state["on"])     # 1 or 0
print(state["bri"])    # 0-255
print(state["color"])  # e.g. 16711680 (0xFF0000)
```

### WLED.devices()

List all configured WLED device names (from UI config).

**Returns:** `list` of strings

```berry
import WLED

var devs = WLED.devices()
for name : devs
    print(name)
end
```

## Examples

### Night light on button press

```berry
import WLED
import BUTTON

BUTTON.on_press(def ()
    WLED.set_color("Bedroom Strip", 0xFF8C00)
    WLED.set_brightness("Bedroom Strip", 30)
    WLED.on("Bedroom Strip")
end)
```

### Flash red on Zigbee alert

```berry
import WLED
import ZB
import TIMER

ZB.on_message(def (msg)
    if msg["cluster"] == 0x0500
        WLED.set_color("Alert Strip", 0xFF0000)
        WLED.set_effect("Alert Strip", 1)
        WLED.on("Alert Strip")
        TIMER.once(10000, def ()
            WLED.off("Alert Strip")
        end)
    end
end)
```

### Cycle through all configured devices

```berry
import WLED

var devs = WLED.devices()
for name : devs
    WLED.set_color(name, 0x00FF00)
    WLED.on(name)
end
```

### Read and log device state

```berry
import WLED
import SLZB

var state = WLED.get_state("Kitchen Strip")
if state
    SLZB.log("On: " .. str(state["on"]) .. " Brightness: " .. str(state["bri"]))
end
```

## Notes

- Uses HTTP (not HTTPS) to communicate with WLED devices on the local network
- Each function call makes one HTTP request (~2-4 KB temporary RAM, freed immediately)
- Device name lookup is case-insensitive
- If a name contains a dot (`.`), it's treated as an IP/hostname directly
- SLWF-03 and SLWF-09 devices configured in the UI are automatically found by name
- WLED devices must be on the same network as the SLZB device
- `set_state()` gives full access to the WLED JSON API for advanced use cases (multiple segments, presets, etc.)
