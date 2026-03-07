#META {"start":1}
# Read temperature from a Zigbee sensor and publish to MQTT every 60 seconds
# Requires: MQTT enabled in web interface, a paired temperature sensor

import MQTT
import ZHB

ZHB.waitForStart(0xff)
MQTT.waitConnect(0xff)

var sensor = ZHB.getDevice("Temperature Sensor") # change to your device name

while true
  var temp = sensor.getVal(1, 0x0402, 0) # cluster 0x0402 = Temperature

  if temp != nil
    MQTT.publish("temperature", str(temp))
    SLZB.log("Published temperature: " .. temp)
  else
    SLZB.log("No temperature data yet")
  end

  SLZB.delay(60000) # every 60 seconds
end
