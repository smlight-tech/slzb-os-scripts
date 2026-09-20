# NETWORK — Network State (Readiness, Interface Status, IP Addresses)

> Available since: v2.9.7 (status and IP functions since v3.3.8.dev8)

Check the network state of the coordinator from a script: whether the TCP/IP stack is ready, whether Ethernet and Wi-Fi are connected, and the current IP addresses of the device.

Any network call (HTTP, MQTT, integrations, ...) made before the network stack is up crashes the script — always wait for `NETWORK.waitReady()` (or check `NETWORK.isReady()`) first in scripts that start on boot.

## Quick Example

```berry
import NETWORK

# wait for the network before doing anything network-related
NETWORK.waitReady(0xff)

SLZB.log("device IP: " .. NETWORK.getIp())

if NETWORK.isEthConnected()
  SLZB.log("Ethernet: " .. NETWORK.getEthIp())
end

if NETWORK.isWifiConnected()
  SLZB.log("Wi-Fi: " .. NETWORK.getWifiIp())
end
```

## API Reference

### Readiness

| Function | Description |
|----------|-------------|
| `NETWORK.isReady() -> bool` | `true` once the TCP/IP stack is up. Before that any network call from a script crashes it. |
| `NETWORK.waitReady(timeout:int) -> bool` | Block until the network is ready. `timeout` in seconds; any value `>= 255` (`0xff`) waits forever. Returns: `bool` — `false` if the timeout expired before the network became ready. |

### Interface Status

| Function | Description |
|----------|-------------|
| `NETWORK.isEthConnected() -> bool` | `true` while the Ethernet interface has an IP address (link is up and DHCP/static configuration finished). |
| `NETWORK.isWifiConnected() -> bool` | `true` while Wi-Fi is connected to an access point and has an IP address. |

### IP Addresses

| Function | Description |
|----------|-------------|
| `NETWORK.getIp() -> string` | IP address of the currently active interface — the one the device actually uses (Ethernet, Wi-Fi or its own access point). `"0.0.0.0"` if the device has no address yet. |
| `NETWORK.getEthIp() -> string` | IP address of the Ethernet interface, `"0.0.0.0"` if not connected. |
| `NETWORK.getWifiIp() -> string` | IP address of the Wi-Fi interface, `"0.0.0.0"` if not connected. |

## Notes

- All addresses are IPv4 strings, e.g. `"192.168.1.50"`. An interface without an address returns `"0.0.0.0"`.
- `getIp()` follows the coordinator mode: Ethernet mode returns the Ethernet address, Wi-Fi mode the Wi-Fi address; in access-point mode it returns the AP address the web interface is reachable at.
- `isReady()` only tells that the TCP/IP stack is running — it does not guarantee internet access. Combine with [PING](ping.md) to check reachability of a real host.
- Both interfaces can be connected at the same time (e.g. Ethernet plugged in while Wi-Fi credentials are configured) — `getIp()` returns the address of the interface the firmware prefers.

## Examples

### Report the device IP to Telegram after boot

```berry
import NETWORK
import TELEGRAM

NETWORK.waitReady(0xff)
TELEGRAM.send("SLZB-06 is online: http://" .. NETWORK.getIp())
```

### Watch for Ethernet loss and fall back notification

```berry
import NETWORK
import TIMER

var ethWas = NETWORK.isEthConnected()

TIMER.setInterval(def ()
  var ethNow = NETWORK.isEthConnected()
  if ethNow != ethWas
    ethWas = ethNow
    if ethNow
      SLZB.log("Ethernet is back, IP " .. NETWORK.getEthIp())
    else
      SLZB.log("Ethernet lost, active IP " .. NETWORK.getIp())
    end
  end
end, 5000)
```

### Publish the network state to MQTT

```berry
import NETWORK
import MQTT
import TIMER

NETWORK.waitReady(0xff)

TIMER.setInterval(def ()
  MQTT.publish("net/ip", NETWORK.getIp())
  MQTT.publish("net/eth", NETWORK.isEthConnected() ? "on" : "off")
  MQTT.publish("net/wifi", NETWORK.isWifiConnected() ? "on" : "off")
end, 60000)
```

## See Also

- [PING](ping.md) — Check reachability of hosts on the network
- [WG](wg.md) — WireGuard VPN tunnel state
- [MQTT](mqtt.md) — Combine: publish the network state
