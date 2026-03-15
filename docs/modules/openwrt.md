# OPENWRT Module

Connect to an [OpenWrt](https://openwrt.org/) router for presence detection, client monitoring, and system management via the ubus JSON-RPC API.

## Prerequisites

Your OpenWrt router must have:
- **uhttpd** web server running (default on most OpenWrt installations)
- **rpcd** and **uhttpd-mod-ubus** packages installed (usually pre-installed)
- For `clients()`: the **luci-mod-rpc** package (`opkg install luci-mod-rpc`)

## Setup

### Option A — Configure via UI (recommended)

1. Go to **Scripts Integrations** page
2. Click the **OPENWRT** tile
3. Fill in:
   - **Host / IP** — router IP address (e.g. `192.168.1.1`)
   - **Username** — router login username (default: `root`)
   - **Password** — router login password
4. Enable and save

### Option B — Configure in script

```berry
import OPENWRT
OPENWRT.setup("192.168.1.1", "root", "your-password")
```

## Functions

### OPENWRT.setup(host, username, password)

Override router credentials for this script session.

| Parameter | Type | Description |
|-----------|------|-------------|
| `host` | string | Router IP address |
| `username` | string | Login username |
| `password` | string | Login password |

### OPENWRT.is_connected(mac)

Check if a device with the given MAC address is on the network. Useful for **presence detection**.

| Parameter | Type | Description |
|-----------|------|-------------|
| `mac` | string | MAC address (e.g. `"AA:BB:CC:DD:EE:FF"`) |

**Returns:** `bool` — `true` if the device has an active DHCP lease

```berry
import OPENWRT

var home = OPENWRT.is_connected("AA:BB:CC:DD:EE:FF")
if home
    print("Phone is on WiFi — someone is home")
end
```

### OPENWRT.clients()

Get a list of network clients (DHCP leases + WiFi associations).

**Returns:** `list` of `map` objects. Each map may contain:

| Key | Type | Description |
|-----|------|-------------|
| `hostname` | string | Device hostname |
| `mac` | string | MAC address |
| `ip` | string | IP address |
| `expires` | string | DHCP lease expiry |
| `signal` | int | WiFi signal strength in dBm (WiFi clients only) |
| `noise` | int | Noise level in dBm (WiFi clients only) |
| `rx_rate` | int | Receive rate in Mbps (WiFi clients only) |
| `tx_rate` | int | Transmit rate in Mbps (WiFi clients only) |

```berry
import OPENWRT

var clients = OPENWRT.clients()
for c : clients
    if c.find("hostname")
        print(c["hostname"] .. " — " .. c["mac"] .. " — " .. c["ip"])
    end
end
```

### OPENWRT.info()

Get router system information.

**Returns:** `map` with keys:

| Key | Type | Description |
|-----|------|-------------|
| `uptime` | int | Uptime in seconds |
| `localtime` | int | Local time as Unix timestamp |
| `load_1m` | int | Load average (1 min), scaled ×65536 |
| `load_5m` | int | Load average (5 min), scaled ×65536 |
| `load_15m` | int | Load average (15 min), scaled ×65536 |
| `mem_total` | int | Total RAM in bytes |
| `mem_free` | int | Free RAM in bytes |
| `mem_buffered` | int | Buffered RAM in bytes |

```berry
import OPENWRT

var info = OPENWRT.info()
print("Uptime: " .. str(info["uptime"] / 3600) .. " hours")
print("Free memory: " .. str(info["mem_free"] / 1024) .. " KB")
```

### OPENWRT.reboot()

Reboot the router.

**Returns:** `bool` — `true` if the reboot command was sent

```berry
import OPENWRT
OPENWRT.reboot()
```

### OPENWRT.call(object, method [, args_json])

Make a raw ubus JSON-RPC call for advanced use cases.

| Parameter | Type | Description |
|-----------|------|-------------|
| `object` | string | ubus object (e.g. `"system"`, `"network.interface"`) |
| `method` | string | ubus method (e.g. `"info"`, `"status"`) |
| `args_json` | string | (optional) JSON arguments |

**Returns:** `string` — raw JSON response

```berry
import OPENWRT
import json

# Get WAN interface status
var resp = OPENWRT.call("network.interface.wan", "status")
var data = json.load(resp)
print(data)
```

## Examples

### Presence-based automation

```berry
import OPENWRT
import HA
import TIMER

# Check every 5 minutes if phone is on WiFi
TIMER.setInterval(def()
    var home = OPENWRT.is_connected("AA:BB:CC:DD:EE:FF")
    if home
        HA.call("climate", "set_temperature", "climate.living_room", '{"temperature": 22}')
    else
        HA.call("climate", "set_temperature", "climate.living_room", '{"temperature": 16}')
    end
end, 300000)
```

### Alert when new device joins network

```berry
import OPENWRT
import TELEGRAM
import TIMER

var known_macs = ["AA:BB:CC:DD:EE:FF", "11:22:33:44:55:66"]

TIMER.setInterval(def()
    var clients = OPENWRT.clients()
    for c : clients
        var mac = c.find("mac", "")
        if mac != "" && known_macs.find(mac) == nil
            TELEGRAM.send("Unknown device on network: " .. mac .. " (" .. c.find("hostname", "unknown") .. ")")
        end
    end
end, 600000)
```

### Monitor router health

```berry
import OPENWRT
import INFLUXDB
import TIMER

TIMER.setInterval(def()
    var info = OPENWRT.info()
    INFLUXDB.write_point("router",
        {"host": "openwrt"},
        {"uptime": info["uptime"], "mem_free": info["mem_free"],
         "load_1m": info["load_1m"]}
    )
end, 300000)
```

### Turn on lights when arriving home

```berry
import OPENWRT
import HUE
import TIMER

var was_home = false

TIMER.setInterval(def()
    var home = OPENWRT.is_connected("AA:BB:CC:DD:EE:FF")
    if home && !was_home
        # Just arrived — turn on lights
        HUE.on(1)
        HUE.set_brightness(1, 200)
    end
    was_home = home
end, 60000)
```

## Finding MAC Addresses

To find your phone's MAC address:
- **iPhone:** Settings → Wi-Fi → tap the (i) next to your network → Wi-Fi Address
- **Android:** Settings → About phone → Status → Wi-Fi MAC address
- **OpenWrt:** LuCI web interface → Status → Overview → Associated Stations

## Notes

- Uses the OpenWrt **ubus JSON-RPC** API over HTTP
- Session tokens are managed automatically — the module logs in and re-authenticates as needed
- The SLZB device must be on the same network as the OpenWrt router
- `clients()` requires the `luci-mod-rpc` package for DHCP lease data
- WiFi client data (signal, rates) comes from `iwinfo` and may only show the first radio (`wlan0`)
- For multiple radios, use `call("iwinfo", "assoclist", '{"device":"wlan1"}')` directly
- Each function makes 1-2 HTTP requests (~2-4 KB temporary RAM, freed immediately)
- Session validity is checked before each call; auto-re-login on session expiry
