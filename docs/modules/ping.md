# PING Module

Check if network hosts are reachable using ICMP ping. Works with IP addresses and hostnames — no external services required.

## Functions

### PING.check(host [, count [, timeout_ms]])

Send ICMP ping packets and get detailed results.

| Parameter | Type | Description |
|-----------|------|-------------|
| `host` | string | IP address or hostname |
| `count` | int | (optional) Number of pings, default `3`, max `10` |
| `timeout_ms` | int | (optional) Timeout per ping in ms, default `1000` |

**Returns:** `map` with keys:

| Key | Type | Description |
|-----|------|-------------|
| `ok` | bool | `true` if at least one reply received |
| `time` | int | Last successful round-trip time in ms |
| `sent` | int | Number of packets sent |
| `recv` | int | Number of replies received |
| `loss` | int | Packet loss percentage (0–100) |

```berry
import PING

var r = PING.check("192.168.1.1")
print("OK: " .. str(r["ok"]))
print("Time: " .. str(r["time"]) .. " ms")
print("Loss: " .. str(r["loss"]) .. "%")

# Custom count and timeout
var r2 = PING.check("google.com", 5, 2000)
```

### PING.alive(host)

Quick reachability check — sends a single ping.

| Parameter | Type | Description |
|-----------|------|-------------|
| `host` | string | IP address or hostname |

**Returns:** `bool` — `true` if the host responded

```berry
import PING

if PING.alive("192.168.1.1")
    print("Router is up")
else
    print("Router is down!")
end
```

## Examples

### Monitor gateway and alert on failure

```berry
import PING
import TELEGRAM
import TIMER

TIMER.setInterval(def()
    if !PING.alive("192.168.1.1")
        TELEGRAM.send("Gateway is unreachable!")
    end
end, 60000)
```

### Check multiple hosts

```berry
import PING

var hosts = ["192.168.1.1", "192.168.1.100", "google.com"]
for host : hosts
    var r = PING.check(host, 2)
    print(host .. ": " .. (r["ok"] ? "up" : "down") .. " (" .. str(r["time"]) .. " ms)")
end
```

### Wake-on-LAN with ping verification

```berry
import PING
import WOL
import SLZB

WOL.wake("AA:BB:CC:DD:EE:FF")
SLZB.delay(10000)

if PING.alive("192.168.1.50")
    print("PC is up!")
else
    print("PC did not respond yet")
end
```

### Reboot Zigbee chip if internet is down

```berry
import PING
import ZB
import TIMER

var fail_count = 0

TIMER.setInterval(def()
    if PING.alive("8.8.8.8")
        fail_count = 0
    else
        fail_count += 1
        if fail_count >= 3
            ZB.reboot()
            fail_count = 0
        end
    end
end, 30000)
```

## Notes

- Uses ESP-IDF ICMP ping — no external service or HTTP overhead
- DNS resolution is supported (hostnames are resolved automatically)
- `check()` is blocking — the script waits until all pings complete
- `alive()` sends a single ping with a 2-second timeout
- Maximum count is 10 to prevent long blocking times
- The SLZB device must have network connectivity (Ethernet or WiFi)
- ICMP may be blocked by some firewalls — ping failures don't always mean the host is down
