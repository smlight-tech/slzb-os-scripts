# WEBHOOK Module

A generic HTTP client for connecting to any service with a REST API. Supports multiple named webhooks, POST, GET, and PUT with custom headers and JSON bodies.

Use this module when there is no dedicated integration module for the service you want to connect to.

## Setup

### Option A — Configure via UI (recommended)

1. Go to **Scripts Integrations** page
2. Click the **WEBHOOK** tile
3. Add one or more webhooks, each with:
   - **Name** — a friendly name (e.g. "My API", "Health Check")
   - **URL** — target URL
   - **Custom Headers** (optional) — JSON object, e.g. `{"Authorization":"Bearer mytoken"}`
4. Enable and save

You can add as many webhooks as you need — just like WLED or ESPHome devices.

### Option B — Configure in script

```berry
import WEBHOOK

# Named webhook
WEBHOOK.setup("My API", "https://api.example.com/data", '{"Authorization":"Bearer abc123"}')

# Simple (unnamed) webhook
WEBHOOK.setup("https://example.com/api/data")
```

### Option C — No setup, use ad-hoc URLs

Every function accepts a direct URL, so you can use WEBHOOK without any setup:

```berry
import WEBHOOK
var r = WEBHOOK.post("https://example.com/api", '{"key":"value"}')
```

## Functions

### WEBHOOK.setup(url [, headers_json])

Set a default (unnamed) webhook for this script session.

### WEBHOOK.setup(name, url [, headers_json])

Set a named webhook for this script session.

| Parameter | Type | Description |
|-----------|------|-------------|
| `name` | string | Webhook name (must not contain `://`) |
| `url` | string | Target URL |
| `headers_json` | string | (optional) JSON object with custom headers |

### WEBHOOK.post(name_or_url, body)

POST JSON body to a named webhook or direct URL.

| Parameter | Type | Description |
|-----------|------|-------------|
| `name_or_url` | string | Webhook name or direct URL |
| `body` | string | JSON body to send |

**Returns:** `map` with `status` (int) and `body` (string)

### WEBHOOK.post(body)

POST JSON body to the default (unnamed) webhook.

### WEBHOOK.get(name_or_url)

GET request to a named webhook or direct URL.

**Returns:** `map` with `status` (int) and `body` (string)

### WEBHOOK.get()

GET the default (unnamed) webhook.

### WEBHOOK.put(name_or_url, body) / WEBHOOK.put(body)

PUT request — same signature as `post()`.

**Returns:** `map` with `status` (int) and `body` (string)

### WEBHOOK.list()

List all configured webhooks.

**Returns:** `map` — keys are webhook names, values are URLs.

```berry
import WEBHOOK
var all = WEBHOOK.list()
for name : all.keys()
    print(name .. " -> " .. all[name])
end
```

## Name vs URL Detection

The module auto-detects whether the first argument is a name or a URL:
- Contains `://` → treated as a **direct URL** (e.g. `"https://example.com"`)
- No `://` → treated as a **webhook name** (e.g. `"My API"`)

## Response Format

All functions return a map:

```berry
var r = WEBHOOK.get("My API")
print(r["status"])  # HTTP status code, e.g. 200
print(r["body"])    # Response body as string
```

To parse a JSON response:

```berry
import json
var r = WEBHOOK.get("My API")
var data = json.load(r["body"])
print(data["temperature"])
```

## Examples

### Multiple webhooks for different services

```berry
import WEBHOOK

# POST to named webhooks (configured via UI)
WEBHOOK.post("Sensor API", '{"temp": 23.5}')
WEBHOOK.post("Health Check", '{"status": "ok"}')
WEBHOOK.get("Config Server")
```

### Send sensor data to a custom API

```berry
import WEBHOOK
import ZHB

ZHB.waitForStart(0xff)
var sensor = ZHB.getDevice("Temperature Sensor")
var temp = sensor.getAttr("temperature")

var body = '{"sensor":"temperature","value":' .. str(temp) .. '}'
var r = WEBHOOK.post("My API", body)
print("Status: " .. str(r["status"]))
```

### Authenticated API call

```berry
import WEBHOOK

# Setup with Bearer token (in script)
WEBHOOK.setup("My API", "https://api.example.com/devices", '{"Authorization":"Bearer abc123"}')

var r = WEBHOOK.post("My API", '{"action":"toggle","device":"relay1"}')
print(r["status"])
```

### Forward Zigbee events to a custom server

```berry
import WEBHOOK
import ZHB
import json

ZHB.waitForStart(0xff)
ZHB.on_action(def (action, dev)
    var body = json.dump({
        "device": dev.getName(),
        "action": action,
        "ieee": dev.getIeee()
    })
    WEBHOOK.post("Event Server", body)
end, 300000)
```

### Ping a health-check service

```berry
import WEBHOOK
import TIMER

# Send heartbeat every 5 minutes
TIMER.setInterval(def()
    WEBHOOK.get("Health Check")
end)
```

### Ad-hoc URL (no setup needed)

```berry
import WEBHOOK

# Direct URL — works without any configuration
var r = WEBHOOK.post("https://api.pushbullet.com/v2/pushes", '{"type":"note","title":"SLZB","body":"Alert!"}')
```

## Notes

- Supports **multiple named webhooks** — configure via UI or `setup()`
- Direct URLs (containing `://`) always work without configuration
- Supports HTTP and HTTPS URLs
- `Content-Type: application/json` is set automatically for POST and PUT
- Custom headers from UI config are applied per webhook
- Response buffer is 2 KB — larger responses will be truncated
- Each call makes one HTTP request, memory is freed immediately after
- Unlike the built-in `HTTP` module, WEBHOOK returns both the status code and response body as a map
