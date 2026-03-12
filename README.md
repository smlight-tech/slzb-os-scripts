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
Watch your Zigbee network and send notifications via Telegram, Discord, email, or any messaging service.

```berry
import TELEGRAM
TELEGRAM.send("Zigbee coordinator is online!")
```

```berry
import MQTT
MQTT.waitConnect(0xff)
MQTT.publish("alerts", "Sensor triggered!")
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
| [IR Transmitter](docs/modules/ir_transmitter.md) | Send infrared commands to TVs, ACs, and other IR devices | v3.2.5.dev1 | Ultima |
| [IR Receiver](docs/modules/ir_receiver.md) | Receive IR signals from remote controls, learn and replay codes | v3.2.5.dev1 | Ultima |
| [SSE](docs/modules/sse.md) | Server-Sent Events for real-time push to browsers | v3.2.5.dev1 | All |
| [TIMER](docs/modules/timer.md) | Repeating and one-shot timers | v3.2.5.dev1 | All |

### Integrations

Modules for connecting to external services. Configure credentials via the **Scripts Integrations** UI page or directly in scripts.

| Module | Description |
|--------|-------------|
| [TELEGRAM](docs/modules/telegram.md) | Send and receive Telegram messages via Bot |
| [WHATSAPP](docs/modules/whatsapp.md) | Send WhatsApp messages via CallMeBot |
| [TEAMS](docs/modules/teams.md) | Send notifications to Microsoft Teams via webhook |
| [SLACK](docs/modules/slack.md) | Send messages to Slack channels via webhook |
| [DISCORD](docs/modules/discord.md) | Send notifications to Discord via webhook |
| [PUSHOVER](docs/modules/pushover.md) | Push notifications with priority levels and sounds |
| [NTFY](docs/modules/ntfy.md) | Push notifications via ntfy.sh |
| [EMAIL](docs/modules/email.md) | Send email alerts via SMTP |
| [HA](docs/modules/ha.md) | Call Home Assistant services and read entity states |
| [IFTTT](docs/modules/ifttt.md) | Trigger IFTTT applets via webhooks |
| [OPENWRT](docs/modules/openwrt.md) | OpenWrt router — presence detection, clients, system info |
| [WOL](docs/modules/wol.md) | Wake-on-LAN — wake computers and devices on your network |
| [HUE](docs/modules/hue.md) | Control Philips Hue lights via Bridge v1 API |
| [WLED](docs/modules/wled.md) | Control WLED-powered LED strips |
| [SLWF03](docs/modules/slwf03.md) | SMLIGHT SLWF-03 Sound WLED controller (WLED alias) |
| [SLWF09](docs/modules/slwf09.md) | SMLIGHT SLWF-09 ETH POE WLED controller (WLED alias) |
| [ESPHOME](docs/modules/esphome.md) | Control any ESPHome device via REST API |
| [SLWF01](docs/modules/slwf01.md) | SMLIGHT SLWF-01 A/C Controller (ESPHome alias) |
| [SLWF08](docs/modules/slwf08.md) | SMLIGHT SLWF-08 HDMI-CEC controller (ESPHome alias) |
| [WEATHER](docs/modules/weather.md) | Get weather forecasts from OpenWeatherMap |
| [AIRQUALITY](docs/modules/airquality.md) | Get air quality index and pollutant data |
| [SUN](docs/modules/sun.md) | Get sunrise and sunset times (no API key needed) |
| [GSHEETS](docs/modules/gsheets.md) | Log data to Google Sheets via Apps Script |
| [INFLUXDB](docs/modules/influxdb.md) | Write time-series data to InfluxDB v2 for Grafana |
| [WEBHOOK](docs/modules/webhook.md) | Generic HTTP client — connect any REST API |

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
| [reboot_at_3am.be](examples/time/reboot_at_3am.be) | Reboot device daily at 3:00 AM | TIME |
| [log_datetime.be](examples/time/log_datetime.be) | Log current date and time | TIME |
| [alarm.be](examples/time/alarm.be) | Gentle wake-up alarm with gradual LED brightness and buzzer melodies | TIME, AMBILIGHT, BUZZER |
| [blink_led.be](examples/gpio/blink_led.be) | Blink an LED on/off every second | GPIO |
| [read_analog.be](examples/gpio/read_analog.be) | Read voltage on an analog pin | GPIO |
| [mqtt_subscribe.be](examples/mqtt/mqtt_subscribe.be) | Subscribe to MQTT topic and log messages | MQTT |
| [mqtt_publish_temperature.be](examples/mqtt/mqtt_publish_temperature.be) | Publish Zigbee sensor temperature to MQTT | MQTT, ZHB |
| [play_melody.be](examples/buzzer/play_melody.be) | Play an RTTTL melody on the buzzer | BUZZER |
| [doorbell.be](examples/buzzer/doorbell.be) | Zigbee button triggers a doorbell sound | BUZZER, ZHB |
| [button_toggle_relay.be](examples/button/button_toggle_relay.be) | Physical button toggles a Zigbee relay | BUTTON, ZHB |
| [effects_demo.be](examples/ambilight/effects_demo.be) | Cycle through all LED effects | AMBILIGHT |
| [color_cycle_on_button.be](examples/ambilight/color_cycle_on_button.be) | Zigbee button cycles LED colors | AMBILIGHT, ZHB |
| [send_nec_command.be](examples/ir_transmitter/send_nec_command.be) | Send an NEC IR command | IR |
| [zigbee_button_sends_ir.be](examples/ir_transmitter/zigbee_button_sends_ir.be) | Zigbee button sends IR commands to TV | IR, ZHB |
| [log_ir_codes.be](examples/ir_receiver/log_ir_codes.be) | Log all received IR codes (discovery tool) | IR |
| [ir_to_zigbee_bridge.be](examples/ir_receiver/ir_to_zigbee_bridge.be) | Control Zigbee devices with an IR remote | IR, ZHB |

Community examples:
- [Scheduled socket management](https://github.com/Tarik2142/slzb-outage-commander/blob/main/commander.be) — ZHB + TIME
- [Stream mode HTML parser](https://github.com/Tarik2142/slzb-outage-commander/blob/main/parser.be) — HTTP stream mode

---

## AI-Assisted Scripting

Use **[AI_PROMPT.md](AI_PROMPT.md)** as a context file for AI agents (ChatGPT, Claude, etc.) when writing Berry scripts. It contains a compact summary of all modules, script rules, and quick-reference patterns — designed so the AI reads only the detailed docs it needs for your specific task.

---

## Ukrainian Documentation

A Ukrainian version of the base documentation is available in [README_UA.md](README_UA.md).
Note: It covers only the core modules (SLZB, ZB, WEBSERVER, FS). For the full and up-to-date reference, please use the English documentation above.
