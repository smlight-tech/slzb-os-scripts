# SUN Module

**This module has been completely reworked in firmware `v3.3.3.dev0`!
You are currently viewing the description for firmware `v3.3.3.dev0` or higher!**

Calculates sunrise and sunset times using the provided coordinates and a special algorithm. Possible error in calculations +-10 minutes.<br>
<br>
Astronomical twilight:	almost completely dark.<br>
Nautical twilight:	horizon becomes visible.<br>
Civil twilight:	enough light for most outdoor activity.<br>
Sunrise/Sunset:	Sun crosses horizon.<br>
<br>
Definitions:<br>
Civil dawn → morning civil twilight begins.<br>
Civil dusk → evening civil twilight ends.<br>
Same idea for nautical and astronomical twilight.<br>

## Setup

### Option A — Configure via UI (recommended)

1. Go to **Scripts Integrations** page
2. Click the **SUN** tile
3. Fill in **Latitude** and **Longitude**, or click **Detect location** to auto-fill from your browser
4. Enable and save

### Option B — Configure in script

```berry
import SUN
SUN.setup(48.8566, 2.3522)
```

This overrides the UI config for the current script session only.

## API Reference

| Function | Description |
|----------|-------------|
| `SUN.setup(lat:real, lng:real) -> nil` | Override coordinates for this script session. There should be no more than seven digits after the dot. |
| `SUN.sunrise(y:int?, m:int?, d:int?) -> map` | Calculates sunrise time for the specified 'YYYY, MM, DD' date. If no date is specified, it calculates for today. Since v3.4.5.dev2 (before: `SUN.sunrize()`, see Notes). |
| `SUN.sunset(y:int?, m:int?, d:int?) -> map` | Calculates sunset time. |
| `SUN.civilDawn(y:int?, m:int?, d:int?) -> map` | Calculates civil dawn time. |
| `SUN.civilDusk(y:int?, m:int?, d:int?) -> map` | Calculates civil dusk time. |
| `SUN.astronomicalDawn(y:int?, m:int?, d:int?) -> map` | Calculates astronomical dawn time. |
| `SUN.astronomicalDusk(y:int?, m:int?, d:int?) -> map` | Calculates astronomical dusk time. |
| `SUN.nauticalDawn(y:int?, m:int?, d:int?) -> map` | Calculates nautical dawn time. |
| `SUN.nauticalDusk(y:int?, m:int?, d:int?) -> map` | Calculates nautical dusk time. |

**Returns:** `map` with keys:

| Key | Type | Description |
|-----|------|-------------|
| `hour` | int | result hour |
| `min` | int | result minute | 

## Examples

### Today's sunrise/sunset
```berry
import SUN

# Today's sunrise/sunset
var rise = SUN.sunrise()
var set = SUN.sunset()
SLZB.log(format("Sunrise: %02d:%02d", rise["hour"], rise["min"]))
SLZB.log(format("Sunset: %02d:%02d", set["hour"], set["min"]))

# Specific date
var midsummer = SUN.sunrise(2025, 6, 21)
```

### Turn on lights at sunset in Zigbee Hub mode

```berry
import SUN
import TIME
import TIMER
import ZHB

ZHB.waitForStart(0xff)
TIME.waitSync(0xff)
var dev = ZHB.getDevice("0xa4c138e1494c3145") # replace with your device's IEEE
var light_on = nil # not known yet: the first check sends the state

# minutes since midnight: "after 17:45" is not "hour >= 17 and min >= 45"
def minutes(t)
    return t["hour"] * 60 + t["min"]
end

TIMER.setInterval(def ()
    var now = minutes(TIME.getTime())
    var dark = now >= minutes(SUN.sunset()) || now < minutes(SUN.sunrise())

    if dark != light_on
        light_on = dark
        dev.sendOnOff(dark ? 1 : 0)
    end
end, 60000)
```

## Notes

- Uses local calculation. The calculation itself does not require internet access, but the **coordinator's NTP clock must be synchronized!**
- All times are returned taking into account the time zone set on the coordinator and taking into account summer/winter time. Even for future dates
- Latitude range: -90 to 90; Longitude range: -180 to 180
- Use the **Detect location** button in the UI to auto-fill coordinates from your browser
- Before v3.4.5.dev2 the sunrise function was named `SUN.sunrize()`. That name still works as an alias of `SUN.sunrise()`; use `SUN.sunrise()` in new scripts
