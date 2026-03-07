#META {"start":1}
# Subscribe to an MQTT topic and log incoming messages
# Make sure MQTT is enabled in the coordinator web interface

import MQTT

SLZB.log("Waiting for MQTT connection...")
MQTT.waitConnect(0xff)
SLZB.log("MQTT connected!")

MQTT.subscribe("commands")

def handler(topic, data)
  SLZB.log("Topic: " .. topic .. " Data: " .. data)
end

MQTT.on_message(handler)
