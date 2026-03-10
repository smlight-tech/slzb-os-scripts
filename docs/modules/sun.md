# SUN Module

Get sunrise and sunset times using the [Sunrise-Sunset.org](https://sunrise-sunset.org/) API — no API key required.

## Setup

### Option A — Configure via UI (recommended)

1. Go to **Scripts Integrations** page
2. Click the **SUN** tile
3. Fill in **Latitude** and **Longitude**, or click **Detect location** to auto-fill from your browser
4. Enable and save

### Option B — Configure in script

```berry
import SUN
SUN.setup("48.8566", "2.3522")
```

This overrides the UI config for the current script session only.

## Functions

### SUN.setup(lat, lng)

Override coordinates for this script session.

| Parameter | Type | Description |
|-----------|------|-------------|
| `lat` | string | Latitude (e.g. `"48.8566"`) |
| `lng` | string | Longitude (e.g. `"2.3522"`) |

```berry
import SUN
SUN.setup("48.8566", "2.3522")
```

### SUN.get([date])

Get sunrise/sunset data for today or a specific date.

| Parameter | Type | Description |
|-----------|------|-------------|
| `date` | string | (optional) Date in `YYYY-MM-DD` format. Defaults to `"today"` |

**Returns:** `map` with keys:

| Key | Type | Description |
|-----|------|-------------|
| `sunrise` | string | Sunrise time (ISO 8601 UTC) |
| `sunset` | string | Sunset time (ISO 8601 UTC) |
| `solar_noon` | string | Solar noon time (ISO 8601 UTC) |
| `day_length` | int | Day length in seconds |
| `civil_twilight_begin` | string | Civil twilight begin (ISO 8601 UTC) |
| `civil_twilight_end` | string | Civil twilight end (ISO 8601 UTC) |
| `nautical_twilight_begin` | string | Nautical twilight begin (ISO 8601 UTC) |
| `nautical_twilight_end` | string | Nautical twilight end (ISO 8601 UTC) |
| `astronomical_twilight_begin` | string | Astronomical twilight begin (ISO 8601 UTC) |
| `astronomical_twilight_end` | string | Astronomical twilight end (ISO 8601 UTC) |

```berry
import SUN

# Today's sunrise/sunset
var s = SUN.get()
print("Sunrise: " .. s["sunrise"])
print("Sunset: " .. s["sunset"])
print("Day length: " .. str(s["day_length"]) .. " seconds")

# Specific date
var s2 = SUN.get("2025-06-21")
print("Summer solstice sunrise: " .. s2["sunrise"])
```

## Examples

### Turn on lights at sunset

```berry
import SUN
import HA
import TIMER

TIMER.every(60000, def ()
    var s = SUN.get()
    var now = TIME.getTime()
    # Compare current time with sunset and turn on lights
    # (times are in UTC ISO format)
    print("Sunset today: " .. s["sunset"])
end)
```

### Log daylight hours

```berry
import SUN
import GSHEETS

var s = SUN.get()
var hours = s["day_length"] / 3600
GSHEETS.append("daylight", hours, s["sunrise"], s["sunset"])
```

### Adjust LED brightness based on time of day

```berry
import SUN
import WLED

var s = SUN.get()
var dayLen = s["day_length"]
if dayLen > 50000
    WLED.set_brightness("Strip", 128)
else
    WLED.set_brightness("Strip", 255)
end
```

### Button press shows sunrise info

```berry
import SUN
import BUTTON
import TELEGRAM

BUTTON.on_press(def ()
    var s = SUN.get()
    var hrs = s["day_length"] / 3600
    var mins = (s["day_length"] % 3600) / 60
    TELEGRAM.send("Sunrise: " .. s["sunrise"] .. "\nSunset: " .. s["sunset"] .. "\nDay: " .. str(hrs) .. "h " .. str(mins) .. "m")
end)
```

## Notes

- Uses the free [Sunrise-Sunset.org](https://sunrise-sunset.org/) API — **no API key required**
- All times are returned in **UTC** (ISO 8601 format)
- The `date` parameter accepts `YYYY-MM-DD` format or `"today"` (default)
- Each call makes one HTTP request (~1-2 KB temporary RAM, freed immediately)
- The API has no rate limit for reasonable use
- Latitude range: -90 to 90; Longitude range: -180 to 180
- Use the **Detect location** button in the UI to auto-fill coordinates from your browser
