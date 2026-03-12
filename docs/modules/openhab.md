# OpenHAB Integration

Connect SLZB to [OpenHAB](https://www.openhab.org/) — read item states, send commands, and trigger rules from Zigbee events.

> This integration uses the [WEBHOOK](webhook.md) module. No separate module needed — OpenHAB's REST API works with standard HTTP requests.

## Setup

### 1. Get your OpenHAB API token

1. Open OpenHAB UI → **Profile** (bottom-left)
2. Go to **API Tokens**
3. Click **Create new API token**
4. Copy the token

### 2. Configure in SLZB

#### Option A — Named webhook via UI (recommended)

1. Go to **Scripts Integrations** → **WEBHOOK**
2. Add a device:
   - **Name**: `OpenHAB`
   - **URL**: `http://192.168.1.100:8080/rest/items/`
   - **Headers**: `{"Authorization": "Bearer YOUR_TOKEN", "Content-Type": "text/plain"}`
3. Enable and save

#### Option B — Direct in script

```berry
import HTTP

var host = "http://192.168.1.100:8080"
var token = "oh.mytoken.xxx"

var h = HTTP.open(host .. "/rest/items/LivingRoom_Light", "POST", 512, false)
HTTP.setHeader("Authorization", "Bearer " .. token)
HTTP.setHeader("Content-Type", "text/plain")
HTTP.setPostData("ON")
HTTP.perform()
HTTP.close()
```

## Examples

### Send command to OpenHAB item

```berry
import HTTP

var host = "http://192.168.1.100:8080"
var token = "oh.mytoken.xxx"

def oh_command(item, command)
    var h = HTTP.open(host .. "/rest/items/" .. item, "POST", 512, false)
    HTTP.setHeader("Authorization", "Bearer " .. token)
    HTTP.setHeader("Content-Type", "text/plain")
    HTTP.setPostData(command)
    HTTP.perform()
    HTTP.close()
end

oh_command("LivingRoom_Light", "ON")
oh_command("Thermostat_SetPoint", "22")
oh_command("Rollershutter_LivingRoom", "50")
```

### Read item state

```berry
import HTTP
import json

var host = "http://192.168.1.100:8080"
var token = "oh.mytoken.xxx"

def oh_get_state(item)
    var h = HTTP.open(host .. "/rest/items/" .. item, "GET", 1024, false)
    HTTP.setHeader("Authorization", "Bearer " .. token)
    HTTP.perform()
    var resp = HTTP.getResponse()
    HTTP.close()
    var data = json.load(resp)
    return data ? data["state"] : nil
end

var temp = oh_get_state("Temperature_LivingRoom")
print("Temperature: " .. temp)
```

### Zigbee button controls OpenHAB item

```berry
import HTTP
import ZHB

var host = "http://192.168.1.100:8080"
var token = "oh.mytoken.xxx"

def oh_command(item, command)
    var h = HTTP.open(host .. "/rest/items/" .. item, "POST", 512, false)
    HTTP.setHeader("Authorization", "Bearer " .. token)
    HTTP.setHeader("Content-Type", "text/plain")
    HTTP.setPostData(command)
    HTTP.perform()
    HTTP.close()
end

ZHB.waitForStart(0xff)
ZHB.on_action(def (action, dev)
    if dev.getName() == "Wall Switch"
        if action == "single"
            oh_command("LivingRoom_Light", "ON")
        elif action == "double"
            oh_command("LivingRoom_Light", "OFF")
        elif action == "long"
            oh_command("Scene_MovieMode", "ON")
        end
    end
end)
```

### Sensor data to OpenHAB

```berry
import HTTP
import ZHB
import TIMER

var host = "http://192.168.1.100:8080"
var token = "oh.mytoken.xxx"

def oh_update(item, value)
    var h = HTTP.open(host .. "/rest/items/" .. item, "PUT", 512, false)
    HTTP.setHeader("Authorization", "Bearer " .. token)
    HTTP.setHeader("Content-Type", "text/plain")
    HTTP.setPostData(str(value))
    HTTP.perform()
    HTTP.close()
end

ZHB.waitForStart(0xff)
var sensor = ZHB.getDevice("Kitchen Sensor")

TIMER.every(60000, def ()
    oh_update("Zigbee_Kitchen_Temp", sensor.getTemperature())
    oh_update("Zigbee_Kitchen_Humidity", sensor.getHumidity())
end)
```

## OpenHAB REST API Quick Reference

| Action | Method | URL | Body |
|--------|--------|-----|------|
| Send command | POST | `/rest/items/{item}` | Command text (e.g. `ON`, `OFF`, `50`) |
| Update state | PUT | `/rest/items/{item}/state` | State text |
| Read state | GET | `/rest/items/{item}` | — |
| List items | GET | `/rest/items` | — |
| Trigger rule | POST | `/rest/rules/{ruleUID}/runnow` | — |

## Notes

- OpenHAB REST API runs on port `8080` by default
- Authentication requires a Bearer token (API Token from OpenHAB UI)
- Commands use `text/plain` content type, not JSON
- The POST endpoint sends a **command** (triggers rules), PUT updates **state** directly
- For bidirectional communication (OpenHAB → SLZB), use the [WEBSERVER](webserver.md) module and OpenHAB's HTTP binding
- [OpenHAB REST API docs](https://www.openhab.org/docs/configuration/restdocs.html)
