# MQTT — Messaging

> Available since: v3.2.4

Subscribe to MQTT topics and publish messages through your device's MQTT broker connection.

**Prerequisite:** Enable MQTT in the coordinator web interface before using this module.

## Quick Example

```berry
import MQTT

MQTT.waitConnect(0xff)
MQTT.subscribe("my_topic")

def handler(topic, data)
  SLZB.log("Received: " .. data .. " on " .. topic)
end

MQTT.on_message(handler)
MQTT.publish("status", "online")
```

## API Reference

| Function | Description |
|----------|-------------|
| `MQTT.waitConnect(timeout:int) -> bool` | Wait for broker connection. 1–254 seconds, `255` = wait forever. |
| `MQTT.isConnected() -> bool` | Check if connected to the MQTT broker. |
| `MQTT.subscribe(topic:string) -> bool` | Subscribe to `<base_topic>/<topic>`. Use `#` to subscribe to all subtopics. |
| `MQTT.subscribeCustom(topic:string) -> bool` | Subscribe to an exact topic (no base topic prefix). Use `/#` for all subtopics. |
| `MQTT.publish(topic:string, payload:string) -> bool` | Publish a message to `<base_topic>/<topic>`. |
| `MQTT.publishCustom(topic:string, payload:string) -> bool` | Publish to an exact `/<topic>` (no base topic prefix). |
| `MQTT.on_message(callback:function(topic:string, data:string) -> nil) -> nil` | Register a handler for incoming messages. |

**Note:** `<base_topic>` is configured on the MQTT settings page of your device's web interface.

### Topic examples

```berry
# Subscribe to a single topic
MQTT.subscribe("my_test_topic")       # subscribes to '<base_topic>/my_test_topic'

# Subscribe to all subtopics
MQTT.subscribe("#")                   # subscribes to all '<base_topic>/...' topics

# Subscribe to a custom topic (no base prefix)
MQTT.subscribeCustom("homeassistant/status")

# Publish
MQTT.publish("status", "hello!")      # publishes to '<base_topic>/status'
```

## See Also

- [ZHB — Zigbee Hub](zhb.md) — Combine with MQTT to publish Zigbee device state
- [WEBSERVER — Webhooks](webserver.md) — Alternative: HTTP-based communication
- [HTTP — HTTP Client](http.md) — Alternative: send data via HTTP requests
- [Example: Subscribe and log](../../examples/mqtt/mqtt_subscribe.be)
- [Example: Publish temperature](../../examples/mqtt/mqtt_publish_temperature.be)
