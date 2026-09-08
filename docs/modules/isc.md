# ISC Module

Inter-script communication — exchange messages between running Berry scripts through numbered channels. Each channel is a thread-safe FIFO queue, so one script can safely produce data while another consumes it.

Supported message types: `int`, `real`, `string`.

A channel must be **claimed** before writing to it (`ISC.claim`): **private** — a single writer owns the channel, or **public** — every script that wants to write claims the same channel. Reading needs no claim — anyone can listen.

## Setup

No configuration needed — just import the module in every script that takes part:

```berry
import ISC
```

Pick a channel number (0–100), claim it in the writer script, and use the same number on both sides. A channel is created automatically on first use and holds up to 8 pending messages.

```berry
import ISC
ISC.claim(1, ISC.CH_TYPE_PRIVATE)   # this script is the only writer of channel 1
ISC.send(1, "hello")
```

> Channels 101–255 are reserved for the apps system — any call with a reserved channel raises an error.

## API Reference

| Function | Description |
|----------|-------------|
| `ISC.claim(channel:int, ch_type:int) -> bool` | Claim a channel for writing (private or public). |
| `ISC.release(channel:int) -> bool` | Release this script's claim on a channel. |
| `ISC.send(channel:int, value:int\|real\|string) -> bool` | Send an int, real or string message to a claimed channel. Non-blocking. |
| `ISC.receive(channel:int, timeout_ms:int=0) -> int\|real\|string` | Receive the next message from a channel, waiting up to `timeout_ms`. |
| `ISC.available(channel:int) -> int` | Number of messages waiting in a channel. |
| `ISC.clear(channel:int) -> nil` | Drop all pending messages in a channel. |

### ISC.claim(channel:int, ch_type:int) -> bool

Claim a channel before writing to it.

| Parameter | Type | Description |
|-----------|------|-------------|
| `channel` | int | Channel id, 0–100 |
| `ch_type` | int | `ISC.CH_TYPE_PRIVATE` — single writer, or `ISC.CH_TYPE_PUBLIC` — shared writers |

**Returns:** `bool` — `true` if the claim succeeded; `false` if the channel is already taken: a private channel claimed by another script, a type mismatch, or no writer slots left

- **Private** channel: the claiming script becomes the only writer. `claim()` from any other script returns `false` — that means the channel is busy.
- **Public** (broadcast) channel: several scripts can write — each writer calls `claim(ch, ISC.CH_TYPE_PUBLIC)` on the same channel.
- Repeating `claim()` from the same script is a no-op and returns `true`.
- The claim is released automatically when the script stops.

```berry
import ISC

if !ISC.claim(1, ISC.CH_TYPE_PRIVATE)
    # channel 1 is already taken by another script
end

ISC.claim(2, ISC.CH_TYPE_PUBLIC)   # join channel 2 as one of several writers
```

### ISC.release(channel:int) -> bool

Manually release this script's claim. The channel becomes free again when its last claimer releases it (or stops). Pending messages are kept in the queue.

| Parameter | Type | Description |
|-----------|------|-------------|
| `channel` | int | Channel id, 0–100 |

**Returns:** `bool` — `false` if the calling script was not a claimer of this channel

```berry
import ISC
ISC.release(1)
```

### ISC.send(channel:int, value:int\|real\|string) -> bool

Send a message to a channel claimed by this script. Never blocks. Raises an error if the channel is not claimed, or is claimed by another script (private).

| Parameter | Type | Description |
|-----------|------|-------------|
| `channel` | int | Channel id, 0–100 (101–255 are reserved for the system) |
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
| `channel` | int | Channel id, 0–100 (101–255 are reserved for the system) |
| `timeout_ms` | int | (optional) How long to wait, milliseconds. `0` (default) — return immediately; `ISC.TIMEOUT_FOREVER` (`-1`) — wait forever |

**Returns:** the received `int`, `real` or `string`, or `nil` if no message arrived within the timeout

```berry
import ISC

var v = ISC.receive(1)             # poll, nil if empty
var v = ISC.receive(1, 5000)       # wait up to 5 seconds
var v = ISC.receive(1, ISC.TIMEOUT_FOREVER)  # block until a message arrives
```

### ISC.available(channel:int) -> int

Get the number of messages currently waiting in a channel.

| Parameter | Type | Description |
|-----------|------|-------------|
| `channel` | int | Channel id, 0–100 (101–255 are reserved for the system) |

**Returns:** `int` — pending message count (0–8)

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
| `channel` | int | Channel id, 0–100 (101–255 are reserved for the system) |

```berry
import ISC
ISC.clear(1)
```

## Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `ISC.TIMEOUT_FOREVER` | -1 | Pass as `timeout_ms` to `receive()` to wait forever |
| `ISC.MAX_CHANNEL` | 100 | Highest channel id available to scripts |
| `ISC.CH_TYPE_PRIVATE` | 1 | Channel with a single writer |
| `ISC.CH_TYPE_PUBLIC` | 2 | Broadcast channel — several scripts may claim and write |

## Examples

### Producer script — publish sensor data

```berry
import ISC
import TIMER
import WEATHER

ISC.claim(10, ISC.CH_TYPE_PRIVATE)   # this script is the only writer

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

ISC.claim(20, ISC.CH_TYPE_PRIVATE)

BUTTON.on_press(0, def (press_type)
    ISC.send(20, "press:" .. str(press_type))
end)
```

```berry
# Script B — main flow blocks waiting for commands
import ISC
import SLZB

while true
    var cmd = ISC.receive(20, ISC.TIMEOUT_FOREVER)
    if cmd == "press:1"
        SLZB.log("button pressed in script A")
    end
end
```

### Request/response between two scripts

```berry
# Script A — request on channel 30, response on channel 31
# (script B claims channel 31 and answers)
import ISC
import SLZB

ISC.claim(30, ISC.CH_TYPE_PRIVATE)
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
- Channels are global — agree on channel numbers between your scripts. Writing requires a claim; reading is open to every script
- A script's claims are released automatically when the script stops (the channel frees up once its last claimer is gone); pending messages stay in the queue until received or cleared
- Scripts may use channels 0–100 only; 101–255 are reserved for the apps system and raise an error if used
- `send()` never blocks — on a full channel it returns `false` immediately (drain with `receive()` or `clear()`)
- A blocking `receive()` blocks the whole calling script — its timers and event callbacks do not run until a message arrives
- IMPORTANT: timer and event callbacks of ALL scripts are serialized — a long blocking `receive()` inside a `TIMER` or event callback stalls callbacks of every script, including the sender's, and can deadlock until the timeout. Inside callbacks use `timeout_ms = 0` (poll); block with `ISC.TIMEOUT_FOREVER` only allowed in the main script flow without timers
- Messages survive the sender script stopping, but a channel keeps its pending messages until they are received or cleared — call `clear()` at script start if stale data is a concern
