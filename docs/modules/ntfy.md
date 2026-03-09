# NTFY Module

Send push notifications from Berry scripts via ntfy.sh or a self-hosted ntfy instance.

## Setup

### Step 1 — Choose a topic

Ntfy requires no account. Just pick a unique topic name (e.g. `slzb-my-home-alerts`). Anyone who knows the topic name can subscribe, so use something hard to guess.

### Step 2 — Subscribe on your phone

1. Install the **ntfy** app from [Google Play](https://play.google.com/store/apps/details?id=io.heckel.ntfy) or [App Store](https://apps.apple.com/app/ntfy/id1625396347)
2. Tap **+** and subscribe to your topic name
3. You can also subscribe at `https://ntfy.sh/<your_topic>` in a browser

### Step 3 — Configure via UI (recommended)

1. Go to **Scripts Integrations** page
2. Click the **NTFY** tile
3. Enter the **Server URL** (`https://ntfy.sh` for the public server, or your self-hosted URL)
4. Enter your **Topic** name
5. Enable and save

### Alternative — Configure in script

```berry
import NTFY
NTFY.setup("https://ntfy.sh", "slzb-my-home-alerts")
```

This overrides the UI config for the current script session only.

## Functions

### NTFY.setup(server, topic)

Override server and topic for this script session.

| Parameter | Type | Description |
|-----------|------|-------------|
| `server` | string | Server URL (e.g. `https://ntfy.sh`) |
| `topic` | string | Topic name |

```berry
import NTFY
NTFY.setup("https://ntfy.sh", "slzb-my-home-alerts")
```

### NTFY.send(text)

Send a push notification. Returns the HTTP status code (200 = success).

| Parameter | Type | Description |
|-----------|------|-------------|
| `text` | string | Notification text |

**Returns:** `int` — HTTP status code

```berry
import NTFY

NTFY.send("Sensor triggered!")
```

## Examples

### Send alert on button press

```berry
import NTFY
import BUTTON

BUTTON.on_press(def ()
    NTFY.send("Button pressed on SLZB!")
end)
```

### Temperature alert

```berry
import NTFY
import ZB

ZB.on_message(def (msg)
    if msg["cluster"] == 0x0402
        var temp = msg["value"] / 100.0
        if temp > 30
            NTFY.send("High temperature: " .. str(temp) .. " C")
        end
    end
end)
```

### Water leak alert

```berry
import NTFY
import ZB

ZB.on_message(def (msg)
    if msg["cluster"] == 0x0500
        NTFY.send("Water leak detected!")
    end
end)
```

## Notes

- No account required — ntfy.sh is free and open source
- Send only — receiving messages is not supported
- Public topics on ntfy.sh are visible to anyone who knows the topic name; use a unique, hard-to-guess name
- For private notifications, use a self-hosted ntfy instance with authentication
- If the Server URL field is left empty, it defaults to `https://ntfy.sh`
- `send()` uses ~2 KB of temporary RAM, freed immediately after
- The device needs internet access for HTTPS calls
