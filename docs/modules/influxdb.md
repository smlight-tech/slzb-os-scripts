# INFLUXDB Module

Write time-series data to [InfluxDB v2](https://docs.influxdata.com/influxdb/v2/) using the Write API. Perfect for building Grafana dashboards with sensor data.

## Setup

### Option A — Configure via UI (recommended)

1. Go to **Scripts Integrations** page
2. Click the **INFLUXDB** tile
3. Fill in:
   - **InfluxDB URL** — e.g. `http://192.168.1.100:8086`
   - **API Token** — generated in InfluxDB UI under API Tokens
   - **Organization** — your InfluxDB org name
   - **Bucket** — target bucket name
4. Enable and save

### Option B — Configure in script

```berry
import INFLUXDB
INFLUXDB.setup("http://192.168.1.100:8086", "my-api-token", "my-org", "my-bucket")
```

## Functions

### INFLUXDB.setup(url, token, org, bucket)

Override InfluxDB connection for this script session.

| Parameter | Type | Description |
|-----------|------|-------------|
| `url` | string | InfluxDB server URL (e.g. `http://192.168.1.100:8086`) |
| `token` | string | API token |
| `org` | string | Organization name |
| `bucket` | string | Bucket name |

### INFLUXDB.write(measurement, tags, fields)

Write a data point using [line protocol](https://docs.influxdata.com/influxdb/v2/reference/syntax/line-protocol/) strings.

| Parameter | Type | Description |
|-----------|------|-------------|
| `measurement` | string | Measurement name (e.g. `"temperature"`) |
| `tags` | string | Comma-separated tags: `"room=kitchen,floor=1"` (use `""` for no tags) |
| `fields` | string | Comma-separated fields: `"value=23.5,humidity=60i"` |

**Returns:** `int` — HTTP status code (204 on success)

```berry
import INFLUXDB

# With tags
INFLUXDB.write("temperature", "room=kitchen,floor=1", "value=23.5")

# Without tags
INFLUXDB.write("system", "", "uptime=3600i,free_mem=45000i")

# Multiple fields
INFLUXDB.write("weather", "city=Kyiv", "temp=22.3,humidity=65i,pressure=1013i")
```

### Line Protocol Field Types

| Suffix | Type | Example |
|--------|------|---------|
| (none) | Float | `value=23.5` |
| `i` | Integer | `count=42i` |
| `"..."` | String | `status="ok"` |
| `true`/`false` | Boolean | `active=true` |

### INFLUXDB.write_point(measurement, tags_map, fields_map)

Write a data point using Berry maps — more convenient than raw line protocol.

| Parameter | Type | Description |
|-----------|------|-------------|
| `measurement` | string | Measurement name |
| `tags_map` | map | Tag key-value pairs (string values) |
| `fields_map` | map | Field key-value pairs (int, real, bool, or string) |

**Returns:** `int` — HTTP status code (204 on success)

Type mapping for fields:
- `int` → InfluxDB integer (appends `i`)
- `real` → InfluxDB float
- `bool` → InfluxDB boolean
- `string` → InfluxDB string (quoted)

```berry
import INFLUXDB

INFLUXDB.write_point("temperature",
    {"room": "kitchen", "floor": "1"},
    {"value": 23.5, "humidity": 60}
)

# Empty tags
INFLUXDB.write_point("system", {}, {"uptime": 3600, "free_mem": 45000})
```

## Examples

### Log Zigbee sensor data

```berry
import INFLUXDB
import ZHB
import TIMER

ZHB.waitForStart(0xff)
var sensor = ZHB.getDevice("Temperature Sensor")

TIMER.setInterval(def()
    var temp = sensor.getAttr("temperature")
    var hum = sensor.getAttr("humidity")
    INFLUXDB.write_point("zigbee_sensor",
        {"device": "Temperature Sensor", "ieee": sensor.getIeee()},
        {"temperature": temp, "humidity": hum}
    )
end, 60000)
```

### Log weather data hourly

```berry
import INFLUXDB
import WEATHER
import TIMER

TIMER.setInterval(def()
    var w = WEATHER.get()
    INFLUXDB.write_point("weather",
        {"city": w["city"]},
        {"temp": w["temp"], "humidity": w["humidity"],
         "pressure": w["pressure"], "wind": w["wind_speed"]}
    )
end, 3600000)
```

### Track daylight hours

```berry
import INFLUXDB
import SUN
import TIMER

TIMER.setInterval(def()
    var s = SUN.get()
    INFLUXDB.write_point("daylight",
        {},
        {"day_length": s["day_length"]}
    )
end, 86400000)
```

### Monitor device health

```berry
import INFLUXDB
import SLZB
import TIMER

TIMER.setInterval(def()
    INFLUXDB.write_point("device_health",
        {"device": "slzb-06"},
        {"uptime": SLZB.getUptime(), "free_heap": SLZB.getFreeHeap()}
    )
end, 300000)
```

## Grafana Dashboard

After writing data to InfluxDB, create a Grafana dashboard:

1. Add InfluxDB as a data source in Grafana (use Flux query language)
2. Create a new dashboard with panels
3. Example Flux query:
   ```flux
   from(bucket: "my-bucket")
     |> range(start: -24h)
     |> filter(fn: (r) => r._measurement == "temperature")
     |> filter(fn: (r) => r.room == "kitchen")
   ```

## Notes

- Uses InfluxDB **v2 Write API** (`/api/v2/write`)
- Precision is set to seconds (`precision=s`)
- InfluxDB returns **204 No Content** on successful writes (not 200)
- Token authentication is optional — if token is empty, no auth header is sent (useful for local instances without auth)
- Tags are indexed (fast to query), fields are not — use tags for metadata (room, device) and fields for values (temperature, humidity)
- Each write is a single HTTP request (~1 KB temporary RAM, freed immediately)
- For InfluxDB v1, use the `WEBHOOK` module with the v1 write endpoint instead
