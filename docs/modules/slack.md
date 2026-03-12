# SLACK Module

Send messages to Slack channels using [Incoming Webhooks](https://api.slack.com/messaging/webhooks).

## Setup

### Option A — Configure via UI (recommended)

1. Go to **Scripts Integrations** page
2. Click the **SLACK** tile
3. Paste your **Webhook URL**
4. Enable and save

### How to create a Slack Webhook

1. Go to [api.slack.com/apps](https://api.slack.com/apps) and click **Create New App** → **From scratch**
2. Name your app (e.g. "SLZB") and select your workspace
3. Go to **Incoming Webhooks** → toggle **Activate Incoming Webhooks** on
4. Click **Add New Webhook to Workspace** → select a channel → **Allow**
5. Copy the Webhook URL (looks like `https://hooks.slack.com/services/T.../B.../xxx...`)

### Option B — Configure in script

```berry
import SLACK
SLACK.setup("https://hooks.slack.com/services/T.../B.../xxx...")
```

## Functions

### SLACK.setup(webhook_url)

Override the webhook URL for this script session.

| Parameter | Type | Description |
|-----------|------|-------------|
| `webhook_url` | string | Slack Incoming Webhook URL |

### SLACK.send(text)

Send a simple text message to the default channel.

| Parameter | Type | Description |
|-----------|------|-------------|
| `text` | string | Message text (supports Slack markdown) |

**Returns:** `int` — HTTP status code (200 on success)

```berry
import SLACK
SLACK.send("Hello from SLZB!")
```

### SLACK.send_rich(text [, channel [, username [, icon_emoji]]])

Send a message with optional channel override, custom username, and emoji icon.

| Parameter | Type | Description |
|-----------|------|-------------|
| `text` | string | Message text |
| `channel` | string | (optional) Channel override, e.g. `"#alerts"` |
| `username` | string | (optional) Bot display name |
| `icon_emoji` | string | (optional) Emoji icon, e.g. `":robot_face:"` |

**Returns:** `int` — HTTP status code (200 on success)

> **Note:** Channel override, username, and icon_emoji require the webhook app to have appropriate permissions. Some workspaces restrict these overrides.

```berry
import SLACK
SLACK.send_rich("Sensor alert!", "#alerts", "SLZB-Bot", ":warning:")
```

## Slack Markdown

Slack supports its own markdown formatting in messages:

| Format | Syntax |
|--------|--------|
| **Bold** | `*bold*` |
| *Italic* | `_italic_` |
| ~~Strike~~ | `~strike~` |
| Code | `` `code` `` |
| Link | `<https://example.com\|Click here>` |
| User mention | `<@U1234567>` |
| Channel | `<#C1234567>` |

## Examples

### Notify on Zigbee device join

```berry
import SLACK
import ZHB

ZHB.waitForStart(0xff)
ZHB.on_join(def (dev)
    SLACK.send("New Zigbee device joined: " .. dev.getName())
end)
```

### Temperature alert

```berry
import SLACK
import WEATHER

var w = WEATHER.get()
if w["temp"] > 35
    SLACK.send_rich(":hot_face: Temperature alert: " .. str(w["temp"]) .. " C in " .. w["city"], "#alerts", "Weather Bot", ":thermometer:")
end
```

### Send sensor data periodically

```berry
import SLACK
import ZHB
import TIMER

ZHB.waitForStart(0xff)
var sensor = ZHB.getDevice("Temperature Sensor")

TIMER.every(3600000, def ()
    var temp = sensor.getAttr("temperature")
    SLACK.send("Hourly temp: " .. str(temp) .. " C")
end)
```

## Notes

- Uses Slack [Incoming Webhooks](https://api.slack.com/messaging/webhooks) — simple, no OAuth required
- Messages support Slack markdown formatting
- Each call makes one HTTPS request (~1 KB temporary RAM, freed immediately)
- Webhook URLs do not expire unless the app is deleted or the webhook is revoked
- Rate limit: Slack allows ~1 message per second per webhook
