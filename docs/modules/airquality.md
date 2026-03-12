# AIRQUALITY Module

Get air quality index (AQI) and pollutant concentration data from the [OpenWeatherMap Air Pollution API](https://openweathermap.org/api/air-pollution).

> **Tip:** Uses the same API key as the WEATHER module. If you already have WEATHER configured, just reuse your key.

## Setup

### Option A — Configure via UI (recommended)

1. Go to **Scripts Integrations** page
2. Click the **AIR QUALITY** tile
3. Fill in:
   - **API Key** — same as your OpenWeatherMap API key (get one free at [openweathermap.org/api](https://openweathermap.org/api))
   - **Latitude** and **Longitude** — or click **Detect location** to auto-fill
4. Enable and save

### Option B — Configure in script

```berry
import AIRQUALITY
AIRQUALITY.setup("your-api-key", "48.8566", "2.3522")
```

## Functions

### AIRQUALITY.setup(api_key, lat, lng)

Override credentials and coordinates for this script session.

| Parameter | Type | Description |
|-----------|------|-------------|
| `api_key` | string | OpenWeatherMap API key |
| `lat` | string | Latitude |
| `lng` | string | Longitude |

### AIRQUALITY.get()

Get current air quality data.

**Returns:** `map` with keys:

| Key | Type | Description |
|-----|------|-------------|
| `aqi` | int | Air Quality Index (1–5, see table below) |
| `co` | int | Carbon monoxide (CO) in μg/m³ |
| `no` | int | Nitrogen monoxide (NO) in μg/m³ |
| `no2` | int | Nitrogen dioxide (NO2) in μg/m³ |
| `o3` | int | Ozone (O3) in μg/m³ |
| `so2` | int | Sulphur dioxide (SO2) in μg/m³ |
| `pm2_5` | int | Fine particulate matter (PM2.5) in μg/m³ |
| `pm10` | int | Coarse particulate matter (PM10) in μg/m³ |
| `nh3` | int | Ammonia (NH3) in μg/m³ |

### AQI Scale

| AQI | Quality | Description |
|-----|---------|-------------|
| 1 | Good | Air quality is satisfactory |
| 2 | Fair | Acceptable, some pollutants may be a concern |
| 3 | Moderate | Sensitive groups may experience health effects |
| 4 | Poor | Everyone may begin to experience health effects |
| 5 | Very Poor | Health alert: serious health effects |

```berry
import AIRQUALITY

var a = AIRQUALITY.get()
print("AQI: " .. str(a["aqi"]))
print("PM2.5: " .. str(a["pm2_5"]) .. " μg/m³")
print("PM10: " .. str(a["pm10"]) .. " μg/m³")
print("Ozone: " .. str(a["o3"]) .. " μg/m³")
```

## Examples

### Alert on poor air quality

```berry
import AIRQUALITY
import TELEGRAM

var a = AIRQUALITY.get()
if a["aqi"] >= 4
    TELEGRAM.send("Air quality is POOR (AQI=" .. str(a["aqi"]) .. ")! PM2.5=" .. str(a["pm2_5"]) .. " μg/m³. Consider closing windows.")
end
```

### Log air quality to InfluxDB

```berry
import AIRQUALITY
import INFLUXDB
import TIMER

TIMER.every(1800000, def ()
    var a = AIRQUALITY.get()
    INFLUXDB.write_point("air_quality",
        {},
        {"aqi": a["aqi"], "pm2_5": a["pm2_5"], "pm10": a["pm10"],
         "o3": a["o3"], "no2": a["no2"], "co": a["co"]}
    )
end)
```

### Close ventilation on bad air

```berry
import AIRQUALITY
import HA
import TIMER

TIMER.every(600000, def ()
    var a = AIRQUALITY.get()
    if a["aqi"] >= 4
        HA.call("switch", "turn_off", "switch.ventilation")
    else
        HA.call("switch", "turn_on", "switch.ventilation")
    end
end)
```

### Combined weather + air quality report

```berry
import AIRQUALITY
import WEATHER
import PUSHOVER

var w = WEATHER.get()
var a = AIRQUALITY.get()

var aqi_names = ["", "Good", "Fair", "Moderate", "Poor", "Very Poor"]
var msg = "Temp: " .. str(w["temp"]) .. " C, " .. w["description"]
msg = msg .. "\nAQI: " .. aqi_names[a["aqi"]] .. " (PM2.5=" .. str(a["pm2_5"]) .. ")"

PUSHOVER.send(msg, "Daily Report")
```

## PM2.5 Reference Levels

| PM2.5 (μg/m³) | Assessment |
|----------------|------------|
| 0–10 | Good |
| 10–25 | Fair |
| 25–50 | Moderate |
| 50–75 | Poor |
| 75+ | Very Poor |

## Notes

- Uses the [OpenWeatherMap Air Pollution API](https://openweathermap.org/api/air-pollution) — same API key as the WEATHER module
- Free tier: 60 calls/minute, 1,000,000 calls/month
- Requires latitude/longitude coordinates (not city name) — use **Detect location** button for convenience
- All pollutant values are in **μg/m³** (micrograms per cubic meter)
- AQI is the European Air Quality Index (1=Good to 5=Very Poor), not the US EPA AQI scale
- Each call makes one HTTPS request (~1 KB temporary RAM, freed immediately)
