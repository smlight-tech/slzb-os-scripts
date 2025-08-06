**This scripts requires SLZB-OS version v2.8.6 or higher**<br>
**These scripts are for zigbee hub mode**<br>

# simple_thermostat.be
Berry implementation of a simple thermostat for heating or cooling using data from a ZigBee temperature sensor and a ZigBee relay as a switching device.<br>
**chkInterval** - defines the pause between checks. It is not recommended to specify less than 10ms.<br>
**hysteresis** - chkInterval - defines the temperature difference to activate heating/cooling.<br>
**heating** - defines thermostat mode. true - heating, false - cooling.<br>