# TEAMS Module

Send notifications to Microsoft Teams channels using [Workflows webhooks](https://learn.microsoft.com/en-us/microsoftteams/platform/webhooks-and-connectors/how-to/add-incoming-webhook) and Adaptive Cards.

> **Note:** Microsoft retired the legacy Office 365 connectors. This module uses the newer **Workflows** (Power Automate) webhook format with Adaptive Cards.

## Setup

### Option A — Configure via UI (recommended)

1. Go to **Scripts Integrations** page
2. Click the **MS TEAMS** tile
3. Paste your **Webhook URL**
4. Enable and save

### How to create a Teams Webhook

1. Open **Microsoft Teams** and go to the channel where you want notifications
2. Click the **...** menu on the channel → **Workflows**
3. Search for **"Post to a channel when a webhook request is received"**
4. Select the workflow, name it (e.g. "SLZB Alerts"), and pick the target channel
5. Copy the webhook URL provided

### Option B — Configure in script

```berry
import TEAMS
TEAMS.setup("https://prod-XX.westus.logic.azure.com:443/workflows/...")
```

## Functions

### TEAMS.setup(webhook_url)

Override the webhook URL for this script session.

| Parameter | Type | Description |
|-----------|------|-------------|
| `webhook_url` | string | Teams Workflows webhook URL |

### TEAMS.send(text)

Send a simple text message as an Adaptive Card.

| Parameter | Type | Description |
|-----------|------|-------------|
| `text` | string | Message text |

**Returns:** `int` — HTTP status code (200 or 202 on success)

```berry
import TEAMS
TEAMS.send("Hello from SLZB!")
```

### TEAMS.send_card(title, message [, color])

Send a styled Adaptive Card with a title and colored header.

| Parameter | Type | Description |
|-----------|------|-------------|
| `title` | string | Card title (shown in bold) |
| `message` | string | Card body text |
| `color` | string | (optional) Header color: `"FF0000"` (red/attention), `"00FF00"` (green/good), `"FFFF00"` (yellow/warning), or any other value (blue/accent). Default: `"0078D7"` (accent) |

**Returns:** `int` — HTTP status code

```berry
import TEAMS
TEAMS.send_card("Temperature Alert", "Living room is 35 C!", "FF0000")
TEAMS.send_card("System OK", "All sensors reporting normally", "00FF00")
```

## Color Mapping

Adaptive Cards use style names instead of arbitrary hex colors:

| Color Code | Adaptive Card Style | Appearance |
|------------|-------------------|------------|
| `FF0000` | attention | Red |
| `00FF00` | good | Green |
| `FFFF00` | warning | Yellow |
| Any other | accent | Blue (default) |

## Examples

### Zigbee device offline alert

```berry
import TEAMS
import ZHB
import TIMER

ZHB.waitForStart(0xff)

TIMER.every(300000, def ()
    var devices = ZHB.getDevices()
    for dev : devices
        if !dev.isOnline()
            TEAMS.send_card("Device Offline", dev.getName() .. " is not responding", "FF0000")
        end
    end
end)
```

### Temperature monitoring

```berry
import TEAMS
import WEATHER

var w = WEATHER.get()
if w["temp"] > 35
    TEAMS.send_card("Heat Alert", "Temperature: " .. str(w["temp"]) .. " C in " .. w["city"], "FF0000")
elif w["temp"] < 0
    TEAMS.send_card("Frost Alert", "Temperature: " .. str(w["temp"]) .. " C in " .. w["city"], "0000FF")
else
    TEAMS.send("Current temp: " .. str(w["temp"]) .. " C")
end
```

### Daily status report

```berry
import TEAMS
import TIME
import TIMER

TIMER.every(86400000, def ()
    var t = TIME.getAll()
    TEAMS.send_card("Daily Report", "SLZB is online. Date: " .. str(t["day"]) .. "/" .. str(t["month"]) .. "/" .. str(t["year"]), "00FF00")
end)
```

## Notes

- Uses **Workflows** (Power Automate) webhooks with **Adaptive Cards** format
- Legacy Office 365 connector webhooks are deprecated by Microsoft — use Workflows instead
- Each call makes one HTTPS request (~1 KB temporary RAM, freed immediately)
- Card body is limited to ~1 KB to fit in the ESP32 buffer
- Webhook URLs do not expire unless the Workflow is deleted
- Text in cards supports basic markdown: `**bold**`, `_italic_`, `[link](url)`
