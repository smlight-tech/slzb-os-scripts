# WOL Module

Wake up computers and network devices using [Wake-on-LAN](https://en.wikipedia.org/wiki/Wake-on-LAN) magic packets. No external services required — works entirely on your local network.

## Setup

### Option A — Configure via UI (recommended)

1. Go to **Scripts Integrations** page
2. Click the **WAKE-ON-LAN** tile
3. Add devices with:
   - **Name** — friendly name (e.g. "Gaming PC", "NAS")
   - **MAC Address** — target device MAC (e.g. `AA:BB:CC:DD:EE:FF`)
4. Enable and save

### Option B — Use directly in script (no setup needed)

```berry
import WOL
WOL.wake("AA:BB:CC:DD:EE:FF")
```

## Functions

### WOL.wake(mac [, port])

Send a Wake-on-LAN magic packet to a MAC address.

| Parameter | Type | Description |
|-----------|------|-------------|
| `mac` | string | MAC address (`AA:BB:CC:DD:EE:FF` or `AA-BB-CC-DD-EE-FF`) |
| `port` | int | (optional) UDP port, default `9` |

**Returns:** `bool` — `true` if the packet was sent

```berry
import WOL
WOL.wake("AA:BB:CC:DD:EE:FF")

# Custom port
WOL.wake("AA:BB:CC:DD:EE:FF", 7)
```

### WOL.wake_name(name)

Wake a device by its configured name (from UI).

| Parameter | Type | Description |
|-----------|------|-------------|
| `name` | string | Device name (case-insensitive) |

**Returns:** `bool` — `true` if the packet was sent

```berry
import WOL
WOL.wake_name("Gaming PC")
WOL.wake_name("NAS")
```

### WOL.devices()

List all configured WOL devices.

**Returns:** `map` — keys are device names, values are MAC addresses

```berry
import WOL
var all = WOL.devices()
for name : all.keys()
    print(name .. " — " .. all[name])
end
```

## Examples

### Wake PC on Zigbee button press

```berry
import WOL
import ZHB

ZHB.waitForStart(0xff)
ZHB.on_action(def (action, dev)
    if dev.getName() == "Desk Button" && action == "single"
        WOL.wake_name("Gaming PC")
    end
end, 60000)
```

### Wake NAS at scheduled time

```berry
import WOL
import TIME
import TIMER

TIMER.setInterval(def()
    var t = TIME.getAll()
    if t["hour"] == 7 && t["min"] == 0
        WOL.wake_name("NAS")
    end
end)
```

### Wake on motion detection

```berry
import WOL
import ZHB

ZHB.waitForStart(0xff)
ZHB.on_action(def (action, dev)
    if dev.getName() == "Office Motion" && action == "occupancy"
        WOL.wake_name("Workstation")
    end
end)
```

### Wake + notify

```berry
import WOL
import TELEGRAM

WOL.wake_name("Media Server")
TELEGRAM.send("Media Server wake-up signal sent!")
```

## Prerequisites

The target device must support Wake-on-LAN:

1. **BIOS/UEFI:** Enable "Wake on LAN" or "Power on by PCIe/PCI"
2. **OS settings:**
   - **Windows:** Device Manager → Network Adapter → Properties → Power Management → "Allow this device to wake the computer"
   - **Linux:** `sudo ethtool -s eth0 wol g`
   - **macOS:** System Preferences → Energy Saver → "Wake for network access"
3. The device must be connected via **Ethernet** (WiFi WoL support varies)
4. The device must be in **sleep/hibernate/shutdown** state (not fully powered off at the PSU)

## Finding MAC Addresses

- **Windows:** `ipconfig /all` → look for "Physical Address"
- **Linux:** `ip link show` or `ifconfig`
- **macOS:** System Preferences → Network → Advanced → Hardware
- **Router:** Check the DHCP client list in your router's admin page

## Notes

- Sends a UDP broadcast magic packet (102 bytes) to port 9
- No external service or internet required — works entirely on local network
- The SLZB device must be on the same broadcast domain (same subnet) as the target device
- Magic packets cannot cross routers/VLANs without special configuration (directed broadcast)
- Each call is instant — no HTTP overhead, just a single UDP packet
- WoL does not guarantee the device will wake — depends on hardware/BIOS/OS configuration
