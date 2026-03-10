# IFTTT Module

Trigger IFTTT applets from Berry scripts via Webhooks.

## Setup

### Option A — Configure via UI (recommended)

1. Go to **Scripts Integrations** page
2. Click the **IFTTT** tile
3. Enter your Webhook Key
4. Enable and save

### How to get your Webhook Key

1. Go to [IFTTT Maker Webhooks](https://ifttt.com/maker_webhooks)
2. Click **Documentation** (top right)
3. Your key is shown at the top of the page

### Option B — Configure in script

```berry
import IFTTT
IFTTT.setup("your_webhook_key")
```

This overrides the UI config for the current script session only.

## Functions

### IFTTT.setup(webhook_key)

Override the Webhook Key for this script session.

| Parameter | Type | Description |
|-----------|------|-------------|
| `webhook_key` | string | IFTTT Maker Webhooks key |

```berry
import IFTTT
IFTTT.setup("dGhpcyBpcyBhIHRlc3Q")
```

### IFTTT.trigger(event [, value1 [, value2 [, value3]]])

Trigger an IFTTT Webhook event with up to 3 optional string values.

| Parameter | Type | Description |
|-----------|------|-------------|
| `event` | string | Event name (as configured in your IFTTT applet) |
| `value1` | string | (optional) First value |
| `value2` | string | (optional) Second value |
| `value3` | string | (optional) Third value |

**Returns:** `int` — HTTP status code (200 on success)

```berry
import IFTTT

# Simple trigger
IFTTT.trigger("button_pressed")

# Trigger with values
IFTTT.trigger("temp_alert", "living room", "32.5", "celsius")
```

## Examples

### Trigger on button press

```berry
import IFTTT
import BUTTON

BUTTON.on_press(def ()
    IFTTT.trigger("slzb_button_pressed")
end)
```

### Temperature alert

```berry
import IFTTT
import ZB

ZB.on_message(def (msg)
    if msg["cluster"] == 0x0402
        var temp = msg["value"] / 100.0
        if temp > 30
            IFTTT.trigger("high_temp", str(temp), "sensor_1")
        end
    end
end)
```

### Periodic status report

```berry
import IFTTT
import TIMER
import SLZB

TIMER.every(3600000, def ()
    IFTTT.trigger("slzb_heartbeat", str(SLZB.uptime()))
end)
```

## Notes

- IFTTT Webhooks supports up to 3 string values per trigger (`value1`, `value2`, `value3`)
- Values are available in your IFTTT applet as `{{Value1}}`, `{{Value2}}`, `{{Value3}}`
- Each `trigger()` call makes one HTTPS request (~2-4 KB temporary RAM, freed immediately)
- The device needs internet access to reach `maker.ifttt.com`
- Free IFTTT accounts are limited to 2 applets
