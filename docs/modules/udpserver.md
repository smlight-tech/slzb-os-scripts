# UDP_SERVER — UDP Datagram Server Class

> Available since: v3.3.8.dev8 · ESP32-S3 devices only (U series, Ultima)

Listen for UDP datagrams on a known port: receive announcements and sensor broadcasts, answer discovery requests, join multicast groups (SSDP-style protocols, WLED sync, etc.).

`UDP_SERVER` is a **class** (companion of [`TCP_SERVER`](tcpserver.md)): `UDP_SERVER(port)` binds the port and starts receiving immediately; `UDP_SERVER(port, group)` additionally joins a multicast group. Datagrams are read one at a time with `read()`, and `reply()` answers the sender of the last one. When an instance is garbage-collected or the script stops, the socket is closed and its memory (PSRAM) is freed automatically.

## Quick Example

```berry
# answer "ping" datagrams on port 4210
import NETWORK
import TIMER

NETWORK.waitReady(0xff)

var srv = UDP_SERVER(4210)

TIMER.setInterval(def ()
  var msg = srv.read()
  if msg == "" return end

  SLZB.log("from " .. srv.remoteIp() .. ": " .. msg)
  if msg == "ping"
    srv.reply("pong")
  end
end, 50)
```

## API Reference

### Class UDP_SERVER

A listening UDP socket. Constructor: `UDP_SERVER(port:int, group:string?)` — binds the port right away; with `group` (e.g. `"239.255.255.250"`) it joins that multicast group. Raises an error if the port cannot be opened or the network is not ready yet — call `NETWORK.waitReady()` first.

| Function | Description |
|----------|-------------|
| `UDP_SERVER.available() -> int` | Size of the datagram waiting to be read, `0` if none. |
| `UDP_SERVER.waitAvailable(timeout:int) -> int` | Block up to `timeout` ms until a datagram arrives. Returns: `int` — its size, `0` on timeout. |
| `UDP_SERVER.read(max_len:int?) -> string` | Read the pending datagram (**one datagram per call**, up to `max_len` bytes, default/maximum 4096) without blocking. Returns: `string` — the payload (may contain any bytes), `""` if nothing arrived. |
| `UDP_SERVER.readBytes(max_len:int?) -> bytes` | Same as `read()` but returns a `bytes()` object — convenient for binary protocols. |
| `UDP_SERVER.reply(data:string) -> bool` | Send a datagram back to the source of the last received one; `bytes()` accepted too. Returns: `bool` — `false` if nothing was received yet or sending failed. |
| `UDP_SERVER.send(host:string, port:int, data:string) -> bool` | Send a datagram to an arbitrary destination from the same socket; `bytes()` accepted too. Returns: `bool` — `false` if the packet could not be sent. |
| `UDP_SERVER.remoteIp() -> string` | Source IP of the last received datagram, `"0.0.0.0"` before the first one. |
| `UDP_SERVER.remotePort() -> int` | Source port of the last received datagram, `0` before the first one. |
| `UDP_SERVER.close() -> nil` | Stop listening and close the socket. Create a new instance to listen again. |

## Notes

- ESP32-S3 devices only (U series, MRU, Ultima). The socket object and read buffers live in PSRAM.
- No `import` is needed — `UDP_SERVER` is a global class, just call `UDP_SERVER(port)`.
- Nothing happens in the background: poll `read()` yourself, e.g. from a `TIMER.setInterval` loop, or block with `waitAvailable()`.
- `read()`/`readBytes()` return **one whole datagram per call** (up to `max_len`; the cut-off tail of an oversized datagram is dropped). Call `remoteIp()`/`remotePort()` right after reading — the next datagram overwrites them.
- UDP delivery is **not guaranteed** and `reply()` may silently vanish on the network — that's the protocol, not an error.
- The port must not collide with the ports the firmware already uses.
- When the script stops, the socket is closed and the PSRAM instance is freed automatically.

## Examples

### Simple discovery responder (multicast)

```berry
import NETWORK
import TIMER

NETWORK.waitReady(0xff)

var srv = UDP_SERVER(1900, "239.255.255.250")

TIMER.setInterval(def ()
  var msg = srv.read()
  if msg == "" return end

  import string
  if string.find(msg, "M-SEARCH") >= 0
    srv.reply("SLZB-06 " .. NETWORK.getIp())
  end
end, 100)
```

### Collect broadcast sensor readings and publish to MQTT

```berry
import NETWORK
import TIMER
import MQTT

NETWORK.waitReady(0xff)

var srv = UDP_SERVER(9999)

TIMER.setInterval(def ()
  while true
    var msg = srv.read()
    if msg == "" break end
    MQTT.publish("udp/" .. srv.remoteIp(), msg)
  end
end, 200)
```

## See Also

- [UDP_CLIENT](udpclient.md) — Send datagrams first, then read the replies
- [TCP_SERVER](tcpserver.md) — Reliable stream connections instead of datagrams
- [NETWORK](network.md) — Wait for the network before binding the port
- [MQTT](mqtt.md) — Combine: forward received datagrams
