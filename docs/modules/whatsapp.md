# WHATSAPP Module

Send WhatsApp messages from Berry scripts via the CallMeBot free API.

## Setup

### Step 1 — Register with CallMeBot

1. Add the CallMeBot phone number **+34 644 59 71 67** to your phone contacts
2. Send the message `I allow callmebot to send me messages` to this contact via WhatsApp
3. Wait for the reply — you'll receive your **API Key**
4. Your phone number must include the country code without `+` or `00` (e.g. `34612345678` for Spain)

### Step 2 — Configure via UI (recommended)

1. Go to **Scripts Integrations** page
2. Click the **WHATSAPP** tile
3. Enter your **API Key** and **Phone Number** (with country code, no `+`)
4. Enable and save

### Alternative — Configure in script

```berry
import WHATSAPP
WHATSAPP.setup("123456", "34612345678")
```

This overrides the UI config for the current script session only.

## Functions

### WHATSAPP.setup(api_key, phone)

Override credentials for this script session.

| Parameter | Type | Description |
|-----------|------|-------------|
| `api_key` | string | API key from CallMeBot |
| `phone` | string | Phone number with country code (no `+`) |

```berry
import WHATSAPP
WHATSAPP.setup("123456", "34612345678")
```

### WHATSAPP.send(text)

Send a text message to the configured phone number. Returns the HTTP status code (200 = success).

| Parameter | Type | Description |
|-----------|------|-------------|
| `text` | string | Message text to send |

**Returns:** `int` — HTTP status code

```berry
import WHATSAPP

WHATSAPP.send("Hello from SLZB!")
```

## Examples

### Send alert on button press

```berry
import WHATSAPP
import BUTTON

BUTTON.on_press(def ()
    WHATSAPP.send("Button pressed on SLZB!")
end, 3600000)
```

### Temperature alert

```berry
import WHATSAPP
import ZB

ZB.on_message(def (msg)
    if msg["cluster"] == 0x0402
        var temp = msg["value"] / 100.0
        if temp > 30
            WHATSAPP.send("High temperature: " .. str(temp) .. " C")
        end
    end
end)
```

### Periodic status report

```berry
import WHATSAPP
import TIMER
import SLZB

TIMER.setInterval(def()
    WHATSAPP.send("SLZB device is online. Uptime: " .. str(SLZB.uptime()) .. "s")
end)
```

## Notes

- Uses the free CallMeBot API (`api.callmebot.com`) — the device needs internet access
- Send only — receiving WhatsApp messages is not supported
- CallMeBot has a rate limit of approximately 1 message per 2 seconds; avoid sending too frequently
- `send()` uses ~2 KB of temporary RAM, freed immediately after
- Special characters in messages are URL-encoded automatically
- Phone number must include country code without `+` or `00` prefix (e.g. `34612345678`)
