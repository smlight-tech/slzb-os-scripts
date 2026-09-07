# ISC Module

Inter-script communication — exchange messages between running Berry scripts through numbered channels. Each channel is a thread-safe FIFO queue, so one script can safely produce data while another consumes it.

Supported message types: `int`, `real`, `string`.

## Setup

No configuration needed — just import the module in every script that takes part:

```berry
import ISC
```

Pick a channel number (0–255) and use the same number on both sides. A channel is created automatically on first use and holds up to 8 pending messages.

## API Reference

| Function | Description |
|----------|-------------|
| `ISC.send(channel:int, value:int\|real\|string) -> bool` | Send an int, real or string message to a channel. Non-blocking. |
| `ISC.receive(channel:int, timeout_ms:int=0) -> int\|real\|string` | Receive the next message from a channel, waiting up to `timeout_ms`. |
| `ISC.available(channel:int) -> int` | Number of messages waiting in a channel. |
| `ISC.clear(channel:int) -> nil` | Drop all pending messages in a channel. |

### ISC.send(channel:int, value:int\|real\|string) -> bool

Send a message to a channel. Never blocks.

| Parameter | Type | Description |
|-----------|------|-------------|
| `channel` | int | Channel id, 0–255 |
| `value` | any | Message: `int`, `real` or `string` (max 64 KB) |

**Returns:** `bool` — `true` if the message was queued, `false` if the channel is full (8 pending messages) or out of memory

```berry
import ISC

ISC.send(1, 42)              # int
ISC.send(1, 21.5)            # real
ISC.send(1, "hello there")   # string
```

### ISC.receive(channel:int, timeout_ms:int=0) -> int\|real\|string

Receive the oldest message from a channel (FIFO order). Blocks the calling script until a message arrives or the timeout expires.

| Parameter | Type | Description |
|-----------|------|-------------|
| `channel` | int | Channel id, 0–255 |
| `timeout_ms` | int | (optional) How long to wait, milliseconds. `0` (default) — return immediately; `ISC.FOREVER` (`-1`) — wait forever |

**Returns:** the received `int`, `real` or `string`, or `nil` if no message arrived within the timeout

```berry
import ISC

var v = ISC.receive(1)             # poll, nil if empty
var v = ISC.receive(1, 5000)       # wait up to 5 seconds
var v = ISC.receive(1, ISC.FOREVER)  # block until a message arrives
```

### ISC.available(channel:int) -> int

Get the number of messages currently waiting in a channel.

| Parameter | Type | Description |
|-----------|------|-------------|
| `channel` | int | Channel id, 0–255 |

**Returns:** `int` — pending message count (0–16)

```berry
import ISC
import SLZB

if ISC.available(1) > 0
    SLZB.log("message waiting: " .. str(ISC.receive(1)))
end
```

### ISC.clear(channel:int) -> nil

Drop all pending messages in a channel.

| Parameter | Type | Description |
|-----------|------|-------------|
| `channel` | int | Channel id, 0–255 |

```berry
import ISC
ISC.clear(1)
```

## Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `ISC.TIMEOUT_FOREVER` | -1 | Pass as `timeout_ms` to `receive()` to wait forever |

## Examples

### Producer script — publish sensor data

```berry
import ISC
import TIMER
import WEATHER

TIMER.setInterval(def()
    var w = WEATHER.get()
    if !ISC.send(10, w["temp"])
        # channel full — consumer is not keeping up
    end
end, 60000)
```

### Consumer script — react to the data

```berry
import ISC
import TIMER
import SLZB

TIMER.setInterval(def()
    # drain everything that arrived since the last tick
    while ISC.available(10) > 0
        var temp = ISC.receive(10)
        SLZB.log("temperature from producer: " .. str(temp))
    end
end, 5000)
```

### Command channel between scripts

```berry
# Script A — sends commands
import ISC
import BUTTON

BUTTON.on_press(0, def (press_type)
    ISC.send(20, "press:" .. str(press_type))
end)
```

```berry
# Script B — main flow blocks waiting for commands
import ISC
import SLZB

while true
    var cmd = ISC.receive(20, ISC.FOREVER)
    if cmd == "press:1"
        SLZB.log("button pressed in script A")
    end
end
```

### Request/response between two scripts

```berry
# Script A — request on channel 30, response on channel 31
import ISC
import SLZB

ISC.send(30, "get_status")
var answer = ISC.receive(31, 2000)
if answer != nil
    SLZB.log("reply: " .. str(answer))
else
    SLZB.log("no reply in 2 s")
end
```

## Notes

- Available only on U series, MRU series and Ultima
- Channels are global: any script can send to or receive from any channel — agree on channel numbers between your scripts
- `send()` never blocks — on a full channel it returns `false` immediately (drain with `receive()` or `clear()`)
- A blocking `receive()` blocks the whole calling script — its timers and event callbacks do not run until a message arrives
- IMPORTANT: timer and event callbacks of ALL scripts are serialized — a long blocking `receive()` inside a `TIMER` or event callback stalls callbacks of every script, including the sender's, and can deadlock until the timeout. Inside callbacks use `timeout_ms = 0` (poll); block with `ISC.FOREVER` only allowed in the main script flow without timers
- Messages survive the sender script stopping, but a channel keeps its pending messages until they are received or cleared — call `clear()` at script start if stale data is a concern
