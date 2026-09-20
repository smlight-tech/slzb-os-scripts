# TCP_SERVER — Raw TCP Server Class

> Available since: v3.3.8.dev8 · ESP32-S3 devices only (U series, Ultima)

Run a TCP server inside a script: listen on a port, accept clients and exchange raw (binary-safe) data with them. Build custom text protocols, tiny telnet-style consoles, bridges to other software on your LAN.

`TCP_SERVER` is a **class** (like Tasmota's `tcpserver`): `TCP_SERVER(port)` creates a server that starts listening immediately, `accept()` hands each incoming connection to you as a [`TCP_CLIENT`](tcpclient.md) instance. When a server instance is garbage-collected or the script stops, the listening socket is closed and its memory (PSRAM) is freed automatically.

## Quick Example

```berry
# a tiny echo server on port 4000
import NETWORK
import TIMER

NETWORK.waitReady(0xff)

var srv = TCP_SERVER(4000)
var clients = []

TIMER.setInterval(def ()
  var cln = srv.accept()
  if cln != nil
    SLZB.log("client connected from " .. cln.remoteIp())
    clients.push(cln)
  end

  var i = 0
  while i < clients.size()
    if !clients[i].connected()
      clients.remove(i)
      continue
    end
    if clients[i].available() > 0
      clients[i].write(clients[i].read())   # echo back
    end
    i += 1
  end
end, 50)
```

## API Reference

### Class TCP_SERVER

A listening TCP server. Constructor: `TCP_SERVER(port:int, max_clients:int?)` — starts listening right away (`max_clients` 1..16, default 4). Raises an error if the port cannot be opened or the network is not ready yet — call `NETWORK.waitReady()` first.

| Function | Description |
|----------|-------------|
| `TCP_SERVER.hasClient() -> bool` | `true` when a new incoming connection is waiting to be accepted. |
| `TCP_SERVER.accept() -> TCP_CLIENT` | Accept the next incoming connection. Returns: a connected [`TCP_CLIENT`](tcpclient.md) instance, or `nil` when nobody is waiting. Call it regularly (e.g. from a timer). |
| `TCP_SERVER.close() -> nil` | Stop listening. Already accepted `TCP_CLIENT` connections stay alive. |

## Notes

- ESP32-S3 devices only (U series, MRU, Ultima). The server object lives in PSRAM.
- No `import` is needed — `TCP_SERVER` is a global class, just call `TCP_SERVER(port)`.
- Create the server only after the network is up: `NETWORK.waitReady(0xff)` — the constructor raises an error otherwise.
- Accepted connections are ordinary [`TCP_CLIENT`](tcpclient.md) instances: `read()`, `write()`, `connected()`, `close()`, `remoteIp()` all work on them. Keep the instances you get from `accept()` (e.g. in a list) — an instance dropped from all variables is garbage-collected and its connection closes.
- Nothing happens in the background: call `accept()` and `read()` yourself, e.g. from a `TIMER.setInterval` loop.
- The port must not collide with the ports the firmware already uses (80 web, Zigbee socket ports, etc.).
- When the script stops, the server and every accepted connection are cleaned up automatically.

## Examples

### Line-based command console (single client)

```berry
import NETWORK
import TIMER
import string

NETWORK.waitReady(0xff)

var srv = TCP_SERVER(2323, 1)
var cln = nil
var buf = ""

TIMER.setInterval(def ()
  var newCln = srv.accept()
  if newCln != nil
    cln = newCln
    buf = ""
    cln.write("SLZB-06 console. Commands: uptime, quit\r\n> ")
  end

  if cln == nil || cln.available() == 0 return end
  buf += cln.read()

  var nl = string.find(buf, "\n")
  if nl < 0 return end

  var line = string.tr(buf[0 .. nl], "\r\n", "")
  buf = buf[nl + 1 ..]

  if line == "uptime"
    cln.write(str(SLZB.millis() / 1000) .. " s\r\n> ")
  elif line == "quit"
    cln.close()
    cln = nil
  else
    cln.write("unknown command\r\n> ")
  end
end, 50)
```

### Push sensor data to every connected client

```berry
import NETWORK
import TIMER

NETWORK.waitReady(0xff)

var srv = TCP_SERVER(5000)
var clients = []

TIMER.setInterval(def ()
  var cln = srv.accept()
  if cln != nil clients.push(cln) end

  var line = "uptime=" .. str(SLZB.millis() / 1000) .. " heap=" .. str(SLZB.freeHeap()) .. "\n"
  var i = 0
  while i < clients.size()
    if clients[i].connected()
      clients[i].write(line)
      i += 1
    else
      clients.remove(i)
    end
  end
end, 5000)
```

## See Also

- [TCP_CLIENT](tcpclient.md) — The class `accept()` returns; also outgoing connections
- [NETWORK](network.md) — Wait for the network before starting the server
- [WEBSERVER](webserver.md) — Receive HTTP requests instead of raw TCP
- [TIMER](timer.md) — Poll `accept()`/`read()` from a timer
