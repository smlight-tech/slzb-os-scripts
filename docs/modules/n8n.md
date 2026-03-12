# n8n Integration

Connect SLZB to [n8n](https://n8n.io/) workflow automation — trigger any n8n workflow from Zigbee events, sensors, buttons, or schedules.

> This integration uses the [WEBHOOK](webhook.md) module. No separate module needed — n8n workflows are triggered via standard HTTP webhooks.

## Setup

### 1. Create a webhook trigger in n8n

1. Open your n8n instance
2. Create a new workflow
3. Add a **Webhook** trigger node
4. Set method to **POST**
5. Copy the **Production URL** (e.g. `https://n8n.local:5678/webhook/abc123-def456`)

### 2. Configure in SLZB

#### Option A — Named webhook via UI (recommended)

1. Go to **Scripts Integrations** → **WEBHOOK**
2. Add a device:
   - **Name**: `n8n Motion Alert` (or any friendly name)
   - **URL**: paste the n8n webhook URL
   - **Headers**: `{"Content-Type": "application/json"}`
3. Enable and save

Then in your script:
```berry
import WEBHOOK
WEBHOOK.post("n8n Motion Alert", '{"room": "kitchen"}')
```

#### Option B — Direct URL in script

```berry
import WEBHOOK
WEBHOOK.post("https://n8n.local:5678/webhook/abc123-def456", '{"room": "kitchen"}')
```

## Examples

### Zigbee button triggers n8n workflow

A button press triggers an n8n workflow that sends a Telegram message, logs to a spreadsheet, and turns on a smart plug.

```berry
import WEBHOOK
import ZHB

ZHB.waitForStart(0xff)
ZHB.on_action(def (action, dev)
    if dev.getName() == "Desk Button" && action == "single"
        WEBHOOK.post("n8n Desk Button", '{"action": "single"}')
    elif action == "double"
        WEBHOOK.post("n8n Desk Button", '{"action": "double"}')
    end
end)
```

### Send sensor data to n8n for processing

n8n can store data in a database, check thresholds, send alerts, or forward to any of 400+ integrated services.

```berry
import WEBHOOK
import ZHB
import TIMER

ZHB.waitForStart(0xff)
var sensor = ZHB.getDevice("Living Room Sensor")

TIMER.every(300000, def ()
    var temp = sensor.getTemperature()
    var hum = sensor.getHumidity()
    WEBHOOK.post("n8n Sensor Log", '{"temperature": ' .. str(temp) .. ', "humidity": ' .. str(hum) .. '}')
end)
```

### Door open alert with context

n8n workflow checks the time — during night hours sends a high-priority push notification, during day just logs it.

```berry
import WEBHOOK
import ZHB

ZHB.waitForStart(0xff)
ZHB.on_action(def (action, dev)
    if dev.getName() == "Front Door" && action == "contact"
        WEBHOOK.post("n8n Door Alert", '{"door": "front", "state": "open"}')
    end
end)
```

### Zigbee network health report

Send periodic network stats to n8n, which can build dashboards, detect trends, or alert on anomalies.

```berry
import WEBHOOK
import ZB
import TIMER

TIMER.every(3600000, def ()
    var clients = ZB.getZbClients()
    WEBHOOK.post("n8n Network Report", '{"zigbee_clients": ' .. str(clients) .. '}')
end)
```

### Motion-triggered automation chain

Motion sensor triggers n8n, which orchestrates: turn on lights (via Hue), start music (via Spotify), adjust thermostat (via Home Assistant), and log the event.

```berry
import WEBHOOK
import ZHB

ZHB.waitForStart(0xff)
ZHB.on_action(def (action, dev)
    if dev.getName() == "Office Motion" && action == "occupancy"
        WEBHOOK.post("n8n Office Presence", '{"occupied": true}')
    end
end)
```

## Why use n8n with SLZB?

SLZB scripts handle real-time Zigbee events and local control. n8n extends this with:

- **400+ integrations** — Google Sheets, Notion, Airtable, Slack, Matrix, Twilio, and more
- **Visual workflow builder** — no coding needed on the n8n side
- **Conditional logic** — route events based on time, day, sensor values
- **Data transformation** — format, filter, aggregate before sending to destinations
- **Retry and error handling** — automatic retries with backoff
- **Self-hosted** — runs on your own server, no cloud dependency

## Notes

- n8n webhook URLs work with both test and production modes — use the **Production URL** for scripts
- The WEBHOOK module sends a standard HTTP POST with JSON body — compatible with any n8n webhook trigger
- For bidirectional communication (n8n → SLZB), use the [WEBSERVER](webserver.md) module to receive incoming webhooks
- n8n is free and open-source for self-hosting, or available as a cloud service at [n8n.io](https://n8n.io/)
