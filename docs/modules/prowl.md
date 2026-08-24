# PROWL Module

Send push notifications to iPhone / iPad via [Prowl](https://www.prowlapp.com/) with support for priority levels and supplementary URLs.

## Setup

### Option A — Configure via UI (recommended)

1. Go to **Scripts Integrations** page
2. Click the **PROWL** tile
3. Fill in:
   - **API Key** — from [prowlapp.com/api_settings.php](https://www.prowlapp.com/api_settings.php) (40-character hex string; several keys can be comma-separated to notify several devices/accounts)
   - **Application Name** — (optional) name shown in the notification, default `SLZB-OS`
4. Enable and save

### How to get credentials

1. Install the **Prowl** app from the [App Store](https://apps.apple.com/app/prowl-easy-push-notifications/id320876271) (one-time purchase) and create a Prowl account
2. Log in at [prowlapp.com](https://www.prowlapp.com/) and open **API Keys**
3. Click **Generate Key** and copy the 40-character **API Key**

### Option B — Configure in script

```berry
import PROWL
PROWL.setup("your-40-char-api-key")
PROWL.setup("your-40-char-api-key", "My Home")   # with a custom application name
```

This overrides the UI config for the current script session only.

## Functions

### PROWL.setup(api_key [, application])

Override credentials for this script session.

| Parameter | Type | Description |
|-----------|------|-------------|
| `api_key` | string | Prowl API key (40-char hex); several keys comma-separated |
| `application` | string | (optional) Application name shown in the notification, default `SLZB-OS` |

### PROWL.send(event [, description [, priority [, url]]])

Send a push notification.

| Parameter | Type | Description |
|-----------|------|-------------|
| `event` | string | Event name / notification title (max 1024 bytes) |
| `description` | string | (optional) Notification body (up to 5 kb) |
| `priority` | int | (optional) Priority level, see table below (default `0`) |
| `url` | string | (optional) URL attached to the notification, opened on tap (max 512 bytes) |

**Returns:** `int` — HTTP status code (200 on success)

### Priority Levels

| Value | Name | Description |
|-------|------|-------------|
| `-2` | Very Low | Lowest priority |
| `-1` | Moderate | Low priority |
| `0` | Normal | Default |
| `1` | High | High priority |
| `2` | Emergency | Highest priority — can bypass quiet hours when enabled in the Prowl app |

```berry
import PROWL

# Simple notification
PROWL.send("Sensor triggered!")

# Event + description
PROWL.send("Door opened", "Front door was opened at night")

# High priority
PROWL.send("FIRE ALARM!", "Smoke detected in kitchen", 2)

# Notification with a link
PROWL.send("Temperature is 35 C", "Tap to open dashboard", 0, "https://my-grafana.local/dashboard")
```

### PROWL.verify()

Check that the configured API key is valid. Useful for debugging setup.

**Returns:** `int` — HTTP status code (`200` valid key, `401` invalid key, `406` rate limit exceeded)

```berry
import PROWL
import SLZB
if PROWL.verify() == 200
    SLZB.log("Prowl API key is valid")
end
```

### Return Codes

| Code | Meaning |
|------|---------|
| `200` | Notification accepted |
| `400` | Bad request — parameter validation failed (e.g. too long) |
| `401` | Not authorized — invalid API key |
| `406` | Rate limit exceeded (1000 calls/hour per IP) |
| `500` | Prowl server error |

## Examples

### Zigbee button triggers notification

```berry
import PROWL
import ZHB

ZHB.waitForStart(0xff)
ZHB.on_action(def (action, dev)
    if action == "single"
        PROWL.send("Button pressed", dev.getName())
    elif action == "double"
        PROWL.send("Double press", dev.getName(), 1)
    end
end, 300000)
```

### Temperature alert with link

```berry
import PROWL
import WEATHER

var w = WEATHER.get()
if w["temp"] > 35
    PROWL.send("Heat Alert", "Temperature: " .. str(w["temp"]) .. " C", 1, "https://openweathermap.org")
end
```

### Check configuration at script start

```berry
import PROWL
import SLZB

var status = PROWL.verify()
if status != 200
    SLZB.log("Prowl not configured correctly, status: " .. str(status))
end
```

## Notes

- Uses the [Prowl Public API](https://www.prowlapp.com/api.php) (`/publicapi/add`, `/publicapi/verify`)
- Prowl is iOS-only — requires the Prowl app (one-time purchase) on iPhone / iPad
- Rate limit: 1000 API calls per hour per IP address
- `event` is required; `description` and `url` are optional
- Several API keys can be comma-separated in the configuration to notify several devices/accounts in one call (`verify()` checks only the first key)
- Each call makes one HTTPS request
- Not recommended to use inside TIMER callbacks.
