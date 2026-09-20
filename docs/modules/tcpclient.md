# TCP_CLIENT — Raw TCP Client Class

> Available since: v3.3.8.dev8 · ESP32-S3 devices only (U series, Ultima)

Open outgoing TCP connections from a script and exchange raw (binary-safe) data: talk to devices and services that speak plain TCP instead of HTTP — industrial gear, media players, LED controllers, your own daemons.

`TCP_CLIENT` is a **class** (like Tasmota's `tcpclient`): create as many instances as you need with `TCP_CLIENT()`, each one is an independent connection. An instance is also what [`TCP_SERVER.accept()`](tcpserver.md) returns for an incoming connection. When an instance is garbage-collected or the script stops, its connection is closed and its memory (PSRAM) is freed automatically.

## Quick Example

```berry
import NETWORK

NETWORK.waitReady(0xff)

var tcp = TCP_CLIENT()
if tcp.connect("192.168.1.50", 9100)
  tcp.write("STATUS\n")
  if tcp.waitAvailable(2000) > 0
    SLZB.log("reply: " .. tcp.read())
  end
  tcp.close()
end
```

## API Reference

### Class TCP_CLIENT

An outgoing TCP connection. Constructor: `TCP_CLIENT()` — creates a disconnected client.

| Function | Description |
|----------|-------------|
| `TCP_CLIENT.connect(host:string, port:int, timeout:int?) -> bool` | Connect to `host` (IP or DNS name). `timeout` in ms, default 5000. Calling it while connected drops the old connection first. Returns: `bool` — `false` if the connection failed. Raises an error if the network is not ready yet — call `NETWORK.waitReady()` first. |
| `TCP_CLIENT.connected() -> bool` | `true` while the connection is alive. |
| `TCP_CLIENT.close() -> nil` | Disconnect. The instance stays usable — call `connect()` again to reconnect. |
| `TCP_CLIENT.available() -> int` | Number of received bytes waiting to be read. |
| `TCP_CLIENT.waitAvailable(timeout:int) -> int` | Block up to `timeout` ms until data arrives. Returns: `int` — available bytes, `0` on timeout or disconnect. |
| `TCP_CLIENT.read(max_len:int?) -> string` | Read the received data (up to `max_len` bytes, default/maximum 4096) without blocking. Returns: `string` — the data (may contain any bytes), `""` if nothing is available. |
| `TCP_CLIENT.readBytes(max_len:int?) -> bytes` | Same as `read()` but returns a `bytes()` object — convenient for binary protocols. |
| `TCP_CLIENT.write(data:string) -> int` | Send data; `bytes()` values are accepted too. Returns: `int` — bytes actually sent, `0` if disconnected. |
| `TCP_CLIENT.remoteIp() -> string` | IP address of the peer, `"0.0.0.0"` when not connected. |
| `TCP_CLIENT.remotePort() -> int` | TCP port of the peer, `0` when not connected. |

## Notes

- ESP32-S3 devices only (U series, MRU, Ultima). The underlying connection object and read buffers live in PSRAM.
- No `import` is needed — `TCP_CLIENT` is a global class, just call `TCP_CLIENT()`.
- Connect only after the network is up: `NETWORK.waitReady(0xff)` — `connect()` raises an error otherwise.
- `read()` / `readBytes()` / `write()` are binary-safe: the string may contain any byte values, `write()` accepts both `string` and `bytes`.
- `waitAvailable()` blocks the script (not the firmware) — keep the timeout reasonable so the script stays responsive to its other events.
- Plain TCP only, no TLS. For HTTPS use the [HTTP](http.md) module.
- A dropped connection is not re-established automatically — check `connected()` and `connect()` again.
- Instances are cleaned up by the garbage collector (connection closed, PSRAM freed) — at the latest when the script stops. Call `close()` yourself as soon as you are done, don't wait for the GC.

## Examples

### Request/response over a raw control port

```berry
import NETWORK

NETWORK.waitReady(0xff)
var tv = TCP_CLIENT()

def tvCmd(cmd)
  if !tv.connected()
    if !tv.connect("192.168.1.20", 20060, 2000) return "" end
  end
  tv.write(cmd)
  tv.waitAvailable(1000)
  return tv.read()
end

SLZB.log(tvCmd("*SCPOWR0000000000000001\n"))
```

### Binary protocol with bytes()

```berry
import NETWORK

NETWORK.waitReady(0xff)

var tcp = TCP_CLIENT()
if tcp.connect("192.168.1.30", 502)            # e.g. Modbus TCP
  var req = bytes("000100000006010300000002")  # transaction 1, read 2 holding registers
  tcp.write(req)

  if tcp.waitAvailable(1000) > 0
    var resp = tcp.readBytes()
    SLZB.log("register 0: " .. str(resp.get(9, -2)))  # big-endian u16 at offset 9
  end
  tcp.close()
end
```

### Two connections at the same time

```berry
import NETWORK

NETWORK.waitReady(0xff)

var a = TCP_CLIENT()
var b = TCP_CLIENT()
a.connect("192.168.1.5", 5140)
b.connect("192.168.1.6", 5140)

var line = "slzb heap=" .. str(SLZB.freeHeap()) .. "\n"
a.write(line)
b.write(line)
a.close()
b.close()
```

## See Also

- [TCP_SERVER](tcpserver.md) — Accept incoming raw TCP connections (its `accept()` returns a `TCP_CLIENT`)
- [NETWORK](network.md) — Wait for the network before connecting
- [HTTP](http.md) — HTTP/HTTPS requests instead of raw TCP
- [PING](ping.md) — Check the host is reachable first
