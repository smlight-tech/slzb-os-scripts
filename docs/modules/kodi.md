# KODI Module

Control [Kodi](https://kodi.tv/) media center from your SLZB device. Play/pause, adjust volume, show on-screen notifications, and navigate — all via Kodi's JSON-RPC API over your local network.

## Setup

### Option A — Configure via UI (recommended)

1. Go to **Scripts Integrations** page
2. Click the **KODI** tile
3. Enter:
   - **Host / IP** — your Kodi device IP (e.g. `192.168.1.50`)
   - **HTTP Port** — default `8080`
   - **Username / Password** — only if you enabled authentication in Kodi
4. Enable and save

### Option B — Use directly in script

```berry
import KODI

# Without authentication
KODI.setup("192.168.1.50")

# With authentication
KODI.setup("192.168.1.50", 8080, "kodi", "mypassword")
```

## Functions

### KODI.setup(host [, port [, user [, pass]]])

Configure Kodi connection from script. Overrides UI settings.

| Parameter | Type | Description |
|-----------|------|-------------|
| `host` | string | Kodi IP address or hostname |
| `port` | int | (optional) HTTP port, default `8080` |
| `user` | string | (optional) Username for HTTP basic auth |
| `pass` | string | (optional) Password for HTTP basic auth |

### KODI.notify(title, message [, duration_ms])

Show an on-screen notification on the TV.

| Parameter | Type | Description |
|-----------|------|-------------|
| `title` | string | Notification title |
| `message` | string | Notification text |
| `duration_ms` | int | (optional) Display time in ms, default `5000` |

**Returns:** `bool` — `true` if sent successfully

```berry
import KODI
KODI.notify("SLZB Alert", "Motion detected in hallway!")
KODI.notify("Temperature", "Living room: 28°C", 10000)
```

### KODI.play_pause([playerid])

Toggle play/pause. Auto-detects active player if no ID given.

| Parameter | Type | Description |
|-----------|------|-------------|
| `playerid` | int | (optional) Player ID: `0`=music, `1`=video, `2`=pictures |

**Returns:** `bool`

### KODI.stop([playerid])

Stop playback. Auto-detects active player if no ID given.

| Parameter | Type | Description |
|-----------|------|-------------|
| `playerid` | int | (optional) Player ID |

**Returns:** `bool`

### KODI.volume(level)

Set volume level.

| Parameter | Type | Description |
|-----------|------|-------------|
| `level` | int | Volume 0–100 |

**Returns:** `bool`

### KODI.mute([on])

Mute, unmute, or toggle mute.

| Parameter | Type | Description |
|-----------|------|-------------|
| `on` | bool | (optional) `true`=mute, `false`=unmute. Omit to toggle |

**Returns:** `bool`

### KODI.get_playing()

Get information about the currently playing item.

**Returns:** `map` with keys:

| Key | Type | Description |
|-----|------|-------------|
| `playing` | bool | `true` if something is playing |
| `playerid` | int | Active player ID |
| `title` | string | Title of the item |
| `type` | string | Media type (`movie`, `episode`, `song`, etc.) |
| `artist` | string | Artist name (music) |
| `album` | string | Album name (music) |
| `show` | string | TV show title (episodes) |
| `season` | int | Season number (episodes) |
| `episode` | int | Episode number (episodes) |

```berry
import KODI
var p = KODI.get_playing()
if p["playing"]
    print("Now playing: " .. p["title"])
    if p["type"] == "episode"
        print("Show: " .. p["show"] .. " S" .. str(p["season"]) .. "E" .. str(p["episode"]))
    end
end
```

### KODI.input(action)

Send navigation and input actions to Kodi.

| Parameter | Type | Description |
|-----------|------|-------------|
| `action` | string | Action name (see list below) |

**Returns:** `bool`

Built-in actions: `up`, `down`, `left`, `right`, `select`, `back`, `home`, `info`, `osd`

Any other string is sent via `Input.ExecuteAction` (e.g. `"fullscreen"`, `"codecinfo"`, `"nextsubtitle"`).

```berry
import KODI
KODI.input("home")
KODI.input("select")
KODI.input("fullscreen")
```

### KODI.send(method [, params_json])

Send a raw JSON-RPC call for any Kodi API method.

| Parameter | Type | Description |
|-----------|------|-------------|
| `method` | string | JSON-RPC method (e.g. `"Addons.GetAddons"`) |
| `params_json` | string | (optional) JSON string with parameters |

**Returns:** `map` with `ok` (bool) and `response` (string)

```berry
import KODI
var r = KODI.send("Application.GetProperties", '{"properties":["volume","muted","version"]}')
print(r["response"])
```

## Examples

### Zigbee button controls playback

```berry
import KODI
import ZHB

ZHB.waitForStart(0xff)
ZHB.on_action(def (action, dev)
    if dev.getName() == "Remote Button"
        if action == "single"
            KODI.play_pause()
        elif action == "double"
            KODI.stop()
        elif action == "long"
            KODI.mute()
        end
    end
end)
```

### Show sensor alerts on TV

```berry
import KODI
import ZHB

ZHB.waitForStart(0xff)
ZHB.on_action(def (action, dev)
    if dev.getName() == "Door Sensor" && action == "contact"
        KODI.notify("Door Alert", "Front door opened!", 8000)
    end
end)
```

### Movie mode — dim lights when playing

```berry
import KODI
import HUE
import TIMER

var was_playing = false

TIMER.every(10000, def ()
    var p = KODI.get_playing()
    if p["playing"] && !was_playing
        HUE.set_brightness(1, 20)
        was_playing = true
    elif !p["playing"] && was_playing
        HUE.set_brightness(1, 200)
        was_playing = false
    end
end)
```

### Volume control with rotary encoder

```berry
import KODI
import ZHB

ZHB.waitForStart(0xff)
ZHB.on_action(def (action, dev)
    if dev.getName() == "Volume Knob"
        if action == "step_with_on_off_step_mode0"
            KODI.send("Application.SetVolume", '{"volume":"increment"}')
        elif action == "step_with_on_off_step_mode1"
            KODI.send("Application.SetVolume", '{"volume":"decrement"}')
        end
    end
end)
```

## Enabling Kodi HTTP Control

1. Open Kodi → **Settings** → **Services** → **Control**
2. Enable **Allow remote control via HTTP**
3. Set **Port** (default `8080`)
4. (Optional) Set **Username** and **Password**
5. (Optional) Enable **Allow remote control from applications on other systems**

## Notes

- Uses Kodi JSON-RPC API v12+ over HTTP — compatible with Kodi 17 (Krypton) and later
- Fully local — no cloud or internet required
- `play_pause()` and `stop()` auto-detect the active player (video, music, or pictures)
- `input()` supports all Kodi [built-in actions](https://kodi.wiki/view/Action_IDs)
- `send()` gives full access to any [JSON-RPC method](https://kodi.wiki/view/JSON-RPC_API/v12)
- HTTP basic auth is used when username/password are provided
- The SLZB device must be on the same network as Kodi
