# TELEGRAM Module

Send and receive Telegram messages from Berry scripts via the Telegram Bot API.

## Setup

### Option A — Configure via UI (recommended)

1. Go to **Scripts Integrations** page
2. Click the **TELEGRAM** tile
3. Enter your **Bot Token** and **Chat ID**
4. Enable and save

Scripts will automatically use the saved credentials — no tokens in your code.

### Option B — Configure in script

```berry
import TELEGRAM
TELEGRAM.setup("123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11", "987654321")
```

This overrides the UI config for the current script session only.

### How to get Bot Token and Chat ID

1. Open Telegram and search for **@BotFather**
2. Send `/newbot` and follow the instructions to create a bot
3. Copy the **Bot Token** (looks like `123456:ABC-DEF...`)
4. To get your **Chat ID**: send a message to your bot, then open `https://api.telegram.org/bot<YOUR_TOKEN>/getUpdates` in a browser — your chat ID is in the `chat.id` field

## Functions

### TELEGRAM.setup(token, chat_id)

Override credentials for this script session.

| Parameter | Type | Description |
|-----------|------|-------------|
| `token` | string | Bot API token from @BotFather |
| `chat_id` | string | Target chat ID |

```berry
import TELEGRAM
TELEGRAM.setup("123456:ABC-DEF...", "987654321")
```

### TELEGRAM.send(text)

Send a text message to the configured chat. Returns the HTTP status code (200 = success).

| Parameter | Type | Description |
|-----------|------|-------------|
| `text` | string | Message text to send |

**Returns:** `int` — HTTP status code

```berry
import TELEGRAM

# Simple notification
TELEGRAM.send("Hello from SLZB!")

# With sensor data
var temp = 23.5
TELEGRAM.send("Temperature: " .. str(temp) .. "°C")
```

### TELEGRAM.getUpdates()

Poll Telegram for new incoming messages. Returns a list of message objects, or `nil` if there are no new messages. Automatically tracks the last seen message to avoid duplicates.

**Returns:** `list` of `map` objects, or `nil`

Each message map contains:

| Key | Type | Description |
|-----|------|-------------|
| `text` | string | Message text |
| `from` | string | Sender's first name |
| `chat_id` | int | Chat ID the message came from |
| `message_id` | int | Unique message identifier |

```berry
import TELEGRAM
import SLZB

var msgs = TELEGRAM.getUpdates()
if msgs
    for msg : msgs
        SLZB.log("From: " .. msg["from"] .. " Text: " .. msg["text"])
    end
end
```

## Examples

### Send alert on button press

```berry
import TELEGRAM
import BUTTON

BUTTON.on_press(def ()
    TELEGRAM.send("Button pressed!")
end)
```

### Send alert on Zigbee sensor event

```berry
import TELEGRAM
import ZB

ZB.on_message(def (msg)
    if msg["cluster"] == 0x0402
        var temp = msg["value"] / 100.0
        if temp > 30
            TELEGRAM.send("High temperature alert: " .. str(temp) .. "°C")
        end
    end
end)
```

### Poll for commands

```berry
import TELEGRAM
import TIMER
import SLZB

TIMER.every(10000, def ()
    var msgs = TELEGRAM.getUpdates()
    if msgs
        for msg : msgs
            if msg["text"] == "/status"
                TELEGRAM.send("Device is online!")
            elif msg["text"] == "/reboot"
                TELEGRAM.send("Rebooting...")
                SLZB.restart()
            end
        end
    end
end)
```

### Interactive light control

```berry
import TELEGRAM
import TIMER
import AMBILIGHT

TIMER.every(5000, def ()
    var msgs = TELEGRAM.getUpdates()
    if msgs
        for msg : msgs
            var cmd = msg["text"]
            if cmd == "/on"
                AMBILIGHT.setEffect(AMBILIGHT.Eff_Solid)
                TELEGRAM.send("Light ON")
            elif cmd == "/off"
                AMBILIGHT.setEffect(AMBILIGHT.Eff_Off)
                TELEGRAM.send("Light OFF")
            elif cmd == "/red"
                AMBILIGHT.setColor(0xFF0000)
                TELEGRAM.send("Color set to red")
            end
        end
    end
end)
```

## Notes

- Messages are sent via HTTPS to `api.telegram.org` — the device needs internet access
- `getUpdates()` uses short polling (no long-polling) to avoid blocking the script
- Each `getUpdates()` call uses ~4 KB of temporary RAM, freed immediately after
- `send()` uses ~2 KB of temporary RAM, freed immediately after
- The bot can only receive messages from users who have started a conversation with it first (Telegram requirement)
