# SLZB-OS Berry Scripting — AI Agent Context

Use this file as a prompt for AI agents when writing Berry scripts for SLZB-OS devices. Copy this entire file into your prompt, then describe what you want to build. Optionally specify which modules you need — the agent will read only the relevant documentation files.

---

## What is this?

SLZB-OS is the operating system for SMLIGHT Zigbee coordinators (SLZB-06x, MRx, Ultima series). It supports user scripts written in [Berry](https://berry-lang.github.io/), a lightweight embedded scripting language. Scripts run directly on the device — no external server needed.

## Script rules

- Up to 3 scripts can run simultaneously.
- Every script must start with a metadata line: `#META {"start":1}` (auto-start) or `#META {"start":0}` (manual).
- The space after `#META` is required. The line must end with a newline.
- Optional metadata: `"stack":8192` (increase memory), `"psram":true` (U-series only, disables filesystem access).
- The `SLZB` module is auto-loaded. All others require `import`.
- Event callbacks must not use `SLZB.delay()`, must not contain infinite loops, and must return quickly.
- `SLZB.log()` crashes if text exceeds 1024 characters.
- All scripts share one HTTP client — only one script can use HTTP at a time.

## Available modules

Below is every module with a one-line summary. **Read the linked file only for modules you need.**

| Module | Description | Min Firmware | Devices | Documentation |
|--------|-------------|:------------:|---------|---------------|
| SLZB | Core: `delay()`, `log()`, `reboot()`, `millis()`, `freeHeap()`, `deviceModel()` | v2.8.0 | All | [docs/modules/slzb.md](docs/modules/slzb.md) |
| ZB | Low-level Zigbee chip: `reboot()`, `writeBytes()`, `readBytes()`, `suspend()`, socket events (`on_pkt`, `on_connect`, `on_disconnect`) | v2.8.0 | All | [docs/modules/zb.md](docs/modules/zb.md) |
| WEBSERVER | Incoming HTTP webhook at `<ip>/script/webhook`: `getArg()`, `hasArg()`, `send()`, `on_webhook` event | v2.8.2.dev0 | All | [docs/modules/webserver.md](docs/modules/webserver.md) |
| ZHB | Zigbee Hub device control: `getDevice()`, `waitForStart()`, `permitJoin()`. ZigbeeDevice class: `sendOnOff()`, `sendBri()`, `sendColor()`, `sendColorTemp()`, `sendCmd()`, `getVal()`, `readAttr()`, binding, `on_action` event | v2.9.6 | All | [docs/modules/zhb.md](docs/modules/zhb.md) |
| HTTP | Outgoing HTTP/S requests: `open()`, `perform()`, `getResponse()`, `setPostData()`, `setHeader()`, stream mode for large responses | v2.9.8 | All | [docs/modules/http.md](docs/modules/http.md) |
| TIME | NTP-synced clock: `waitSync()`, `getAll()` → `{year, month, day, hour, min, sec, weekday}`, `getTime()` | v3.0.6 | All | [docs/modules/time.md](docs/modules/time.md) |
| FS | File system: `exists()`, `open()`, `deleteFile()`, `deleteDir()` | v3.0.6 | All | [docs/modules/fs.md](docs/modules/fs.md) |
| GPIO | Direct pin control: `pinMode()`, `digitalRead/Write()`, `analogRead/Write()`, `tone()`, `noTone()` | v3.1.6.dev3 | All | [docs/modules/gpio.md](docs/modules/gpio.md) |
| MQTT | Messaging: `waitConnect()`, `subscribe()`, `publish()`, `on_message` event. Requires MQTT enabled in web UI | v3.2.4 | All | [docs/modules/mqtt.md](docs/modules/mqtt.md) |
| BUZZER | Play RTTTL melodies: `play(melody_string)` | v3.2.5.dev1 | Ultima3 | [docs/modules/buzzer.md](docs/modules/buzzer.md) |
| BUTTON | Override physical device button: `on_press(0, callback)` → press_type 0=short, 1=long | v3.2.5.dev1 | All | [docs/modules/button.md](docs/modules/button.md) |
| AMBILIGHT | WS2812B LED strip: effects, colors, brightness, speed, direction. 18 built-in effects | v3.2.5.dev1 | Ultima | [docs/modules/ambilight.md](docs/modules/ambilight.md) |
| IR Transmitter | Send IR commands: `send(protocol, addr, cmd)`, `sendRaw()`. 13 protocol constants | v3.2.5.dev1 | Ultima | [docs/modules/ir_transmitter.md](docs/modules/ir_transmitter.md) |
| IR Receiver | Receive IR signals: `on_receive` event, `getProtocol/Address/Command()`, `getRaw()` for learning. 14 protocol constants | v3.2.5.dev1 | Ultima | [docs/modules/ir_receiver.md](docs/modules/ir_receiver.md) |

## Guides

| Guide | When to read |
|-------|-------------|
| [docs/guides/zigbee-button-actions.md](docs/guides/zigbee-button-actions.md) | When using `ZHB.on_action()` — contains action string tables for different device brands and full examples |

## Examples

| File | What it demonstrates |
|------|---------------------|
| [examples/basic/reboot_every_day.be](examples/basic/reboot_every_day.be) | Scheduled reboot with delay loop |
| [examples/basic/zb_reboot_on_drop.be](examples/basic/zb_reboot_on_drop.be) | Monitor Zigbee socket clients, reboot chip on disconnect |
| [examples/basic/get_file_size.be](examples/basic/get_file_size.be) | Open and inspect a file |
| [examples/http_client/http_get.be](examples/http_client/http_get.be) | GET request with JSON parsing |
| [examples/http_client/http_post.be](examples/http_client/http_post.be) | POST request with JSON body |
| [examples/report_stats/report_stats.be](examples/report_stats/report_stats.be) | Zigbee packet stats + webhook API (ZB + WEBSERVER) |
| [examples/zigbee_hub/simple_thermostat.be](examples/zigbee_hub/simple_thermostat.be) | Thermostat with temp sensor + relay (ZHB) |
| [examples/time/reboot_at_3am.be](examples/time/reboot_at_3am.be) | Reboot device at a specific time daily (TIME) |
| [examples/time/log_datetime.be](examples/time/log_datetime.be) | Log current date and time (TIME) |
| [examples/time/alarm.be](examples/time/alarm.be) | Wake-up alarm with LED + buzzer (TIME + AMBILIGHT + BUZZER) |
| [examples/gpio/blink_led.be](examples/gpio/blink_led.be) | Blink an LED on/off (GPIO) |
| [examples/gpio/read_analog.be](examples/gpio/read_analog.be) | Read analog voltage (GPIO) |
| [examples/mqtt/mqtt_subscribe.be](examples/mqtt/mqtt_subscribe.be) | Subscribe to MQTT topic and log messages |
| [examples/mqtt/mqtt_publish_temperature.be](examples/mqtt/mqtt_publish_temperature.be) | Publish Zigbee sensor data to MQTT (MQTT + ZHB) |
| [examples/buzzer/play_melody.be](examples/buzzer/play_melody.be) | Play RTTTL melody (BUZZER) |
| [examples/buzzer/doorbell.be](examples/buzzer/doorbell.be) | Zigbee button doorbell (BUZZER + ZHB) |
| [examples/button/button_toggle_relay.be](examples/button/button_toggle_relay.be) | Physical button toggles Zigbee relay (BUTTON + ZHB) |
| [examples/ambilight/effects_demo.be](examples/ambilight/effects_demo.be) | Cycle through all LED effects (AMBILIGHT) |
| [examples/ambilight/color_cycle_on_button.be](examples/ambilight/color_cycle_on_button.be) | Zigbee button cycles LED colors (AMBILIGHT + ZHB) |
| [examples/ir_transmitter/send_nec_command.be](examples/ir_transmitter/send_nec_command.be) | Send an NEC IR command |
| [examples/ir_transmitter/zigbee_button_sends_ir.be](examples/ir_transmitter/zigbee_button_sends_ir.be) | Zigbee button sends IR to TV (IR + ZHB) |
| [examples/ir_receiver/log_ir_codes.be](examples/ir_receiver/log_ir_codes.be) | Log all received IR codes (discovery) |
| [examples/ir_receiver/ir_to_zigbee_bridge.be](examples/ir_receiver/ir_to_zigbee_bridge.be) | Control Zigbee devices with IR remote (IR + ZHB) |

## Quick reference: common patterns

### Minimal script template
```berry
#META {"start":1}
# your code here
SLZB.log("Hello from Berry!")
```

### Event-based script template
```berry
#META {"start":1}
import ZHB

ZHB.waitForStart(0xff)

def on_action(action, dev)
  SLZB.log("[" .. dev.getName() .. "] " .. action)
end

ZHB.on_action(on_action)
```

### Control a device
```berry
var dev = ZHB.getDevice("Device Name")  # by name
var dev = ZHB.getDevice("0x00158d...")   # by IEEE
var dev = ZHB.getDevice(0x1234)          # by network address
dev.sendOnOff(1)                         # turn on
dev.getVal(1, 0x0402, 0)                 # read temperature
```

### HTTP request
```berry
import HTTP
if HTTP.open(url, "get", 1024)
  if HTTP.perform() == 200
    var resp = HTTP.getResponse()
  end
  HTTP.close()
end
```

### MQTT publish/subscribe
```berry
import MQTT
MQTT.waitConnect(0xff)
MQTT.subscribe("topic")
MQTT.on_message(def (topic, data) SLZB.log(data) end)
MQTT.publish("topic", "payload")
```

---

## How to use this prompt

Paste this file into your AI agent's context, then add your request. Examples:

> "Write a script that toggles a relay named 'Heater' when a button named 'Wall Switch' is single-clicked. Read docs/modules/zhb.md and docs/guides/zigbee-button-actions.md for details."

> "Create a script that checks temperature every 5 minutes and sends an MQTT alert if it exceeds 30 degrees. Read docs/modules/zhb.md and docs/modules/mqtt.md."

> "Write a script that changes the LED strip to red when an IR power button is received. Read docs/modules/ir.md and docs/modules/ambilight.md."

The agent should read only the documentation files relevant to your request, not all of them.
