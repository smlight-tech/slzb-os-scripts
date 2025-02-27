**This script requires SLZB-OS version v2.8.2.dev1 or higher**<br>
This can be useful for detecting devices spamming your ZigBee network.
This script keeps statistics on the number of reports from your zigbee devices.
The device logs statistics every 8 packets, and it also makes them available at ```<device ip>/script/webhook``` URL

For faster calculation, the logical operator ```&``` is used instead of the remainder from division ```%``` so ```step``` should be calculated using the formula ```(2 ^ step) - 1```
Here's how the condition for the remainder of division would change: ```if !(actualCount % step)``` In this case, you can use any ```step``` instead of the power of 2 but the calculation will take longer.

For the list of devices, ```map``` is used [https://berry.readthedocs.io/en/latest/source/en/Chapter-7.html#map-class](https://berry.readthedocs.io/en/latest/source/en/Chapter-7.html#map-class)

```json``` module is used to serialize the variable to JSON [https://berry.readthedocs.io/en/latest/source/en/Chapter-7.html#json-module](https://berry.readthedocs.io/en/latest/source/en/Chapter-7.html#json-module)

If you want to know more about zigbee chip commands please check: [(for CC2652x) Z-Stack Monitor and Test API](https://github.com/Koenkk/zigbee-herdsman/blob/master/docs/Z-Stack%20Monitor%20and%20Test%20API.pdf) | [(for EFR32) EZSP Reference Guide](https://www.silabs.com/documents/public/user-guides/ug100-ezsp-reference-guide.pdf)

## WARNING: you should not use any delays in socket, web server or any other event handlers as this will slow down the device.