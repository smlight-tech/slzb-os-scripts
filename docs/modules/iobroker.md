# ioBroker Integration

Connect SLZB to [ioBroker](https://www.iobroker.net/) — read and set states, control devices, and trigger scripts from Zigbee events.

> This integration uses the [HTTP](http.md) module directly. No separate module needed — ioBroker's Simple API adapter provides plain HTTP endpoints.

## Setup

### 1. Install the Simple API adapter in ioBroker

1. Open ioBroker admin panel
2. Go to **Adapters**
3. Install **Simple API** (`simple-api`)
4. Configure it — default port is `8087`
5. (Optional) Enable authentication if needed

### 2. Use in SLZB scripts

```berry
import HTTP

var host = "http://192.168.1.100:8087"

# Set a state
var h = HTTP.open(host .. "/set/javascript.0.myState?value=true", "GET", 1024, false)
HTTP.perform()
HTTP.close()
```

## Examples

### Set a state value

```berry
import HTTP

var host = "http://192.168.1.100:8087"

def iob_set(state_id, value)
    var url = host .. "/set/" .. state_id .. "?value=" .. str(value)
    var h = HTTP.open(url, "GET", 1024, false)
    HTTP.perform()
    HTTP.close()
end

iob_set("hm-rpc.0.ABC123.1.STATE", "true")
iob_set("deconz.0.lights.1.bri", "200")
iob_set("javascript.0.myVariable", "hello")
```

### Read a state value

```berry
import HTTP
import json

var host = "http://192.168.1.100:8087"

def iob_get(state_id)
    var url = host .. "/get/" .. state_id
    var h = HTTP.open(url, "GET", 2048, false)
    HTTP.perform()
    var resp = HTTP.getResponse()
    HTTP.close()
    var data = json.load(resp)
    if data
        return data["val"]
    end
    return nil
end

var temp = iob_get("hm-rpc.0.ABC123.1.TEMPERATURE")
print("Temperature: " .. str(temp))
```

### Zigbee button controls ioBroker device

```berry
import HTTP
import ZHB

var host = "http://192.168.1.100:8087"

def iob_set(state_id, value)
    var url = host .. "/set/" .. state_id .. "?value=" .. str(value)
    var h = HTTP.open(url, "GET", 1024, false)
    HTTP.perform()
    HTTP.close()
end

ZHB.waitForStart(0xff)
ZHB.on_action(def (action, dev)
    if dev.getName() == "Wall Switch"
        if action == "single"
            iob_set("hm-rpc.0.ABC123.1.STATE", "true")
        elif action == "double"
            iob_set("hm-rpc.0.ABC123.1.STATE", "false")
        end
    end
end, 60000)
```

### Toggle a state

```berry
import HTTP
import json

var host = "http://192.168.1.100:8087"

def iob_toggle(state_id)
    var url = host .. "/toggle/" .. state_id
    var h = HTTP.open(url, "GET", 1024, false)
    HTTP.perform()
    HTTP.close()
end

iob_toggle("hm-rpc.0.ABC123.1.STATE")
```

### Push Zigbee sensor data to ioBroker

```berry
import HTTP
import ZHB
import TIMER

var host = "http://192.168.1.100:8087"

def iob_set(state_id, value)
    var url = host .. "/set/" .. state_id .. "?value=" .. str(value)
    var h = HTTP.open(url, "GET", 1024, false)
    HTTP.perform()
    HTTP.close()
end

ZHB.waitForStart(0xff)
var sensor = ZHB.getDevice("Living Room Sensor")

TIMER.setInterval(def()
    iob_set("javascript.0.zigbee_temp", sensor.getTemperature())
    iob_set("javascript.0.zigbee_humidity", sensor.getHumidity())
end, 300000)
```

### Read ioBroker sensor and react locally

```berry
import HTTP
import ZHB
import TIMER
import json

var host = "http://192.168.1.100:8087"

def iob_get(state_id)
    var url = host .. "/get/" .. state_id
    var h = HTTP.open(url, "GET", 2048, false)
    HTTP.perform()
    var resp = HTTP.getResponse()
    HTTP.close()
    var data = json.load(resp)
    if data
        return data["val"]
    end
    return nil
end

ZHB.waitForStart(0xff)
var relay = ZHB.getDevice("Heater Relay")

TIMER.setInterval(def()
    var target = iob_get("javascript.0.target_temp")
    var current = iob_get("hm-rpc.0.ABC123.1.TEMPERATURE")
    if target && current
        if current < target
            relay.sendOnOff(1)
        else
            relay.sendOnOff(0)
        end
    end
end)
```

## ioBroker Simple API Quick Reference

| Action | URL |
|--------|-----|
| Get state | `GET /get/STATE_ID` |
| Set state | `GET /set/STATE_ID?value=VALUE` |
| Toggle | `GET /toggle/STATE_ID` |
| Get plain value | `GET /getPlainValue/STATE_ID` |
| Get all states | `GET /getAll` |
| Get objects | `GET /objects?pattern=PATTERN` |

## Notes

- Requires the **Simple API** adapter (`simple-api`) installed in ioBroker
- Default port is `8087`
- All requests are simple GET — no special headers or content types
- State IDs follow ioBroker's namespace format (e.g. `hm-rpc.0.ABC123.1.STATE`)
- If authentication is enabled in the adapter, add `?user=USER&pass=PASS` to the URL
- For bidirectional communication (ioBroker → SLZB), use ioBroker's **request** adapter or JavaScript adapter to call [WEBSERVER](webserver.md)
- ioBroker is free and open-source — [iobroker.net](https://www.iobroker.net/)
