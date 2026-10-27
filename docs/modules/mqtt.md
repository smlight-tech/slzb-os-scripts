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
| `MQTT.getState() -> int` | Current broker connection state, one of the `MQTT.STATE_*` constants. |
| `MQTT.on_state_change(callback:function(state:int) -> nil) -> nil` | Register a callback fired on every change of the broker connection state (`MQTT.STATE_*`). |
| `MQTT.subscribe(topic:string) -> bool` | Subscribe to `<base_topic>/<topic>`. Use `#` to subscribe to all subtopics. |
| `MQTT.subscribeCustom(topic:string) -> bool` | Subscribe to a topic as given (no base topic prefix). MQTT wildcards work: `homeassistant/#`, `plug/+/state`. |
| `MQTT.publish(topic:string, payload:string) -> bool` | Publish a message to `<base_topic>/<topic>`. |
| `MQTT.publishCustom(topic:string, payload:string) -> bool` | Publish to a topic as given (no base topic prefix, no leading `/` added). |
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

### Subscribe again after a reconnect

The device connects to the broker with a clean session: after a lost connection the broker forgets the subscriptions of the scripts. Subscribe in `on_state_change` to keep them:

```berry
import MQTT

def subscribeAll()
  MQTT.subscribe("my_test_topic")
  MQTT.subscribeCustom("homeassistant/status")
end

MQTT.on_state_change(def (state)
  if state == MQTT.STATE_CONNECTED
    subscribeAll()
  elif state == MQTT.STATE_DISCONNECTED
    SLZB.log("MQTT connection lost")
  end
end)

if MQTT.getState() == MQTT.STATE_CONNECTED  # connected before the callback was registered
  subscribeAll()
end
```

## Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `MQTT.STATE_DISABLED` | 0 | MQTT is switched off in the settings |
| `MQTT.STATE_DISCONNECTED` | 1 | Not connected to the broker (yet, or any more): the device keeps trying to connect |
| `MQTT.STATE_CONNECTED` | 2 | Connected to the broker |

## Notes

- `subscribe()` / `subscribeCustom()` return `false` and subscribe nothing when the device is not connected to the broker
- Subscriptions are not restored after a lost connection: the broker forgets them (clean session). Subscribe again in `on_state_change` on `MQTT.STATE_CONNECTED` (`getState()`, `on_state_change`: since v3.4.3.dev2)
- `on_state_change` is called only on a change: a script started while the device is already connected gets no `STATE_CONNECTED` — check `getState()` at the start. A connection lost and made again within a moment gives `STATE_DISCONNECTED` and then `STATE_CONNECTED`
- `on_message` gets every message under `<base_topic>/` the device receives (also the topics the firmware subscribes to itself, such as the Zigbee Hub `cmd` / `write` topics) and the messages of the topics subscribed with `subscribeCustom()`. Before v3.4.3.dev2 messages of `subscribeCustom()` topics did not reach `on_message`
- Subscriptions are not removed when the script stops: they stay until the connection to the broker is lost
- A message with an empty payload does not reach `on_message`

## See Also

- [ZHB — Zigbee Hub](zhb.md) — Combine with MQTT to publish Zigbee device state
- [WEBSERVER — Webhooks](webserver.md) — Alternative: HTTP-based communication
- [HTTP — HTTP Client](http.md) — Alternative: send data via HTTP requests
- [Example: Subscribe and log](../../examples/mqtt/mqtt_subscribe.be)
- [Example: Publish temperature](../../examples/mqtt/mqtt_publish_temperature.be)
