# DISCORD Module

Send notifications to a Discord channel from Berry scripts via webhooks.

## Setup

### Step 1 — Create a Discord webhook

1. Open Discord and go to the channel where you want to receive messages
2. Click the gear icon (Edit Channel) → **Integrations** → **Webhooks**
3. Click **New Webhook**
4. Give it a name (e.g. "SLZB Alerts") and click **Copy Webhook URL**
5. The URL looks like `https://discord.com/api/webhooks/1234567890/abcdefg...`

### Step 2 — Configure via UI (recommended)

1. Go to **Scripts Integrations** page
2. Click the **DISCORD** tile
3. Paste the **Webhook URL**
4. Enable and save

### Alternative — Configure in script

```berry
import DISCORD
DISCORD.setup("https://discord.com/api/webhooks/1234567890/abcdefg...")
```

This overrides the UI config for the current script session only.

## Functions

### DISCORD.setup(webhook_url)

Override the webhook URL for this script session.

| Parameter | Type | Description |
|-----------|------|-------------|
| `webhook_url` | string | Discord webhook URL |

```berry
import DISCORD
DISCORD.setup("https://discord.com/api/webhooks/1234567890/abcdefg...")
```

### DISCORD.send(text)

Send a text message to the configured Discord channel. Returns the HTTP status code (204 = success).

| Parameter | Type | Description |
|-----------|------|-------------|
| `text` | string | Message text to send |

**Returns:** `int` — HTTP status code (204 = success, Discord returns 204 No Content on success)

```berry
import DISCORD

DISCORD.send("Hello from SLZB!")
```

## Examples

### Send alert on button press

```berry
import DISCORD
import BUTTON

BUTTON.on_press(def ()
    DISCORD.send("Button pressed on SLZB!")
end)
```

### Temperature alert

```berry
import DISCORD
import ZB

ZB.on_message(def (msg)
    if msg["cluster"] == 0x0402
        var temp = msg["value"] / 100.0
        if temp > 30
            DISCORD.send("High temperature alert: " .. str(temp) .. " C")
        end
    end
end)
```

### Door sensor notification

```berry
import DISCORD
import ZB

ZB.on_message(def (msg)
    if msg["cluster"] == 0x0006
        var state = msg["value"]
        if state == 1
            DISCORD.send("Door opened!")
        else
            DISCORD.send("Door closed.")
        end
    end
end)
```

## Notes

- Uses Discord webhook API — no bot account needed, just a webhook URL
- Send only — receiving Discord messages is not supported
- Discord returns HTTP 204 (No Content) on success, not 200
- Discord rate limits webhooks to approximately 5 requests per 2 seconds per webhook
- `send()` uses ~2 KB of temporary RAM, freed immediately after
- The device needs internet access for HTTPS calls to `discord.com`
