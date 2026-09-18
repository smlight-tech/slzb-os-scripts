# WG — WireGuard VPN Client (Status, Reconnect, Events)

> Available since: v3.3.8.dev8

Monitor the built-in WireGuard VPN client from a script: tunnel and peer state, time of the latest handshake, a forced reconnect and a callback on every state change.

The tunnel itself (keys, endpoint, local address) is configured on the *VPN* page. The module does not change the settings — with VPN switched off every function returns an "empty" value (`false` / `0` / `""`).

## Quick Example

```berry
import WG

# log every change of the VPN state
WG.on_state(def (state)
  if state == WG.STATE_UP
    SLZB.log("VPN is up, local address " .. WG.getLocalIp())
  elif state == WG.STATE_NO_PEER
    SLZB.log("VPN peer is offline")
  end
end)
```

## API Reference

### Status

| Function | Description |
|----------|-------------|
| `WG.isEnabled() -> bool` | `true` if VPN is switched on in the settings. |
| `WG.getStatus() -> int` | Current tunnel state, one of the `WG.STATE_*` constants. |
| `WG.isPeerUp() -> bool` | `true` while there is a valid handshake with the peer, i.e. traffic can pass. Live check. |
| `WG.getLastHandshake() -> int` | Unix time of the latest completed handshake, `0` if there was none since the last (re)connect. |
| `WG.getHandshakeAge() -> int` | Seconds since the latest completed handshake, `-1` if there was none. |
| `WG.getUptime() -> int` | Seconds the peer has been online without a break, `0` if it is offline. |
| `WG.getConnectCount() -> int` | How many times the tunnel was started since boot (1 = never reconnected). |
| `WG.getLocalIp() -> string` | Tunnel address of the device with the prefix, e.g. `"10.0.0.2/24"`. `""` if VPN is switched off or WireGuard was not started yet. |
| `WG.getEndpoint() -> string` | Configured server endpoint, e.g. `"vpn.example.com:51820"`. `""` if VPN is switched off or WireGuard was not started yet. |

### Control & Events

| Function | Description |
|----------|-------------|
| `WG.reconnect() -> bool` | Drop the tunnel and start it again right away: new handshake, the endpoint host name is resolved again. Non-blocking. Returns: `bool` — `false` if WireGuard is not running (disabled, init failed or still waiting for the network at boot). |
| `WG.on_state(callback:function(state:int) -> nil) -> nil` | Register a callback fired on every change of the tunnel state (`WG.STATE_*`). |

## Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `WG.STATE_DISABLED` | 0 | VPN is switched off in the settings |
| `WG.STATE_ERROR` | 1 | WireGuard could not be initialised: invalid keys, address or endpoint port. Fix the settings on the VPN page. |
| `WG.STATE_CONNECTING` | 2 | Tunnel interface is down: waiting for the network / time sync, or between reconnect attempts |
| `WG.STATE_NO_PEER` | 3 | Tunnel interface is up, no valid handshake with the peer (yet) |
| `WG.STATE_UP` | 4 | Peer is online, traffic can pass |

## Notes

- The firmware already keeps the tunnel alive on its own: it reconnects when the peer stays offline for 15 s, when the optional ping watchdog (VPN page) loses 5 replies in a row, when the network goes down and when the uplink changes (Ethernet / Wi-Fi / LTE failover). `reconnect()` is for cases the firmware cannot see, e.g. the server was re-deployed with a new address behind the same host name.
- `getStatus()` and `on_state` follow the tunnel supervisor, which checks the peer every 5 s — a state change is reported with up to 5 s delay. `isPeerUp()` asks WireGuard directly.
- WireGuard has no "connected" flag: a peer counts as online while the latest handshake is fresh (handshakes are renewed about every 2 minutes while traffic or keepalives flow; keepalive is sent every 15 s).
- After `reconnect()` the state goes `STATE_CONNECTING` → `STATE_NO_PEER` → `STATE_UP`; with a reachable server this takes a few seconds.
- WireGuard needs a valid clock: until the time is synchronised after boot the state stays `STATE_CONNECTING`.
- Only hosts inside the tunnel subnet (local address + prefix) are routed through the VPN.

## Examples

### Notify when the VPN goes down for more than a minute

```berry
import WG
import TIMER
import TELEGRAM

var downSince = 0
var reported = false

TIMER.setInterval(def ()
  if !WG.isEnabled() return end

  if WG.isPeerUp()
    if reported TELEGRAM.send("VPN is back") end
    downSince = 0
    reported = false
  else
    downSince += 10
    if downSince >= 60 && !reported
      reported = true
      TELEGRAM.send("VPN is down, state " .. WG.getStatus())   # delivered over the regular uplink
    end
  end
end, 10000)
```

### Reconnect when a host behind the VPN stops answering

```berry
import WG
import PING
import TIMER

var fails = 0

TIMER.setInterval(def ()
  if WG.getStatus() != WG.STATE_UP
    fails = 0
    return
  end

  if PING.alive("10.0.0.1")
    fails = 0
  else
    fails += 1
    if fails >= 3
      SLZB.log("VPN host is unreachable, reconnecting WireGuard")
      WG.reconnect()
      fails = 0
    end
  end
end, 30000)
```

### Publish the VPN state to MQTT

```berry
import WG
import MQTT

WG.on_state(def (state)
  MQTT.publish("vpn/state", str(state))
  MQTT.publish("vpn/reconnects", str(WG.getConnectCount() - 1))
end)
```

## See Also

- [PING](ping.md) — Combine: check hosts behind the tunnel
- [LTE](lte.md) — 4G/LTE add-on modem: WireGuard follows the uplink failover automatically
- [MQTT](mqtt.md) — Combine: publish the VPN state
