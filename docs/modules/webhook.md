# WEBHOOK Module

A generic HTTP client for connecting to any service with a REST API. Supports POST, GET, and PUT with custom headers and JSON bodies.

Use this module when there is no dedicated integration module for the service you want to connect to.

## Setup

### Option A — Configure via UI

1. Go to **Scripts Integrations** page
2. Click the **WEBHOOK** tile
3. Fill in:
   - **URL** — default target URL
   - **Custom Headers** (optional) — JSON object with headers, e.g. `{"Authorization":"Bearer mytoken"}`
4. Enable and save

### Option B — Configure in script

```berry
import WEBHOOK
WEBHOOK.setup("https://example.com/api/data")

# With custom headers:
WEBHOOK.setup("https://example.com/api", '{"Authorization":"Bearer mytoken","X-Custom":"value"}')
```

### Option C — No setup, use ad-hoc URLs

Every function accepts an explicit URL, so you can use WEBHOOK without any setup:

```berry
import WEBHOOK
var r = WEBHOOK.post("https://example.com/api", '{"key":"value"}')
```

## Functions

### WEBHOOK.setup(url [, headers_json])

Set default URL and optional headers for this script session.

| Parameter | Type | Description |
|-----------|------|-------------|
| `url` | string | Default target URL |
| `headers_json` | string | (optional) JSON object with custom headers |

### WEBHOOK.post(body)

POST JSON body to the configured default URL.

| Parameter | Type | Description |
|-----------|------|-------------|
| `body` | string | JSON body to send |

**Returns:** `map` with `status` (int) and `body` (string)

### WEBHOOK.post(url, body)

POST JSON body to a specific URL (no setup required).

| Parameter | Type | Description |
|-----------|------|-------------|
| `url` | string | Target URL |
| `body` | string | JSON body to send |

**Returns:** `map` with `status` (int) and `body` (string)

### WEBHOOK.get()

GET the configured default URL.

**Returns:** `map` with `status` (int) and `body` (string)

### WEBHOOK.get(url)

GET a specific URL (no setup required).

| Parameter | Type | Description |
|-----------|------|-------------|
| `url` | string | Target URL |

**Returns:** `map` with `status` (int) and `body` (string)

### WEBHOOK.put(body) / WEBHOOK.put(url, body)

PUT request — same signature as `post()`.

**Returns:** `map` with `status` (int) and `body` (string)

## Response Format

All functions return a map:

```berry
var r = WEBHOOK.get("https://api.example.com/data")
print(r["status"])  # HTTP status code, e.g. 200
print(r["body"])    # Response body as string
```

To parse a JSON response:

```berry
import json
var r = WEBHOOK.get("https://api.example.com/data")
var data = json.load(r["body"])
print(data["temperature"])
```

## Examples

### Send sensor data to a custom API

```berry
import WEBHOOK
import ZHB

ZHB.waitForStart(0xff)
var sensor = ZHB.getDevice("Temperature Sensor")
var temp = sensor.getAttr("temperature")

var body = '{"sensor":"temperature","value":' .. str(temp) .. '}'
var r = WEBHOOK.post("https://myapi.example.com/data", body)
print("Status: " .. str(r["status"]))
```

### Read data from an external API

```berry
import WEBHOOK
import json

var r = WEBHOOK.get("https://api.example.com/config")
if r["status"] == 200
    var cfg = json.load(r["body"])
    print("Setting: " .. cfg["mode"])
end
```

### Authenticated API call

```berry
import WEBHOOK

# Setup with Bearer token
WEBHOOK.setup("https://api.example.com/devices", '{"Authorization":"Bearer abc123"}')

# All subsequent calls use the token
var r = WEBHOOK.post('{"action":"toggle","device":"relay1"}')
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
    WEBHOOK.post("https://myserver.com/zigbee-events", body)
end)
```

### Ping a health-check service

```berry
import WEBHOOK
import TIMER

# Send heartbeat every 5 minutes
TIMER.every(300000, def ()
    WEBHOOK.get("https://hc-ping.com/your-uuid-here")
end)
```

### Integration with services not covered by other modules

```berry
import WEBHOOK

# PushBullet notification
WEBHOOK.setup("https://api.pushbullet.com/v2/pushes", '{"Access-Token":"your-token","Content-Type":"application/json"}')
WEBHOOK.post('{"type":"note","title":"SLZB Alert","body":"Motion detected!"}')

# Twilio SMS (via their REST API)
# Any REST API can be called this way
```

## Notes

- Supports HTTP and HTTPS URLs
- `Content-Type: application/json` is set automatically for POST and PUT requests
- Custom headers from `setup()` are applied only when using the configured default URL; ad-hoc URLs use no custom headers
- Response buffer is 2 KB — larger responses will be truncated
- Each call makes one HTTP request, memory is freed immediately after
- Unlike the built-in `HTTP` module, WEBHOOK returns both the status code and response body as a map, making it easier to work with REST APIs
