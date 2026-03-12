# TASMOTA Module

Control [Tasmota](https://tasmota.github.io/docs/)-flashed WiFi devices — smart plugs, lights, switches, dimmers, and more — directly from your SLZB device. Bridge the gap between your Zigbee and WiFi smart home devices.

> **API notice:** Uses the publicly documented [Tasmota HTTP API](https://tasmota.github.io/docs/Commands/). SMLIGHT is not affiliated with the Tasmota project.

## Setup

### Option A — Configure via UI (recommended)

1. Go to **Scripts Integrations** page
2. Click the **TASMOTA** tile
3. Add devices with:
   - **Name** — friendly name (e.g. "Kitchen Plug", "Desk Lamp")
   - **Host / IP** — device IP address
4. Enable and save

### Option B — Use directly in script

```berry
import TASMOTA

# Register devices by name
TASMOTA.setup("Kitchen Plug", "192.168.1.50")
TASMOTA.setup("Desk Lamp", "192.168.1.51")

# Or use IP addresses directly (no setup needed)
TASMOTA.on("192.168.1.50")
```

## Functions

### TASMOTA.setup(name, host)

Register a device by friendly name.

| Parameter | Type | Description |
|-----------|------|-------------|
| `name` | string | Friendly name |
| `host` | string | IP address or hostname |

### TASMOTA.on(name_or_host)

Turn on the device.

| Parameter | Type | Description |
|-----------|------|-------------|
| `name_or_host` | string | Device name or IP address |

**Returns:** `bool`

### TASMOTA.off(name_or_host)

Turn off the device.

**Returns:** `bool`

### TASMOTA.toggle(name_or_host)

Toggle the device.

**Returns:** `bool`

### TASMOTA.dimmer(name_or_host, level)

Set dimmer level.

| Parameter | Type | Description |
|-----------|------|-------------|
| `name_or_host` | string | Device name or IP |
| `level` | int | Brightness 0–100 |

**Returns:** `bool`

### TASMOTA.color(name_or_host, hex_color)

Set light color.

| Parameter | Type | Description |
|-----------|------|-------------|
| `name_or_host` | string | Device name or IP |
| `hex_color` | string | Hex color (e.g. `"FF0000"` for red) |

**Returns:** `bool`

### TASMOTA.ct(name_or_host, value)

Set color temperature.

| Parameter | Type | Description |
|-----------|------|-------------|
| `name_or_host` | string | Device name or IP |
| `value` | int | Color temperature in mireds (153–500) |

**Returns:** `bool`

### TASMOTA.status(name_or_host)

Get device status.

**Returns:** `map` with keys:

| Key | Type | Description |
|-----|------|-------------|
| `power` | string | `"ON"` or `"OFF"` |
| `dimmer` | int | Current dimmer level |
| `ct` | int | Current color temperature |
| `color` | string | Current color hex |
| `rssi` | int | WiFi signal strength |
| `ip` | string | IP address |
| `mac` | string | MAC address |
| `version` | string | Tasmota firmware version |

```berry
import TASMOTA
var s = TASMOTA.status("Kitchen Plug")
print("Power: " .. s["power"])
print("WiFi: " .. str(s["rssi"]) .. "%")
```

### TASMOTA.cmd(name_or_host, command)

Send any Tasmota command. Full command list at [tasmota.github.io/docs/Commands](https://tasmota.github.io/docs/Commands/).

| Parameter | Type | Description |
|-----------|------|-------------|
| `name_or_host` | string | Device name or IP |
| `command` | string | Any Tasmota command (e.g. `"Restart 1"`, `"Backlog Power ON; Dimmer 50"`) |

**Returns:** `map` with `ok` (bool) and `response` (string)

```berry
import TASMOTA

# Restart device
TASMOTA.cmd("Kitchen Plug", "Restart 1")

# Multiple commands at once
TASMOTA.cmd("Desk Lamp", "Backlog Power ON; Dimmer 75; CT 300")

# Read sensor value
var r = TASMOTA.cmd("Temp Sensor", "Status 10")
print(r["response"])
```

### TASMOTA.devices()

List all configured devices.

**Returns:** `map` — keys are names, values are host addresses

## Examples

### Zigbee button toggles WiFi plug

```berry
import TASMOTA
import ZHB

ZHB.waitForStart(0xff)
ZHB.on_action(def (action, dev)
    if dev.getName() == "Wall Switch" && action == "single"
        TASMOTA.toggle("Kitchen Plug")
    end
end)
```

### Zigbee sensor controls WiFi light color

```berry
import TASMOTA
import ZHB
import TIMER

ZHB.waitForStart(0xff)
var sensor = ZHB.getDevice("Temp Sensor")

TIMER.every(60000, def ()
    var temp = sensor.getTemperature()
    if temp > 28
        TASMOTA.color("Status Light", "FF0000")
    elif temp > 24
        TASMOTA.color("Status Light", "FFAA00")
    else
        TASMOTA.color("Status Light", "00FF00")
    end
end)
```

### Motion sensor turns on WiFi lights

```berry
import TASMOTA
import ZHB

ZHB.waitForStart(0xff)
ZHB.on_action(def (action, dev)
    if dev.getName() == "Hallway Motion" && action == "occupancy"
        TASMOTA.on("Hallway Light")
        TASMOTA.dimmer("Hallway Light", 80)
    end
end)
```

### Power monitoring with alerts

```berry
import TASMOTA
import TELEGRAM
import TIMER

TIMER.every(60000, def ()
    var r = TASMOTA.cmd("Washing Machine", "Status 8")
    if r["ok"]
        import json
        var data = json.load(r["response"])
        if data
            var power = data["StatusSNS"]["ENERGY"]["Power"]
            if power < 5
                TELEGRAM.send("Washing machine finished!")
            end
        end
    end
end)
```

### All-off on leaving home

```berry
import TASMOTA
import OPENWRT
import TIMER

var phone_mac = "AA:BB:CC:DD:EE:FF"

TIMER.every(60000, def ()
    if !OPENWRT.is_connected(phone_mac)
        var devs = TASMOTA.devices()
        for name : devs.keys()
            TASMOTA.off(name)
        end
    end
end)
```

### Sync Zigbee and Tasmota devices

When a Zigbee relay turns on, also turn on a Tasmota light.

```berry
import TASMOTA
import ZHB

ZHB.waitForStart(0xff)
ZHB.on_action(def (action, dev)
    if dev.getName() == "Living Room Relay"
        if action == "on"
            TASMOTA.on("Living Room Lamp")
            TASMOTA.dimmer("Living Room Lamp", 70)
        elif action == "off"
            TASMOTA.off("Living Room Lamp")
        end
    end
end)
```

## Notes

- Uses the [Tasmota HTTP API](https://tasmota.github.io/docs/Commands/) — `GET /cm?cmnd=COMMAND`
- Works with any Tasmota-flashed device (Sonoff, Tuya, generic ESP8266/ESP32)
- All communication is local — no cloud, no internet required
- Devices can be referenced by name (configured in UI/script) or by IP address directly
- If the device has HTTP authentication enabled, it's not currently supported — disable web password or use without auth
- The `cmd()` function gives access to all 600+ Tasmota commands
- The SLZB device must be on the same network as the Tasmota devices
- SMLIGHT is not affiliated with the Tasmota project
