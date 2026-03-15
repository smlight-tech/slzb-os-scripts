# Node-RED Integration

Connect SLZB to [Node-RED](https://nodered.org/) — trigger flows from Zigbee events, sensors, buttons, or schedules.

> This integration uses the [WEBHOOK](webhook.md) module. No separate module needed — Node-RED flows are triggered via HTTP-in nodes.

## Setup

### 1. Create an HTTP endpoint in Node-RED

1. Open your Node-RED editor (usually `http://nodered:1880`)
2. Drag an **http in** node onto the canvas
3. Set method to **POST** and URL to something like `/slzb/motion`
4. Connect it to your flow logic
5. Add an **http response** node at the end (returns 200 OK)

### 2. Configure in SLZB

#### Option A — Named webhook via UI (recommended)

1. Go to **Scripts Integrations** → **WEBHOOK**
2. Add a device:
   - **Name**: `Node-RED Motion`
   - **URL**: `http://192.168.1.100:1880/slzb/motion`
   - **Headers**: `{"Content-Type": "application/json"}`
3. Enable and save

Then in your script:
```berry
import WEBHOOK
WEBHOOK.post("Node-RED Motion", '{"room": "kitchen"}')
```

#### Option B — Direct URL in script

```berry
import WEBHOOK
WEBHOOK.post("http://192.168.1.100:1880/slzb/motion", '{"room": "kitchen"}')
```

## Examples

### Zigbee button triggers Node-RED flow

A button press triggers a Node-RED flow that can do anything — send notifications, control devices, query databases, call APIs.

```berry
import WEBHOOK
import ZHB

ZHB.waitForStart(0xff)
ZHB.on_action(def (action, dev)
    if dev.getName() == "Desk Button"
        WEBHOOK.post("Node-RED Button", '{"device": "Desk Button", "action": "' .. action .. '"}')
    end
end, 30000)
```

### Forward all Zigbee actions to Node-RED

Let Node-RED handle all the automation logic — SLZB just forwards events.

```berry
import WEBHOOK
import ZHB

ZHB.waitForStart(0xff)
ZHB.on_action(def (action, dev)
    var body = '{"device": "' .. dev.getName() .. '", "action": "' .. action .. '"}'
    WEBHOOK.post("http://192.168.1.100:1880/slzb/action", body)
end, 300000)
```

### Send sensor data for Node-RED dashboards

Node-RED has built-in dashboard nodes — feed Zigbee sensor data into charts and gauges.

```berry
import WEBHOOK
import ZHB
import TIMER

ZHB.waitForStart(0xff)
var sensor = ZHB.getDevice("Living Room Sensor")

TIMER.setInterval(def()
    var temp = sensor.getTemperature()
    var hum = sensor.getHumidity()
    WEBHOOK.post("Node-RED Sensors", '{"temperature": ' .. str(temp) .. ', "humidity": ' .. str(hum) .. ', "room": "living_room"}')
end)
```

### Door sensor alert via Node-RED

Node-RED flow checks time of day, sends different notifications for day vs night.

```berry
import WEBHOOK
import ZHB

ZHB.waitForStart(0xff)
ZHB.on_action(def (action, dev)
    if dev.getName() == "Front Door" && action == "contact"
        WEBHOOK.post("Node-RED Door", '{"door": "front", "state": "open"}')
    end
end)
```

### Zigbee network monitoring

Send periodic Zigbee network stats for Node-RED to graph over time.

```berry
import WEBHOOK
import ZB
import SLZB
import TIMER

TIMER.setInterval(def()
    var body = '{"clients": ' .. str(ZB.getZbClients()) .. ', "free_heap": ' .. str(SLZB.freeHeap()) .. '}'
    WEBHOOK.post("Node-RED Stats", body)
end)
```

### Bidirectional: Node-RED controls SLZB

Node-RED can also send commands back to SLZB using the [WEBSERVER](webserver.md) module.

**SLZB script (receives commands):**
```berry
import WEBSERVER
import ZHB

ZHB.waitForStart(0xff)
var relay = ZHB.getDevice("Kitchen Relay")

WEBSERVER.on_webhook(def (args)
    if WEBSERVER.hasArg("cmd")
        var cmd = WEBSERVER.getArg("cmd")
        if cmd == "relay_on"
            relay.sendOnOff(1)
        elif cmd == "relay_off"
            relay.sendOnOff(0)
        end
    end
    WEBSERVER.send(200, "OK")
end)
```

**Node-RED http request node:**
- Method: POST
- URL: `http://slzb-ip/webhook?cmd=relay_on`

## Why use Node-RED with SLZB?

SLZB handles real-time Zigbee events and local control. Node-RED extends this with:

- **Visual flow programming** — drag-and-drop automation logic
- **Dashboard nodes** — build real-time web dashboards for sensor data
- **2500+ community nodes** — databases, APIs, protocols, services
- **Conditional logic** — time-based, state-based, complex branching
- **MQTT integration** — Node-RED has native MQTT support (also available via [MQTT](mqtt.md) module)
- **Self-hosted** — runs on Raspberry Pi, NAS, Docker, or any server

## Alternative: MQTT instead of HTTP

If you already run an MQTT broker, you can use [MQTT](mqtt.md) for communication instead of HTTP webhooks. Many Node-RED users prefer MQTT for real-time event streams:

```berry
import MQTT
MQTT.waitConnect(0xff)
MQTT.publish("slzb/sensor/temperature", str(23.5))
```

Node-RED subscribes to `slzb/#` and processes all events.

## Notes

- Node-RED HTTP-in nodes run on port `1880` by default
- No authentication by default — add auth via Node-RED settings or a reverse proxy if exposed to the internet
- For real-time streaming, consider [MQTT](mqtt.md) instead of polling with webhooks
- For bidirectional communication (Node-RED → SLZB), use the [WEBSERVER](webserver.md) module
- Node-RED is free and open-source — [nodered.org](https://nodered.org/)
- Runs on Raspberry Pi, Docker, any Linux server, or as a cloud service
