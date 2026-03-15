# PUSHOVER Module

Send push notifications via [Pushover](https://pushover.net/) with support for priority levels, sounds, HTML formatting, and supplementary URLs.

## Setup

### Option A — Configure via UI (recommended)

1. Go to **Scripts Integrations** page
2. Click the **PUSHOVER** tile
3. Fill in:
   - **Application Token** — create an app at [pushover.net/apps](https://pushover.net/apps/build)
   - **User Key** — found on your Pushover dashboard
4. Enable and save

### How to get credentials

1. Create a Pushover account at [pushover.net](https://pushover.net/)
2. Install the Pushover app on your phone (iOS/Android) — one-time purchase
3. Your **User Key** is shown on the main dashboard page
4. Create an application at [pushover.net/apps/build](https://pushover.net/apps/build) to get your **Application Token**

### Option B — Configure in script

```berry
import PUSHOVER
PUSHOVER.setup("your-app-token", "your-user-key")
```

## Functions

### PUSHOVER.setup(app_token, user_key)

Override credentials for this script session.

| Parameter | Type | Description |
|-----------|------|-------------|
| `app_token` | string | Application API token |
| `user_key` | string | User/group key |

### PUSHOVER.send(message [, title [, priority [, sound]]])

Send a push notification.

| Parameter | Type | Description |
|-----------|------|-------------|
| `message` | string | Message body (supports HTML: `<b>`, `<i>`, `<u>`, `<a href="">`) |
| `title` | string | (optional) Notification title |
| `priority` | int | (optional) Priority level (see table below) |
| `sound` | string | (optional) Notification sound name |

**Returns:** `int` — HTTP status code (200 on success)

### Priority Levels

| Value | Name | Description |
|-------|------|-------------|
| `-2` | Lowest | No notification, no sound, no badge |
| `-1` | Low | No sound, no vibration |
| `0` | Normal | Default (sound + vibration) |
| `1` | High | Bypasses quiet hours |
| `2` | Emergency | Repeats every 60s for 5 min until acknowledged |

```berry
import PUSHOVER

# Normal notification
PUSHOVER.send("Sensor triggered!")

# High priority with siren sound
PUSHOVER.send("FIRE ALARM!", "Emergency", 1, "siren")

# Silent notification
PUSHOVER.send("Daily report ready", "SLZB", -1)

# Emergency — repeats until acknowledged
PUSHOVER.send("Water leak detected!", "CRITICAL", 2, "alien")
```

### PUSHOVER.send_url(message, title, url, url_title)

Send a notification with a supplementary URL.

| Parameter | Type | Description |
|-----------|------|-------------|
| `message` | string | Message body |
| `title` | string | Notification title |
| `url` | string | Supplementary URL |
| `url_title` | string | Label for the URL |

**Returns:** `int` — HTTP status code (200 on success)

```berry
import PUSHOVER
PUSHOVER.send_url("Temperature is 35 C", "Heat Alert", "https://my-grafana.local/dashboard", "Open Grafana")
```

### Available Sounds

| Sound | Description |
|-------|-------------|
| `pushover` | Default |
| `bike` | Bike |
| `bugle` | Bugle |
| `cashregister` | Cash register |
| `classical` | Classical |
| `cosmic` | Cosmic |
| `falling` | Falling |
| `gamelan` | Gamelan |
| `incoming` | Incoming |
| `intermission` | Intermission |
| `magic` | Magic |
| `mechanical` | Mechanical |
| `pianobar` | Piano bar |
| `siren` | Siren |
| `spacealarm` | Space alarm |
| `tugboat` | Tug boat |
| `alien` | Alien (long) |
| `climb` | Climb (long) |
| `persistent` | Persistent (long) |
| `echo` | Echo (long) |
| `updown` | Up down (long) |
| `vibrate` | Vibrate only |
| `none` | No sound |

## Examples

### Zigbee button triggers notification

```berry
import PUSHOVER
import ZHB

ZHB.waitForStart(0xff)
ZHB.on_action(def (action, dev)
    if action == "single"
        PUSHOVER.send("Button pressed: " .. dev.getName(), "SLZB")
    elif action == "double"
        PUSHOVER.send("Double press: " .. dev.getName(), "SLZB", 1, "siren")
    end
end, 300000)
```

### Temperature alert with link

```berry
import PUSHOVER
import WEATHER

var w = WEATHER.get()
if w["temp"] > 35
    PUSHOVER.send_url(
        "<b>Temperature:</b> " .. str(w["temp"]) .. " C",
        "Heat Alert",
        "https://openweathermap.org",
        "View forecast"
    )
end
```

### Device offline — emergency notification

```berry
import PUSHOVER
import ZHB
import TIMER

ZHB.waitForStart(0xff)

TIMER.setInterval(def()
    var devices = ZHB.getDevices()
    for dev : devices
        if !dev.isOnline()
            PUSHOVER.send(dev.getName() .. " is offline!", "Device Alert", 2, "spacealarm")
        end
    end
end)
```

## Notes

- Uses the [Pushover Message API](https://pushover.net/api)
- Pushover requires a one-time app purchase ($5 USD) on iOS or Android
- Free tier: 10,000 messages/month per application
- HTML formatting is enabled by default (`<b>`, `<i>`, `<u>`, `<a href="">`)
- Emergency priority (`2`) auto-sets retry=60s and expire=300s
- Each call makes one HTTPS request (~1 KB temporary RAM, freed immediately)
