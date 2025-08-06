#META {"start":0}
import ZHB
# how often the script will check the received temperature
# 200 ms is sufficient for most cases
var chkInterval = 200

var tempSensorIeee = "0x00158d008b852609"
var relayIeee = "0xa4c1383439bf5cc9"

var targetTemperature = 26
var hysteresis = 2 # +- 2 deg
var heating = true # heating or cooling selector
var relayState = false

# ZHB.getDevice("some name") # to get device by name
var tempSensor = ZHB.getDevice(tempSensorIeee)
var relay = ZHB.getDevice(relayIeee)

def handleHeating(temp)
  if (relayState && (temp >= targetTemperature))
    relay.sendOnOff(0)
    relayState = false

    SLZB.log("Heater off")

  elif (!relayState && temp <= (targetTemperature - hysteresis))
    relay.sendOnOff(1)
    relayState = true

    SLZB.log("Heater on")
  end
end

def handleCooling(temp)
  if (relayState && temp <= targetTemperature)
    relay.sendOnOff(0)
    relayState = false

    SLZB.log("Cooler off")

  elif (!relayState && temp >= (targetTemperature + hysteresis))
    relay.sendOnOff(1)
    relayState = true

    SLZB.log("Cooler on")
  end
end

if (tempSensor && relay)
  relay.sendOnOff(0) # assert relay to off at start

  while true
    var temperature = tempSensor.getVal(1, 0x0402, 0)
    
    if (temperature != nil)
      if (heating)
        handleHeating(temperature)
      else
        handleCooling(temperature)
      end
    else
      # put here what should we do if value is unknown?
    end

    SLZB.delay(chkInterval)
  end
else
  SLZB.log("Failed to get device!")
end