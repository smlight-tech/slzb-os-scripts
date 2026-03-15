# Domoticz Integration

Connect SLZB to [Domoticz](https://www.domoticz.com/) — control switches, read sensors, and trigger scenes from Zigbee events.

> This integration uses the [WEBHOOK](webhook.md) module or [HTTP](http.md) module directly. No separate module needed — Domoticz uses simple GET requests.

## Setup

Domoticz API requires no setup — just GET requests to your Domoticz IP. If you enabled authentication, use HTTP basic auth.

## Examples

### Turn on a switch

Domoticz uses device `idx` numbers (visible in **Setup → Devices**).

```berry
import HTTP

var host = "http://192.168.1.100:8080"

def dz_switch(idx, cmd)
    var url = host .. "/json.htm?type=command&param=switchlight&idx=" .. str(idx) .. "&switchcmd=" .. cmd
    var h = HTTP.open(url, "GET", 1024, false)
    HTTP.perform()
    HTTP.close()
end

dz_switch(1, "On")
dz_switch(1, "Off")
dz_switch(2, "Toggle")
```

### Set dimmer level

```berry
import HTTP

var host = "http://192.168.1.100:8080"

def dz_dimmer(idx, level)
    var url = host .. "/json.htm?type=command&param=switchlight&idx=" .. str(idx) .. "&switchcmd=Set%20Level&level=" .. str(level)
    var h = HTTP.open(url, "GET", 1024, false)
    HTTP.perform()
    HTTP.close()
end

dz_dimmer(3, 50)  # 50%
```

### Read sensor value

```berry
import HTTP
import json

var host = "http://192.168.1.100:8080"

def dz_get_device(idx)
    var url = host .. "/json.htm?type=devices&rid=" .. str(idx)
    var h = HTTP.open(url, "GET", 2048, false)
    HTTP.perform()
    var resp = HTTP.getResponse()
    HTTP.close()
    var data = json.load(resp)
    if data && data["result"]
        return data["result"][0]
    end
    return nil
end

var dev = dz_get_device(5)
if dev
    print("Name: " .. dev["Name"])
    print("Data: " .. dev["Data"])
end
```

### Zigbee button controls Domoticz

```berry
import HTTP
import ZHB

var host = "http://192.168.1.100:8080"

def dz_switch(idx, cmd)
    var url = host .. "/json.htm?type=command&param=switchlight&idx=" .. str(idx) .. "&switchcmd=" .. cmd
    var h = HTTP.open(url, "GET", 1024, false)
    HTTP.perform()
    HTTP.close()
end

ZHB.waitForStart(0xff)
ZHB.on_action(def (action, dev)
    if dev.getName() == "Wall Switch"
        if action == "single"
            dz_switch(1, "Toggle")
        elif action == "double"
            dz_switch(2, "Toggle")
        end
    end
end, 60000)
```

### Activate a scene

```berry
import HTTP

var host = "http://192.168.1.100:8080"

def dz_scene(idx, cmd)
    var url = host .. "/json.htm?type=command&param=switchscene&idx=" .. str(idx) .. "&switchcmd=" .. cmd
    var h = HTTP.open(url, "GET", 1024, false)
    HTTP.perform()
    HTTP.close()
end

dz_scene(1, "On")   # activate scene
dz_scene(1, "Off")  # deactivate group
```

### Push Zigbee sensor data to Domoticz

```berry
import HTTP
import ZHB
import TIMER

var host = "http://192.168.1.100:8080"

def dz_update_temp_hum(idx, temp, hum)
    var url = host .. "/json.htm?type=command&param=udevice&idx=" .. str(idx) .. "&nvalue=0&svalue=" .. str(temp) .. ";" .. str(hum) .. ";0"
    var h = HTTP.open(url, "GET", 1024, false)
    HTTP.perform()
    HTTP.close()
end

ZHB.waitForStart(0xff)
var sensor = ZHB.getDevice("Kitchen Sensor")

TIMER.setInterval(def()
    dz_update_temp_hum(10, sensor.getTemperature(), sensor.getHumidity())
end)
```

## Domoticz API Quick Reference

| Action | URL |
|--------|-----|
| Switch on/off | `/json.htm?type=command&param=switchlight&idx=N&switchcmd=On` |
| Set level | `/json.htm?type=command&param=switchlight&idx=N&switchcmd=Set%20Level&level=50` |
| Toggle | `/json.htm?type=command&param=switchlight&idx=N&switchcmd=Toggle` |
| Scene on | `/json.htm?type=command&param=switchscene&idx=N&switchcmd=On` |
| Get device | `/json.htm?type=devices&rid=N` |
| Get all devices | `/json.htm?type=devices` |
| Update sensor | `/json.htm?type=command&param=udevice&idx=N&nvalue=0&svalue=VALUE` |

## Notes

- Domoticz API uses simple GET requests — no special headers or content types
- All devices are identified by `idx` number (find in **Setup → Devices**)
- If authentication is enabled, add `&username=BASE64&password=BASE64` to the URL (base64-encoded)
- Default port is `8080`
- For bidirectional communication (Domoticz → SLZB), use Domoticz's dzVents scripting with HTTP requests to [WEBSERVER](webserver.md)
- [Domoticz API/JSON reference](https://www.domoticz.com/wiki/Domoticz_API/JSON_URL%27s)
