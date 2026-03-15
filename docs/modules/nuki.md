# NUKI Module

Control [Nuki](https://nuki.io/) smart locks — lock, unlock, check state, and more from Zigbee events, buttons, and schedules.

> **API notice:** This module uses the publicly documented [Nuki Bridge HTTP API](https://developer.nuki.io/page/nuki-bridge-http-api). A **Nuki Bridge** device is required — it acts as the HTTP gateway to your Nuki smart locks on your local network. SMLIGHT is not affiliated with Nuki Home Solutions GmbH.

## Setup

### Prerequisites

1. A **Nuki Smart Lock** paired with a **Nuki Bridge**
2. Enable the Bridge HTTP API:
   - Open the **Nuki App** → **Manage Bridge** → **Enable HTTP API**
   - Note the **Bridge IP** and **API token** displayed

### Option A — Configure via UI (recommended)

1. Go to **Scripts Integrations** page
2. Click the **NUKI SMART LOCK** tile
3. Enter:
   - **Bridge IP** — your Nuki Bridge IP address
   - **Bridge Port** — default `8080`
   - **Bridge API Token** — from Nuki app
   - **Default Nuki ID** — (optional) your lock's ID so you don't have to pass it every call
4. Enable and save

### Option B — Use directly in script

```berry
import NUKI

# With default lock ID
NUKI.setup("192.168.1.60", "my_bridge_token", 8080, 123456789)

# Without default ID (pass it per call)
NUKI.setup("192.168.1.60", "my_bridge_token")
```

### Finding your Nuki ID

```berry
import NUKI
var devs = NUKI.list()
for id : devs.keys()
    print("ID: " .. id .. " — " .. devs[id])
end
```

## Functions

### NUKI.setup(host, token [, port [, nuki_id]])

Configure connection from script. Overrides UI settings.

| Parameter | Type | Description |
|-----------|------|-------------|
| `host` | string | Nuki Bridge IP address |
| `token` | string | Bridge API token |
| `port` | int | (optional) Bridge port, default `8080` |
| `nuki_id` | int | (optional) Default lock ID for all calls |

### NUKI.lock([nuki_id])

Lock the door.

| Parameter | Type | Description |
|-----------|------|-------------|
| `nuki_id` | int | (optional if default configured) Lock ID |

**Returns:** `bool` — `true` if successful

### NUKI.unlock([nuki_id])

Unlock the door.

**Returns:** `bool`

### NUKI.unlatch([nuki_id])

Unlatch the door (fully open — for electric strikes / door openers).

**Returns:** `bool`

### NUKI.lock_n_go([nuki_id])

Unlock, wait a few seconds, then lock again automatically. Useful for letting someone in without leaving the door unlocked.

**Returns:** `bool`

### NUKI.state([nuki_id])

Get the current lock state.

**Returns:** `map` with keys:

| Key | Type | Description |
|-----|------|-------------|
| `success` | bool | `true` if the request succeeded |
| `state` | int | Lock state code (see table below) |
| `state_name` | string | Human-readable state name |
| `battery_critical` | bool | `true` if battery is low |

**Lock states:**

| Code | Name | Description |
|------|------|-------------|
| 1 | `locked` | Door is locked |
| 2 | `unlocking` | Lock is currently unlocking |
| 3 | `unlocked` | Door is unlocked |
| 4 | `locking` | Lock is currently locking |
| 5 | `unlatched` | Door opener activated |
| 6 | `unlocked_go` | Unlocked via Lock 'n' Go |
| 7 | `unlatching` | Door opener activating |
| 254 | `motor_blocked` | Motor is blocked (jammed) |
| 255 | `undefined` | State unknown |

```berry
import NUKI
var s = NUKI.state()
print("Lock is: " .. s["state_name"])
if s["battery_critical"]
    print("WARNING: Battery low!")
end
```

### NUKI.list()

List all smart locks paired with the Bridge.

**Returns:** `map` — keys are Nuki IDs (as strings), values are device names

### NUKI.unpair(nuki_id)

Remove a lock from the Bridge pairing.

| Parameter | Type | Description |
|-----------|------|-------------|
| `nuki_id` | int | Lock ID to unpair |

**Returns:** `bool`

## Examples

### Zigbee button locks/unlocks door

```berry
import NUKI
import ZHB

ZHB.waitForStart(0xff)
ZHB.on_action(def (action, dev)
    if dev.getName() == "Door Button"
        if action == "single"
            NUKI.unlock()
        elif action == "double"
            NUKI.lock()
        elif action == "long"
            NUKI.lock_n_go()
        end
    end
end, 60000)
```

### Auto-lock at night

```berry
import NUKI
import TIME
import TIMER

TIMER.setInterval(def()
    var t = TIME.getAll()
    if t["hour"] == 23 && t["min"] == 0
        var s = NUKI.state()
        if s["state_name"] == "unlocked"
            NUKI.lock()
            import TELEGRAM
            TELEGRAM.send("Front door auto-locked for the night")
        end
    end
end, 60000)
```

### Lock when everyone leaves (presence detection)

```berry
import NUKI
import OPENWRT
import TIMER

# MAC addresses of family phones
var phones = ["AA:BB:CC:DD:EE:01", "AA:BB:CC:DD:EE:02"]

TIMER.setInterval(def()
    var anyone_home = false
    for mac : phones
        if OPENWRT.is_connected(mac)
            anyone_home = true
            break
        end
    end

    if !anyone_home
        var s = NUKI.state()
        if s["state_name"] == "unlocked"
            NUKI.lock()
            import TELEGRAM
            TELEGRAM.send("Nobody home — front door locked automatically")
        end
    end
end, 3600000)
```

### Battery monitoring

```berry
import NUKI
import TELEGRAM
import TIMER

TIMER.setInterval(def()
    var s = NUKI.state()
    if s["battery_critical"]
        TELEGRAM.send("Nuki lock battery is critically low! Replace soon.")
    end
end)
```

### Doorbell with unlock

```berry
import NUKI
import BUZZER
import ZHB

ZHB.waitForStart(0xff)
ZHB.on_action(def (action, dev)
    if dev.getName() == "Doorbell Button" && action == "single"
        BUZZER.play("DoorBell:d=4,o=5,b=140:8e6,8d6")
        NUKI.lock_n_go()
    end
end)
```

### Motion sensor unlocks for you

```berry
import NUKI
import ZHB

ZHB.waitForStart(0xff)
ZHB.on_action(def (action, dev)
    if dev.getName() == "Front Door Motion" && action == "occupancy"
        NUKI.unlock()
    end
end)
```

## Getting the Bridge API Token

1. Open the **Nuki App** on your phone
2. Go to **Smart Lock** → **Manage Bridge**
3. Enable **HTTP API**
4. The app shows the **Bridge IP** and **Token**
5. Alternatively, discover bridges on your network:
   - `GET https://api.nuki.io/discover/bridges` returns local bridge IPs

## Notes

- Uses the [Nuki Bridge HTTP API](https://developer.nuki.io/page/nuki-bridge-http-api) — publicly documented, designed for third-party integrations
- A **Nuki Bridge** device is required — the smart lock itself has no HTTP API (it uses Bluetooth)
- All communication is local — no cloud, no internet required
- The Bridge API token provides full lock control — **keep it secure**
- Lock/unlock commands may take 1–3 seconds to complete (Bluetooth communication between Bridge and lock)
- SMLIGHT is not affiliated with Nuki Home Solutions GmbH
