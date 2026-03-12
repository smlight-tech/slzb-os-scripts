# Frigate Integration

Connect SLZB to [Frigate](https://frigate.video/) NVR — react to AI-powered object detection (people, cars, animals) from your security cameras.

> This integration uses the [MQTT](mqtt.md) module for real-time events and/or the [HTTP](http.md) module for API queries. No separate module needed.

## Setup

### Prerequisites

1. A running Frigate instance with cameras configured
2. An MQTT broker connected to both Frigate and SLZB

### Configure Frigate MQTT

In your Frigate config (`config.yml`), MQTT should be enabled:

```yaml
mqtt:
  host: 192.168.1.100
  port: 1883
```

### Configure SLZB MQTT

Set up the same MQTT broker in SLZB: **Settings → MQTT** or use `MQTT.setup()` in script.

## Real-Time Events via MQTT (recommended)

Frigate publishes detection events to MQTT topics. This is the best approach — events arrive instantly, no polling needed.

### React to any person detection

```berry
import MQTT
import json

MQTT.waitConnect(0xff)
MQTT.subscribe("frigate/events", def (topic, payload)
    var data = json.load(payload)
    if data && data["type"] == "new"
        var after = data["after"]
        if after["label"] == "person"
            var camera = after["camera"]
            print("Person detected on " .. camera)
        end
    end
end)
```

### Turn on lights when person detected

```berry
import MQTT
import ZHB
import json

ZHB.waitForStart(0xff)
MQTT.waitConnect(0xff)

var porch_light = ZHB.getDevice("Porch Light")

MQTT.subscribe("frigate/events", def (topic, payload)
    var data = json.load(payload)
    if data && data["type"] == "new"
        var after = data["after"]
        if after["label"] == "person" && after["camera"] == "front_door"
            porch_light.sendOnOff(1)
        end
    end
end)
```

### Car in driveway notification

```berry
import MQTT
import TELEGRAM
import json

MQTT.waitConnect(0xff)
MQTT.subscribe("frigate/events", def (topic, payload)
    var data = json.load(payload)
    if data && data["type"] == "new"
        var after = data["after"]
        if after["label"] == "car" && after["camera"] == "driveway"
            TELEGRAM.send("Car detected in driveway!")
        end
    end
end)
```

### Trigger alarm on person detection at night

```berry
import MQTT
import BUZZER
import TIME
import json

MQTT.waitConnect(0xff)
MQTT.subscribe("frigate/events", def (topic, payload)
    var data = json.load(payload)
    if data && data["type"] == "new"
        var after = data["after"]
        if after["label"] == "person" && after["camera"] == "backyard"
            var t = TIME.getAll()
            if t["hour"] >= 23 || t["hour"] < 6
                BUZZER.play("Alarm:d=4,o=5,b=200:16e6,16p,16e6,16p,16e6,16p")
                import TELEGRAM
                TELEGRAM.send("ALERT: Person detected in backyard at night!")
            end
        end
    end
end)
```

### React to specific zones

Frigate supports detection zones. The zone info is included in the event payload.

```berry
import MQTT
import ZHB
import json

ZHB.waitForStart(0xff)
MQTT.waitConnect(0xff)

var garage_light = ZHB.getDevice("Garage Light")

MQTT.subscribe("frigate/events", def (topic, payload)
    var data = json.load(payload)
    if data && data["type"] == "new"
        var after = data["after"]
        var zones = after["current_zones"]
        if after["label"] == "person"
            for zone : zones
                if zone == "garage_entrance"
                    garage_light.sendOnOff(1)
                end
            end
        end
    end
end)
```

## HTTP API (for polling and queries)

Use the HTTP module to query Frigate's REST API for stats or recent events.

### Get recent events

```berry
import HTTP
import json

var h = HTTP.open("http://192.168.1.100:5000/api/events?limit=5", "GET", 4096, false)
HTTP.perform()
var resp = HTTP.getResponse()
HTTP.close()

var events = json.load(resp)
if events
    for ev : events
        print(ev["label"] .. " on " .. ev["camera"] .. " at " .. ev["start_time"])
    end
end
```

### Check if a specific camera has recent activity

```berry
import HTTP
import json
import TIMER

TIMER.every(30000, def ()
    var h = HTTP.open("http://192.168.1.100:5000/api/events?cameras=front_door&limit=1&min_score=0.7", "GET", 2048, false)
    HTTP.perform()
    var resp = HTTP.getResponse()
    HTTP.close()

    var events = json.load(resp)
    if events && events.size() > 0
        var ev = events[0]
        if !ev["end_time"]
            print("Active detection: " .. ev["label"])
        end
    end
end)
```

## Frigate MQTT Topics Reference

| Topic | Description |
|-------|-------------|
| `frigate/events` | All detection events (new, update, end) |
| `frigate/available` | Frigate online status (`online`/`offline`) |
| `frigate/{camera}/person` | Person count on specific camera |
| `frigate/{camera}/car` | Car count on specific camera |
| `frigate/{camera}/dog` | Dog count on specific camera |
| `frigate/{camera}/cat` | Cat count on specific camera |
| `frigate/{camera}/motion` | Motion state (`ON`/`OFF`) |

### Event payload structure

```json
{
  "type": "new",
  "after": {
    "id": "1234567.abc",
    "camera": "front_door",
    "label": "person",
    "score": 0.87,
    "current_zones": ["porch"],
    "start_time": 1234567890.123
  }
}
```

Event types: `new` (detection started), `update` (still active), `end` (detection ended).

## Frigate REST API Quick Reference

| Action | Method | URL |
|--------|--------|-----|
| Recent events | GET | `/api/events?limit=N` |
| Events by camera | GET | `/api/events?cameras=NAME` |
| Events by label | GET | `/api/events?labels=person` |
| System stats | GET | `/api/stats` |
| Retain event | POST | `/api/events/{id}/retain` |
| Delete event | DELETE | `/api/events/{id}` |

## Notes

- **MQTT is the recommended approach** — events arrive in real-time with no polling delay
- Frigate runs on port `5000` by default (HTTP API) and connects to your MQTT broker
- Detection labels include: `person`, `car`, `dog`, `cat`, `bird`, `bicycle`, `motorcycle`, and more
- The `score` field (0.0–1.0) indicates detection confidence — filter by `min_score` to reduce false positives
- Frigate is free and open-source — [frigate.video](https://frigate.video/)
- For bidirectional communication, Frigate can also call SLZB's [WEBSERVER](webserver.md) webhook via its notification system
