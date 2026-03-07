# Zigbee Button & Action Events

Use `ZHB.on_action()` to react to Zigbee button presses, rotary encoder turns, and other device actions in your Berry scripts.

## Quick Start

```berry
#META {"start":1}
import ZHB

ZHB.waitForStart(0xff)

var relay = ZHB.getDevice("My Relay")

def on_action(action, dev)
  if dev.getName() == "My Button"
    if action == "single"
      relay.sendOnOff(1)   # turn on
    elif action == "double"
      relay.sendOnOff(0)   # turn off
    end
  end
end

ZHB.on_action(on_action)
```

That's it! Single click turns the relay on, double click turns it off.

---

## How It Works

`ZHB.on_action(callback)` registers a function that is called every time a Zigbee device sends an action event.

Your callback receives two arguments:

| Argument | Type | Description |
|----------|------|-------------|
| `action` | `string` | The action name, e.g. `"single"`, `"btn_double_1"`, `"rotate_right_1"` |
| `dev` | `ZigbeeDevice` | The device that triggered the action |

```berry
def on_action(action, dev)
  # action = "single", "double", "long", "btn_single_1", etc.
  # dev = the ZigbeeDevice object
end

ZHB.on_action(on_action)
```

---

## Step 1: Discover Your Device's Action Strings

**Action strings vary by device manufacturer.** Before writing automation, run this script to see what your button actually sends:

```berry
#META {"start":1}
import ZHB

ZHB.waitForStart(0xff)

def on_action(action, dev)
  SLZB.log("[" .. dev.getName() .. "] action: " .. action)
end

ZHB.on_action(on_action)
```

Press each button on your device (single click, double click, long press) and check the console log:

```
[My Button] action: single
[My Button] action: double
[My Button] action: long
```

Use these exact strings in your automation script.

---

## Step 2: Identify Your Device

You can filter events by device name, IEEE address, or manufacturer/model.

**By name** (set in the Zigbee Hub UI):
```berry
def on_action(action, dev)
  if dev.getName() == "My Button"
    # handle action
  end
end
```

**By IEEE address** (useful if you haven't named your device):
```berry
var button = ZHB.getDevice("0xe456acfffe603d1e")

def on_action(action, dev)
  if dev.getNwk() == button.getNwk()
    # handle action
  end
end
```

**By manufacturer and model** (matches any device of that type):
```berry
def on_action(action, dev)
  if dev.matcher("eWeLink", "WB01")
    # handle action
  end
end
```

---

## Common Action Strings

### Sonoff / eWeLink buttons

| Action | Trigger |
|--------|---------|
| `single` | Single click |
| `double` | Double click |
| `long` | Long press |

### Standard Zigbee buttons (Aqara, Tuya, IKEA, etc.)

| Action | Trigger |
|--------|---------|
| `btn_single_1` | Single click, button 1 |
| `btn_double_1` | Double click, button 1 |
| `btn_long_1` | Long press, button 1 |

### Multi-button remotes

Devices with multiple physical buttons (e.g. Aqara Opple 6-button, IKEA 5-button, Tuya 4-gang scene switch) use the number at the end to identify which button was pressed:

| Action | Trigger |
|--------|---------|
| `btn_single_1` | Single click, button 1 |
| `btn_single_2` | Single click, button 2 |
| `btn_single_3` | Single click, button 3 |
| `btn_double_2` | Double click, button 2 |
| `btn_long_4` | Long press, button 4 |

The number of available buttons depends on the device.

### Rotary encoders

| Action | Trigger |
|--------|---------|
| `rotate_right_1` | Rotate clockwise |
| `rotate_left_1` | Rotate counter-clockwise |
| `rotate_stop_1` | Rotation stopped |

> **Note:** These are the most common action strings. Your device may use different ones. Always use the [discovery script](#step-1-discover-your-devices-action-strings) to check.

---

## Examples

### Toggle a relay on/off

Single click toggles: if the relay is on, turn it off; if it's off, turn it on.

```berry
#META {"start":1}
import ZHB

ZHB.waitForStart(0xff)

var relay = ZHB.getDevice("My Relay")

def on_action(action, dev)
  if dev.getName() == "My Button" && action == "single"
    var state = relay.getVal(1, 6, 0)
    relay.sendOnOff(state ? 0 : 1)
  end
end

ZHB.on_action(on_action)
```

### Control brightness with a button

Single click turns on, double click turns off, long press sets 50% brightness.

```berry
#META {"start":1}
import ZHB

ZHB.waitForStart(0xff)

var lamp = ZHB.getDevice("My Lamp")

def on_action(action, dev)
  if dev.getName() != "My Button"
    return
  end

  if action == "single"
    lamp.sendOnOff(1)
  elif action == "double"
    lamp.sendOnOff(0)
  elif action == "long"
    lamp.sendBri(127)
  end
end

ZHB.on_action(on_action)
```

### Multi-button remote controlling multiple lights

Each button controls a different light — single click on, double click off.

```berry
#META {"start":1}
import ZHB

ZHB.waitForStart(0xff)

var light_1 = ZHB.getDevice("Living Room Light")
var light_2 = ZHB.getDevice("Bedroom Light")
var light_3 = ZHB.getDevice("Kitchen Light")

def on_action(action, dev)
  if dev.getName() != "My Remote"
    return
  end

  if action == "btn_single_1"     light_1.sendOnOff(1)
  elif action == "btn_double_1"   light_1.sendOnOff(0)
  elif action == "btn_single_2"   light_2.sendOnOff(1)
  elif action == "btn_double_2"   light_2.sendOnOff(0)
  elif action == "btn_single_3"   light_3.sendOnOff(1)
  elif action == "btn_double_3"   light_3.sendOnOff(0)
  end
end

ZHB.on_action(on_action)
```

### React to multiple buttons from different devices

```berry
#META {"start":1}
import ZHB

ZHB.waitForStart(0xff)

var relay_1 = ZHB.getDevice("Relay 1")
var relay_2 = ZHB.getDevice("Relay 2")

def on_action(action, dev)
  if dev.getName() == "Kitchen Button" && action == "single"
    relay_1.sendOnOff(1)

  elif dev.getName() == "Bedroom Button" && action == "single"
    relay_2.sendOnOff(1)

  elif action == "long"
    # long press on any button turns everything off
    relay_1.sendOnOff(0)
    relay_2.sendOnOff(0)
  end
end

ZHB.on_action(on_action)
```

### Rotary encoder controlling lamp brightness

Rotate clockwise to increase brightness, counter-clockwise to decrease. Press the button to toggle on/off.

```berry
#META {"start":1}
import ZHB

ZHB.waitForStart(0xff)

var lamp = ZHB.getDevice("My Lamp")
var bri = 127

def on_action(action, dev)
  if dev.getName() != "My Encoder"
    return
  end

  if action == "rotate_right_1"
    bri = bri + 25
    if bri > 254  bri = 254  end
    lamp.sendBri(bri)
  elif action == "rotate_left_1"
    bri = bri - 25
    if bri < 1  bri = 1  end
    lamp.sendBri(bri)
  elif action == "btn_single_1"
    var state = lamp.getVal(1, 6, 0)
    lamp.sendOnOff(state ? 0 : 1)
  end
end

ZHB.on_action(on_action)
```

### Rotary encoder controlling color temperature

Rotate to change the lamp's color temperature from warm to cool.

```berry
#META {"start":1}
import ZHB

ZHB.waitForStart(0xff)

var lamp = ZHB.getDevice("My Lamp")
var mireds = 350  # warm white

def on_action(action, dev)
  if dev.getName() != "My Encoder"
    return
  end

  if action == "rotate_right_1"
    mireds = mireds - 20  # cooler
    if mireds < 150  mireds = 150  end
    lamp.sendColorTemp(mireds)
  elif action == "rotate_left_1"
    mireds = mireds + 20  # warmer
    if mireds > 500  mireds = 500  end
    lamp.sendColorTemp(mireds)
  end
end

ZHB.on_action(on_action)
```

### Change lamp color with a button

```berry
#META {"start":1}
import ZHB

ZHB.waitForStart(0xff)

var lamp = ZHB.getDevice("Color Lamp")
var colors = ["#ff0000", "#00ff00", "#0000ff", "#ffff00"]
var idx = 0

def on_action(action, dev)
  if dev.getName() != "My Button"
    return
  end

  if action == "single"
    lamp.sendOnOff(1)
    lamp.sendColor(colors[idx])
    idx = (idx + 1) % 4
  elif action == "double"
    lamp.sendOnOff(0)
  end
end

ZHB.on_action(on_action)
```

---

## Tips

- **Always discover first.** Different manufacturers use different action strings. Don't guess — run the discovery script.
- **Keep it short.** The `on_action` callback runs in the event task. Don't use `SLZB.delay()` or long loops inside it.
- **One script can handle multiple devices.** You don't need a separate script for each button — just check `dev.getName()` or `dev.matcher()` inside the callback.
- **Use `getDevice()` outside the callback.** Look up devices once at startup, not on every button press.
- **Get device by IEEE address.** If you haven't named your device, use its IEEE address: `ZHB.getDevice("0xe456acfffe603d1e")`. You can find the IEEE address on the Zigbee Hub devices page.
