# UDP_CLIENT — UDP Datagram Client Class

> Available since: v3.3.8.dev8 · ESP32-S3 devices only (U series, Ultima)

Send UDP datagrams from a script and receive the replies: query DNS-like services, drive WLED/Art-Net style controllers, talk to anything that speaks connectionless UDP.

`UDP_CLIENT` is a **class** (companion of [`TCP_CLIENT`](tcpclient.md)): create as many instances as you need with `UDP_CLIENT()`. The socket is created by the first `send()`, and replies to that socket can then be read with `read()`. When an instance is garbage-collected or the script stops, the socket is closed and its memory (PSRAM) is freed automatically.

## Quick Example

```berry
import NETWORK

NETWORK.waitReady(0xff)

var udp = UDP_CLIENT()
udp.send("192.168.1.60", 4210, "ping")
if udp.waitAvailable(1000) > 0
  SLZB.log("reply from " .. udp.remoteIp() .. ": " .. udp.read())
end
udp.close()
```

## API Reference

### Class UDP_CLIENT

An outgoing UDP socket. Constructor: `UDP_CLIENT()`.

| Function | Description |
|----------|-------------|
| `UDP_CLIENT.send(host:string, port:int, data:string) -> bool` | Send one datagram to `host` (IP or DNS name); `bytes()` values are accepted too. Returns: `bool` — `false` if the packet could not be sent. Raises an error if the network is not ready yet — call `NETWORK.waitReady()` first. |
| `UDP_CLIENT.available() -> int` | Size of the datagram waiting to be read, `0` if none. |
| `UDP_CLIENT.waitAvailable(timeout:int) -> int` | Block up to `timeout` ms until a datagram arrives. Returns: `int` — its size, `0` on timeout. |
| `UDP_CLIENT.read(max_len:int?) -> string` | Read the pending datagram (**one datagram per call**, up to `max_len` bytes, default/maximum 4096) without blocking. Returns: `string` — the payload (may contain any bytes), `""` if nothing arrived. |
| `UDP_CLIENT.readBytes(max_len:int?) -> bytes` | Same as `read()` but returns a `bytes()` object — convenient for binary protocols. |
| `UDP_CLIENT.reply(data:string) -> bool` | Send a datagram back to the source of the last received one; `bytes()` accepted too. Returns: `bool` — `false` if nothing was received yet or sending failed. |
| `UDP_CLIENT.remoteIp() -> string` | Source IP of the last received datagram, `"0.0.0.0"` before the first one. |
| `UDP_CLIENT.remotePort() -> int` | Source port of the last received datagram, `0` before the first one. |
| `UDP_CLIENT.close() -> nil` | Close the socket. The next `send()` opens a fresh one. |

## Notes

- ESP32-S3 devices only (U series, MRU, Ultima). The socket object and read buffers live in PSRAM.
- No `import` is needed — `UDP_CLIENT` is a global class, just call `UDP_CLIENT()`.
- UDP is connectionless: there is no `connect()`/`connected()`, every `send()` names the destination, and delivery is **not guaranteed** — design for lost packets (retry, timeouts).
- Replies can only arrive after the first `send()` created the socket. To *listen first* on a known port, use [`UDP_SERVER`](udpserver.md).
- `read()`/`readBytes()` return **one whole datagram per call** (up to `max_len`; the cut-off tail of an oversized datagram is dropped). Datagrams don't merge like a TCP stream.
- `read()`/`readBytes()`/`send()` are binary-safe: payloads may contain any byte values, `send()`/`reply()` accept both `string` and `bytes`.
- `waitAvailable()` blocks the script (not the firmware) — keep the timeout reasonable.

## Examples

### Wake-on-LAN style magic packet (binary payload)

```berry
import NETWORK

NETWORK.waitReady(0xff)

var mac = bytes("A1B2C3D4E5F6")
var pkt = bytes("FFFFFFFFFFFF")
for i: 0 .. 15 pkt += mac end

var udp = UDP_CLIENT()
udp.send("192.168.1.255", 9, pkt)
```

### Query a UDP service with a retry

```berry
import NETWORK

NETWORK.waitReady(0xff)

var udp = UDP_CLIENT()
var reply = ""

for attempt: 1 .. 3
  udp.send("192.168.1.60", 8888, "status?")
  if udp.waitAvailable(500) > 0
    reply = udp.read()
    break
  end
end

SLZB.log(reply != "" ? "reply: " .. reply : "no reply after 3 attempts")
```

## See Also

- [UDP_SERVER](udpserver.md) — Listen for datagrams on a known port (multicast supported)
- [TCP_CLIENT](tcpclient.md) — Reliable stream connections instead of datagrams
- [NETWORK](network.md) — Wait for the network before sending
- [WOL](wol.md) — Ready-made Wake-on-LAN module
