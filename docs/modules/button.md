# BUTTON — Physical Button Override

> Available since: v3.2.5.dev1

Override the device's physical button to run custom actions on short or long press.

**Note:** This module controls the **physical button on the device itself**, not Zigbee wireless buttons. For Zigbee button events, see [ZHB.on_action](zhb.md#zhbon_actioncallback) and the [Zigbee Button & Action Events guide](../guides/zigbee-button-actions.md).

## Quick Example

```berry
import BUTTON

def press_handler(press_type)
  if press_type == 0
    SLZB.log("Short press!")
  elif press_type == 1
    SLZB.log("Long press!")
  end
end

BUTTON.on_press(0, press_handler)
```

## API Reference

| Function | Description |
|----------|-------------|
| `BUTTON.on_press(button_id:int, callback:function)` | Override button actions.<br>`button_id` - button number(id) starting from zero. All devices except SLZB-Ultima have only button `0`. |

Callback receives one argument:
- `press_type` (`int`) — `0` for short press, `1` for long press

SLZB-Ultima specifics:
- you can use two buttons: `0` and `1`. The third button on the case always reboots the coordinator, you cannot use it.
- button `0` supports `short` and `long` presses
- button `1` supports `short` presses only!

**Important:** Registering this callback disables the standard button actions. All press events are redirected to your script instead!

## See Also

- [ZHB.on_action — Zigbee wireless button events](../guides/zigbee-button-actions.md) — For Zigbee buttons, not the physical device button
- [BUZZER — Play sounds](buzzer.md) — Combine: play a tone on button press
- [IR Receiver](ir_receiver.md) — Combine: trigger actions from IR remote
- [GPIO — Direct pin control](gpio.md)
- [Example: Toggle relay with physical button](../../examples/button/button_toggle_relay.be)
