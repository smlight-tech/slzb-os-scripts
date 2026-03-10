# HUE Module

Control Philips Hue lights via the Hue Bridge **v1 API** over your local network.

> **Note:** This module uses the Hue Bridge v1 REST API (HTTP, not HTTPS). The Bridge must be on the same local network as the SLZB device.

## Setup

### Option A — Configure via UI (recommended)

1. Go to **Scripts Integrations** page
2. Click the **PHILIPS HUE** tile
3. Fill in:
   - **Bridge IP** — your Hue Bridge IP address (e.g. `192.168.1.50`)
   - **API Key** — a username/API key for the Bridge (see below)
4. Enable and save

### How to create an API Key

1. Find your Hue Bridge IP (check your router or the Hue app)
2. Open a browser and go to: `http://<bridge-ip>/debug/clip.html`
3. **Press the physical button** on your Hue Bridge
4. Within 30 seconds, send a POST request:
   - URL: `/api`
   - Body: `{"devicetype":"slzb#device"}`
5. The response contains your API key (username) — copy and save it

Alternatively, use curl:
```bash
# Press the bridge button first, then run:
curl -X POST http://<bridge-ip>/api -d '{"devicetype":"slzb#device"}'
```

### Option B — Configure in script

```berry
import HUE
HUE.setup("192.168.1.50", "your-api-key-here")
```

This overrides the UI config for the current script session only.

## Functions

### HUE.setup(host, api_key)

Override Hue Bridge credentials for this script session.

| Parameter | Type | Description |
|-----------|------|-------------|
| `host` | string | Hue Bridge IP address |
| `api_key` | string | API key (username) |

### HUE.on(light_id)

Turn on a light.

| Parameter | Type | Description |
|-----------|------|-------------|
| `light_id` | int | Light ID number (1, 2, 3, ...) |

**Returns:** `int` — HTTP status code (200 on success)

### HUE.off(light_id)

Turn off a light.

### HUE.toggle(light_id)

Toggle a light on/off. Reads the current state first, then switches.

### HUE.set_brightness(light_id, bri)

Set light brightness (also turns it on).

| Parameter | Type | Description |
|-----------|------|-------------|
| `light_id` | int | Light ID |
| `bri` | int | Brightness, 0–254 |

### HUE.set_color(light_id, hue, sat)

Set light color using hue and saturation (also turns it on).

| Parameter | Type | Description |
|-----------|------|-------------|
| `light_id` | int | Light ID |
| `hue` | int | Hue value, 0–65535 (0=red, 21845=green, 43690=blue) |
| `sat` | int | Saturation, 0–254 (0=white, 254=full color) |

### HUE.set_ct(light_id, ct)

Set color temperature in mireds (also turns it on).

| Parameter | Type | Description |
|-----------|------|-------------|
| `light_id` | int | Light ID |
| `ct` | int | Color temperature in mireds, 153–500 (153=cold/6500K, 500=warm/2000K) |

### HUE.set_xy(light_id, x, y)

Set color using CIE xy color space (also turns it on).

| Parameter | Type | Description |
|-----------|------|-------------|
| `light_id` | int | Light ID |
| `x` | real | CIE x coordinate, 0.0–1.0 |
| `y` | real | CIE y coordinate, 0.0–1.0 |

### HUE.alert(light_id, mode)

Trigger a light alert effect.

| Parameter | Type | Description |
|-----------|------|-------------|
| `light_id` | int | Light ID |
| `mode` | string | `"none"` — stop, `"select"` — one flash, `"lselect"` — 15 seconds of flashing |

### HUE.get_state(light_id)

Read the current state of a light.

| Parameter | Type | Description |
|-----------|------|-------------|
| `light_id` | int | Light ID |

**Returns:** `map` with keys:

| Key | Type | Description |
|-----|------|-------------|
| `name` | string | Light name |
| `type` | string | Light type (e.g. `"Extended color light"`) |
| `modelid` | string | Model ID (e.g. `"LCT016"`) |
| `on` | bool | Whether the light is on |
| `bri` | int | Brightness (0–254) |
| `hue` | int | Hue (0–65535) |
| `sat` | int | Saturation (0–254) |
| `ct` | int | Color temperature in mireds |
| `reachable` | bool | Whether the light is reachable |
| `colormode` | string | Current color mode (`"hs"`, `"ct"`, `"xy"`) |

### HUE.lights()

List all lights on the bridge.

**Returns:** `map` — keys are light IDs (as strings), values are light names.

```berry
import HUE

var all = HUE.lights()
for id : all.keys()
    print("Light " .. id .. ": " .. all[id])
end
```

## Finding Light IDs

Light IDs are assigned by the Hue Bridge (1, 2, 3, ...). Use `HUE.lights()` to discover them:

```berry
import HUE
var all = HUE.lights()
# Output example:
# Light 1: Living Room
# Light 2: Kitchen
# Light 3: Bedroom
```

## Examples

### Toggle light on button press

```berry
import HUE
import BUTTON

BUTTON.on_press(def ()
    HUE.toggle(1)
end)
```

### Set warm white at sunset

```berry
import HUE
import SUN
import TIMER

TIMER.every(60000, def ()
    var s = SUN.get()
    # Set warm color temperature at sunset
    HUE.set_ct(1, 400)
    HUE.set_brightness(1, 180)
end)
```

### Flash light on Zigbee sensor alert

```berry
import HUE
import ZB

ZB.on_message(def (msg)
    if msg["cluster"] == 0x0406 && msg["value"] == 1
        HUE.alert(1, "lselect")
    end
end)
```

### Sync brightness from Zigbee dimmer

```berry
import HUE
import ZB

ZB.on_message(def (msg)
    if msg["cluster"] == 0x0008
        # Scale Zigbee brightness (0-254) to Hue brightness (0-254)
        HUE.set_brightness(1, msg["value"])
    end
end)
```

### Color cycle

```berry
import HUE
import TIMER

var hueVal = 0
TIMER.every(3000, def ()
    HUE.set_color(1, hueVal, 254)
    hueVal = (hueVal + 5000) % 65536
end)
```

## Color Reference

### Hue values (with full saturation)

| Hue | Color |
|-----|-------|
| 0 | Red |
| 10920 | Yellow |
| 21845 | Green |
| 32768 | Cyan |
| 43690 | Blue |
| 54612 | Magenta |

### Color temperature (mireds)

| Mireds | Approximate Color |
|--------|-------------------|
| 153 | Cool daylight (6500K) |
| 233 | Neutral white (4300K) |
| 300 | Warm white (3300K) |
| 400 | Soft warm (2500K) |
| 500 | Candlelight (2000K) |

## Notes

- Uses the Hue Bridge **v1 REST API** over plain HTTP (not HTTPS)
- The SLZB device must be on the same local network as the Hue Bridge
- Light IDs are integers assigned by the Bridge — use `lights()` to discover them
- Each function call makes one HTTP request (~1-2 KB temporary RAM, freed immediately)
- The `toggle()` function makes two HTTP requests (GET + PUT)
- API keys do not expire unless manually deleted from the Bridge
- The v1 API is still supported on current Hue Bridge firmware
- For color lights, `set_color()` uses HSV, `set_ct()` uses mireds, and `set_xy()` uses CIE color space
