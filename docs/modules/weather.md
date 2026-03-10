# WEATHER Module

Get current weather data from OpenWeatherMap in Berry scripts.

## Setup

### Option A — Configure via UI (recommended)

1. Go to **Scripts Integrations** page
2. Click the **WEATHER** tile
3. Enter your API Key and city name
4. Enable and save

### How to get an API Key

1. Sign up at [OpenWeatherMap](https://openweathermap.org/api)
2. Go to **API keys** in your account
3. Copy your key (free tier allows 1000 calls/day)

### Option B — Configure in script

```berry
import WEATHER
WEATHER.setup("your_api_key", "London")
```

This overrides the UI config for the current script session only.

## Functions

### WEATHER.setup(api_key, city)

Override API key and default city for this script session.

| Parameter | Type | Description |
|-----------|------|-------------|
| `api_key` | string | OpenWeatherMap API key |
| `city` | string | Default city name |

```berry
import WEATHER
WEATHER.setup("abc123def456", "Berlin")
```

### WEATHER.get([city])

Get current weather data. Uses the configured city, or pass a city name to override.

| Parameter | Type | Description |
|-----------|------|-------------|
| `city` | string | (optional) City name to query instead of the configured default |

**Returns:** `map` with keys:

| Key | Type | Description |
|-----|------|-------------|
| `temp` | int | Temperature in Celsius |
| `feels_like` | int | Feels-like temperature in Celsius |
| `temp_min` | int | Minimum temperature |
| `temp_max` | int | Maximum temperature |
| `humidity` | int | Humidity percentage (0–100) |
| `pressure` | int | Atmospheric pressure in hPa |
| `wind_speed` | int | Wind speed in m/s |
| `wind_deg` | int | Wind direction in degrees |
| `clouds` | int | Cloudiness percentage (0–100) |
| `visibility` | int | Visibility in meters |
| `description` | string | Weather description (e.g. "clear sky", "light rain") |
| `icon` | string | Weather icon code (e.g. "01d", "10n") |
| `weather_id` | int | OpenWeatherMap weather condition ID |
| `city` | string | City name from API response |

```berry
import WEATHER

var w = WEATHER.get()
print("Temp: " .. str(w["temp"]) .. " C")
print("Humidity: " .. str(w["humidity"]) .. "%")
print(w["description"])

# Query a different city
var w2 = WEATHER.get("Tokyo")
print(w2["city"] .. ": " .. str(w2["temp"]) .. " C")
```

## Examples

### Log weather periodically

```berry
import WEATHER
import TIMER
import SLZB

TIMER.every(1800000, def ()
    var w = WEATHER.get()
    if w
        SLZB.log("Weather: " .. str(w["temp"]) .. "C, " .. w["description"])
    end
end)
```

### Temperature alert via Telegram

```berry
import WEATHER
import TELEGRAM
import TIMER

TIMER.every(600000, def ()
    var w = WEATHER.get()
    if w && w["temp"] > 35
        TELEGRAM.send("Heat alert! " .. w["city"] .. ": " .. str(w["temp"]) .. " C")
    end
end)
```

### Change LED color based on temperature

```berry
import WEATHER
import WLED
import TIMER

TIMER.every(300000, def ()
    var w = WEATHER.get()
    if w
        var t = w["temp"]
        var color = 0x00FF00
        if t > 30
            color = 0xFF0000
        elif t > 20
            color = 0xFFAA00
        elif t < 5
            color = 0x0000FF
        end
        WLED.set_color("Status Strip", color)
    end
end)
```

### Rain alert

```berry
import WEATHER
import TELEGRAM
import TIMER

TIMER.every(1800000, def ()
    var w = WEATHER.get()
    if w
        var id = w["weather_id"]
        if id >= 500 && id < 600
            TELEGRAM.send("Rain alert in " .. w["city"] .. ": " .. w["description"])
        end
    end
end)
```

## Notes

- Uses OpenWeatherMap free API (1000 calls/day limit)
- Temperature values are integers (rounded from the API's float values)
- All temperatures are in Celsius (metric units)
- Each `get()` call makes one HTTPS request (~2-4 KB temporary RAM, freed immediately)
- The device needs internet access to reach `api.openweathermap.org`
- Weather condition IDs: 2xx = thunderstorm, 3xx = drizzle, 5xx = rain, 6xx = snow, 7xx = atmosphere, 800 = clear, 80x = clouds
