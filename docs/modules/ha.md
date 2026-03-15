# HA Module

Control Home Assistant from Berry scripts — call services, read entity states, and fire events via the Home Assistant REST API.

## Setup

### Option A — Configure via UI (recommended)

1. Go to **Scripts Integrations** page
2. Click the **HOME ASSISTANT** tile
3. Fill in:
   - **Host / IP** — your Home Assistant address (e.g. `192.168.1.100` or `homeassistant.local`)
   - **Port** — usually `8123` (leave empty for default)
   - **Long-Lived Access Token** — see below how to create one
4. Enable and save

### How to create a Long-Lived Access Token

1. Open your Home Assistant web interface
2. Click your profile icon (bottom left)
3. Scroll to **Long-Lived Access Tokens**
4. Click **Create Token**
5. Give it a name (e.g. "SLZB") and click **OK**
6. Copy the token — it will only be shown once

### Option B — Configure in script

```berry
import HA
HA.setup("192.168.1.100", 8123, "eyJhbGciOi...")
```

This overrides the UI config for the current script session only.

## Functions

### HA.setup(host, port, token)

Override Home Assistant credentials for this script session.

| Parameter | Type | Description |
|-----------|------|-------------|
| `host` | string | Home Assistant host or IP |
| `port` | int | HTTP port (usually 8123) |
| `token` | string | Long-Lived Access Token |

```berry
import HA
HA.setup("192.168.1.100", 8123, "eyJhbGciOi...")
```

### HA.call(domain, service, entity_id [, data_json])

Call a Home Assistant service on an entity.

| Parameter | Type | Description |
|-----------|------|-------------|
| `domain` | string | Service domain (e.g. `"light"`, `"switch"`, `"climate"`) |
| `service` | string | Service name (e.g. `"turn_on"`, `"turn_off"`, `"toggle"`) |
| `entity_id` | string | Entity ID (e.g. `"light.living_room"`) |
| `data_json` | string | (optional) Additional service data as JSON string |

**Returns:** `int` — HTTP status code (200 on success)

```berry
import HA

# Simple on/off
HA.call("light", "turn_on", "light.living_room")
HA.call("switch", "turn_off", "switch.fan")
HA.call("light", "toggle", "light.kitchen")

# With additional parameters
HA.call("light", "turn_on", "light.living_room", '{"brightness": 128}')
HA.call("light", "turn_on", "light.led_strip", '{"brightness": 255, "rgb_color": [255, 0, 0]}')
HA.call("climate", "set_temperature", "climate.thermostat", '{"temperature": 22}')
HA.call("media_player", "play_media", "media_player.speaker", '{"media_content_id": "https://example.com/song.mp3", "media_content_type": "music"}')
```

### HA.get_state(entity_id)

Read the current state of an entity.

| Parameter | Type | Description |
|-----------|------|-------------|
| `entity_id` | string | Entity ID (e.g. `"sensor.temperature"`) |

**Returns:** `map` with keys:

| Key | Type | Description |
|-----|------|-------------|
| `entity_id` | string | Entity ID |
| `state` | string | Current state (e.g. `"on"`, `"off"`, `"23.5"`, `"unavailable"`) |
| `last_changed` | string | ISO timestamp of last state change |
| `friendly_name` | string | Friendly name (if set) |
| `unit` | string | Unit of measurement (if applicable, e.g. `"°C"`) |
| `temperature` | int | Temperature attribute (if present, e.g. for climate entities) |
| `current_temperature` | int | Current temperature (if present) |
| `brightness` | int | Brightness (if present, 0–255) |

```berry
import HA

# Read a sensor
var s = HA.get_state("sensor.outdoor_temperature")
print(s["state"])           # "23.5"
print(s["unit"])            # "°C"
print(s["friendly_name"])   # "Outdoor Temperature"

# Check switch state
var sw = HA.get_state("switch.fan")
if sw["state"] == "on"
    print("Fan is running")
end

# Read light brightness
var l = HA.get_state("light.living_room")
print("Brightness: " .. str(l["brightness"]))
```

### HA.fire_event(event_type [, data_json])

Fire a custom event on the Home Assistant event bus.

| Parameter | Type | Description |
|-----------|------|-------------|
| `event_type` | string | Event type name |
| `data_json` | string | (optional) Event data as JSON string |

**Returns:** `int` — HTTP status code (200 on success)

```berry
import HA

# Simple event
HA.fire_event("slzb_button_pressed")

# Event with data
HA.fire_event("slzb_sensor_alert", '{"sensor": "temperature", "value": 35}')
```

You can listen for these events in Home Assistant automations:

```yaml
automation:
  - alias: "SLZB Button Automation"
    trigger:
      platform: event
      event_type: slzb_button_pressed
    action:
      - service: notify.mobile_app
        data:
          message: "SLZB button was pressed!"
```

## Examples

### Toggle light on button press

```berry
import HA
import BUTTON

BUTTON.on_press(def ()
    HA.call("light", "toggle", "light.living_room")
end, 300000)
```

### Set thermostat based on Zigbee sensor

```berry
import HA
import ZB

ZB.on_message(def (msg)
    if msg["cluster"] == 0x0402
        var temp = msg["value"] / 100.0
        if temp > 28
            HA.call("climate", "set_temperature", "climate.thermostat", '{"temperature": 24}')
        elif temp < 18
            HA.call("climate", "set_temperature", "climate.thermostat", '{"temperature": 22}')
        end
    end
end, 5000)
```

### Monitor HA sensor and alert

```berry
import HA
import TELEGRAM
import TIMER

TIMER.setInterval(def()
    var s = HA.get_state("sensor.front_door")
    if s && s["state"] == "on"
        TELEGRAM.send("Front door is open!")
    end
end)
```

### Sync WLED with HA light state

```berry
import HA
import WLED
import TIMER

TIMER.setInterval(def()
    var s = HA.get_state("light.living_room")
    if s
        if s["state"] == "on"
            WLED.on("Status Strip")
        else
            WLED.off("Status Strip")
        end
    end
end)
```

### Fire event on Zigbee motion

```berry
import HA
import ZB

ZB.on_message(def (msg)
    if msg["cluster"] == 0x0406 && msg["value"] == 1
        HA.fire_event("slzb_motion", '{"zone": "living_room"}')
    end
end)
```

## Common Service Domains

| Domain | Common Services |
|--------|----------------|
| `light` | `turn_on`, `turn_off`, `toggle` |
| `switch` | `turn_on`, `turn_off`, `toggle` |
| `fan` | `turn_on`, `turn_off`, `toggle`, `set_percentage` |
| `climate` | `set_temperature`, `set_hvac_mode`, `turn_on`, `turn_off` |
| `cover` | `open_cover`, `close_cover`, `stop_cover`, `set_cover_position` |
| `media_player` | `play_media`, `media_pause`, `media_play`, `volume_set` |
| `script` | `turn_on` (to run a script) |
| `scene` | `turn_on` (to activate a scene) |
| `automation` | `trigger`, `turn_on`, `turn_off` |
| `notify` | `notify` |

## Notes

- Uses the Home Assistant REST API over HTTP (not WebSocket)
- Default port is 8123 — configurable via UI or `setup()`
- Each function call makes one HTTP request (~2-4 KB temporary RAM, freed immediately)
- The SLZB device must be on the same network as Home Assistant (or have network access to it)
- Long-Lived Access Tokens do not expire
- `get_state()` returns common attributes as flat keys for convenience; for full attribute access, use the raw HA REST API via the HTTP module
- Service data (`data_json`) must be a valid JSON string — use single quotes in Berry to wrap JSON: `'{"key": "value"}'`
