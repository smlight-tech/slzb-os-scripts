# Jeedom Integration

Connect SLZB to [Jeedom](https://www.jeedom.com/) — execute commands, read info, and trigger scenarios from Zigbee events.

> This integration uses the [WEBHOOK](webhook.md) module or [HTTP](http.md) module directly. No separate module needed — Jeedom uses simple GET requests with an API key.

## Setup

### Get your Jeedom API key

1. Open Jeedom → **Settings** → **System** → **Configuration**
2. Go to **API** tab
3. Copy your **API key**

## Examples

### Execute a command

In Jeedom, every action is a **command** identified by its `id` (visible in the command configuration).

```berry
import HTTP

var host = "http://192.168.1.100"
var api_key = "YOUR_API_KEY"

def jd_cmd(cmd_id)
    var url = host .. "/core/api/jeeApi.php?apikey=" .. api_key .. "&type=cmd&id=" .. str(cmd_id)
    var h = HTTP.open(url, "GET", 1024, false)
    HTTP.perform()
    HTTP.close()
end

jd_cmd(42)  # execute command #42 (e.g. turn on a light)
jd_cmd(43)  # execute command #43 (e.g. turn off)
```

### Execute a command with value

```berry
import HTTP

var host = "http://192.168.1.100"
var api_key = "YOUR_API_KEY"

def jd_cmd_value(cmd_id, value)
    var url = host .. "/core/api/jeeApi.php?apikey=" .. api_key .. "&type=cmd&id=" .. str(cmd_id) .. "&slider=" .. str(value)
    var h = HTTP.open(url, "GET", 1024, false)
    HTTP.perform()
    HTTP.close()
end

jd_cmd_value(44, 50)  # set dimmer to 50%
jd_cmd_value(45, 22)  # set thermostat to 22°C
```

### Read a command value (info)

```berry
import HTTP
import json

var host = "http://192.168.1.100"
var api_key = "YOUR_API_KEY"

def jd_get_value(cmd_id)
    var url = host .. "/core/api/jeeApi.php?apikey=" .. api_key .. "&type=cmd&id=" .. str(cmd_id)
    var h = HTTP.open(url, "GET", 1024, false)
    HTTP.perform()
    var resp = HTTP.getResponse()
    HTTP.close()
    return resp
end

var temp = jd_get_value(50)
print("Temperature: " .. temp)
```

### Zigbee button controls Jeedom

```berry
import HTTP
import ZHB

var host = "http://192.168.1.100"
var api_key = "YOUR_API_KEY"

def jd_cmd(cmd_id)
    var url = host .. "/core/api/jeeApi.php?apikey=" .. api_key .. "&type=cmd&id=" .. str(cmd_id)
    var h = HTTP.open(url, "GET", 1024, false)
    HTTP.perform()
    HTTP.close()
end

ZHB.waitForStart(0xff)
ZHB.on_action(def (action, dev)
    if dev.getName() == "Wall Switch"
        if action == "single"
            jd_cmd(42)  # toggle light
        elif action == "double"
            jd_cmd(60)  # activate scene
        end
    end
end, 60000)
```

### Trigger a scenario

```berry
import HTTP

var host = "http://192.168.1.100"
var api_key = "YOUR_API_KEY"

def jd_scenario(scenario_id, action)
    var url = host .. "/core/api/jeeApi.php?apikey=" .. api_key .. "&type=scenario&id=" .. str(scenario_id) .. "&action=" .. action
    var h = HTTP.open(url, "GET", 1024, false)
    HTTP.perform()
    HTTP.close()
end

jd_scenario(1, "start")  # start scenario #1
jd_scenario(1, "stop")   # stop it
```

### Push Zigbee sensor data to Jeedom virtual

```berry
import HTTP
import ZHB
import TIMER

var host = "http://192.168.1.100"
var api_key = "YOUR_API_KEY"

def jd_set_virtual(cmd_id, value)
    var url = host .. "/core/api/jeeApi.php?apikey=" .. api_key .. "&type=virtual&id=" .. str(cmd_id) .. "&value=" .. str(value)
    var h = HTTP.open(url, "GET", 1024, false)
    HTTP.perform()
    HTTP.close()
end

ZHB.waitForStart(0xff)
var sensor = ZHB.getDevice("Kitchen Sensor")

TIMER.setInterval(def()
    jd_set_virtual(100, sensor.getTemperature())
    jd_set_virtual(101, sensor.getHumidity())
end)
```

## Jeedom API Quick Reference

| Action | URL |
|--------|-----|
| Execute command | `/core/api/jeeApi.php?apikey=KEY&type=cmd&id=N` |
| Command with value | `/core/api/jeeApi.php?apikey=KEY&type=cmd&id=N&slider=VALUE` |
| Read info command | `/core/api/jeeApi.php?apikey=KEY&type=cmd&id=N` (GET returns value) |
| Start scenario | `/core/api/jeeApi.php?apikey=KEY&type=scenario&id=N&action=start` |
| Stop scenario | `/core/api/jeeApi.php?apikey=KEY&type=scenario&id=N&action=stop` |
| Update virtual | `/core/api/jeeApi.php?apikey=KEY&type=virtual&id=N&value=VALUE` |
| Get equipment | `/core/api/jeeApi.php?apikey=KEY&type=eqLogic&object_id=N` |

## Notes

- Jeedom API uses simple GET requests with the API key as a query parameter
- All commands and info are identified by their `id` (find in **Analysis → Equipment → Command configuration**)
- Default HTTP port is `80` (or `443` for HTTPS)
- The API key provides full access — keep it secure
- For bidirectional communication (Jeedom → SLZB), use Jeedom's **Script** plugin or **HTTP Request** action to call [WEBSERVER](webserver.md)
- [Jeedom API documentation](https://doc.jeedom.com/en_US/core/4.4/api_http)
