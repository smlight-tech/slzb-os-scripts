# SLZB-OS Berry Scripting

SLZB-OS is the operating system for [SLZB-06x, SLZB-MRx, and U-series](https://smlight.tech) Zigbee coordinators. It includes a built-in scripting engine powered by the [Berry language](https://berry-lang.github.io/) that lets you automate your smart home directly on the coordinator — no additional server or hub required.

This repository contains the full scripting API documentation and ready-to-use examples.

## What Can You Automate?

### Smart Home Control
Turn Zigbee relays, lamps, and other devices on and off from scripts — triggered by buttons, schedules, or sensor data.

```berry
import ZHB
ZHB.waitForStart(0xff)
var lamp = ZHB.getDevice("Living Room Lamp")
lamp.sendOnOff(1)       # turn on
lamp.sendBri(200)       # set brightness
lamp.sendColor("#ff8800")  # warm orange
```

### Button Automation
React to Zigbee button presses (single, double, long) to control any device.

```berry
import ZHB
ZHB.waitForStart(0xff)
var relay = ZHB.getDevice("Kitchen Relay")

def on_action(action, dev)
  if dev.getName() == "My Button" && action == "single"
    relay.sendOnOff(1)
  end
end
ZHB.on_action(on_action)
```

### Monitoring and Alerts
Watch your Zigbee network and send notifications via HTTP or MQTT when something happens.

```berry
import MQTT
MQTT.waitConnect(0xff)
MQTT.publish("alerts", "Zigbee coordinator is online!")
```

### Scheduling
Reboot the device daily, check sensors on an interval, or run actions at specific times.

```berry
import TIME
TIME.waitSync(0xff)
var t = TIME.getAll()
SLZB.log("Current time: " .. t["hour"] .. ":" .. t["min"])
```

### Hardware Control (Advanced)
Control GPIO pins, play melodies on the buzzer, drive LED strips, or send/receive IR commands on supported devices.

```berry
import GPIO
GPIO.pinMode(46, GPIO.MOD_OUTPUT)
GPIO.digitalWrite(46, 1)  # turn on LED
```

---

## Getting Started

New to Berry scripting on SLZB-OS? Start here:

**[Getting Started Guide](docs/getting-started.md)** — How scripts work, metadata, and the event system.

Berry language resources:
- [Berry in 20 minutes](https://berry.readthedocs.io/en/latest/source/en/Berry-in-20-minutes.html)
- [Berry documentation](https://berry.readthedocs.io/en/latest/)

---

## Module Reference

Each module is documented in its own file with API details, examples, and cross-references.

| Module | Description | Min Firmware | Devices |
|--------|-------------|:------------:|---------|
| [SLZB](docs/modules/slzb.md) | Core functions — delays, logging, reboot, device info | v2.8.0 | All |
| [ZB](docs/modules/zb.md) | Low-level Zigbee chip access — read/write bytes, socket control | v2.8.0 | All |
| [WEBSERVER](docs/modules/webserver.md) | Receive HTTP requests via webhook endpoint | v2.8.2.dev0 | All |
| [ZHB](docs/modules/zhb.md) | Zigbee Hub — control relays, lamps, sensors, buttons | v2.9.6 | All |
| [HTTP](docs/modules/http.md) | Make outgoing HTTP/HTTPS GET and POST requests | v2.9.8 | All |
| [TIME](docs/modules/time.md) | Date, time, and NTP synchronization | v3.0.6 | All |
| [FS](docs/modules/fs.md) | File system — read, check, delete files | v3.0.6 | All |
| [GPIO](docs/modules/gpio.md) | Direct GPIO pin control, PWM, frequency generation | v3.1.6.dev3 | All |
| [MQTT](docs/modules/mqtt.md) | Subscribe and publish MQTT messages | v3.2.4 | All |
| [BUZZER](docs/modules/buzzer.md) | Play melodies on the built-in buzzer | v3.2.5.dev1 | Ultima3 |
| [BUTTON](docs/modules/button.md) | Override physical button actions | v3.2.5.dev1 | All |
| [AMBILIGHT](docs/modules/ambilight.md) | WS2812B LED strip effects and colors | v3.2.5.dev1 | Ultima |
| [IR](docs/modules/ir.md) | Infrared send/receive with protocol support | v3.2.5.dev1 | Ultima |

---

## Guides

In-depth tutorials for common use cases:

| Guide | Description |
|-------|-------------|
| [Zigbee Button & Action Events](docs/guides/zigbee-button-actions.md) | Handle button clicks, rotary encoders, and multi-button remotes |

---

## Examples

Ready-to-use scripts in the [`examples/`](examples/) folder:

| Example | Description | Modules Used |
|---------|-------------|--------------|
| [reboot_every_day.be](examples/basic/reboot_every_day.be) | Reboot device every 24 hours | SLZB |
| [zb_reboot_on_drop.be](examples/basic/zb_reboot_on_drop.be) | Reboot Zigbee chip when all clients disconnect | ZB |
| [get_file_size.be](examples/basic/get_file_size.be) | Read and display file size | FS |
| [http_get.be](examples/http_client/http_get.be) | Fetch JSON from an API | HTTP |
| [http_post.be](examples/http_client/http_post.be) | Send JSON data via POST | HTTP |
| [report_stats.be](examples/report_stats/report_stats.be) | Track Zigbee device report counts, serve via webhook | ZB, WEBSERVER |
| [simple_thermostat.be](examples/zigbee_hub/simple_thermostat.be) | Thermostat using Zigbee sensor + relay | ZHB |

Community examples:
- [Scheduled socket management](https://github.com/Tarik2142/slzb-outage-commander/blob/main/commander.be) — ZHB + TIME
- [Stream mode HTML parser](https://github.com/Tarik2142/slzb-outage-commander/blob/main/parser.be) — HTTP stream mode

---

## Ukrainian Documentation

A Ukrainian version of the base documentation is available in [README_UA.md](README_UA.md).
Note: It covers only the core modules (SLZB, ZB, WEBSERVER, FS). For the full and up-to-date reference, please use the English documentation above.
