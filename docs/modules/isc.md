# ISC Module

Inter-script communication — exchange messages between running Berry scripts through numbered channels. Each channel is a thread-safe FIFO queue, so one script can safely produce data while another consumes it.

Supported message types: `int`, `real`, `string`, `bytes`.

A channel must be **claimed** before writing to it (`ISC.claim`): **private** — a single writer owns the channel, or **public** — every script that wants to write claims the same channel. Reading needs no claim — anyone can listen, but each message is delivered to **one** reader (whoever receives it first).

To deliver every message to **several** scripts, use a **broadcast** channel: one writer claims it with `ISC.CH_TYPE_BROADCAST`, and every reader calls `ISC.subscribe()` — each subscriber gets its own copy of every message. See [Broadcast Channels](#broadcast-channels).

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
| `ISC.claim(channel:int, ch_type:int) -> bool` | Claim a channel for writing (private, public or broadcast). |
| `ISC.release(channel:int) -> bool` | Release this script's claim on a channel. |
| `ISC.send(channel:int, value:int\|real\|string\|bytes) -> bool\|int` | Send an int, real, string or bytes message to a claimed channel. Non-blocking. Returns: `bool` for private/public channels, `int` (number of subscribers reached) for broadcast channels. |
| `ISC.receive(channel:int, timeout_ms:int=0) -> int\|real\|string\|bytes` | Receive the next message from a channel, waiting up to `timeout_ms`. |
| `ISC.available(channel:int) -> int` | Number of messages waiting in a channel. |
| `ISC.clear(channel:int) -> nil` | Drop all pending messages in a channel. |
| `ISC.subscribe(channel:int) -> bool` | Subscribe to a broadcast channel: from now on this script gets its own copy of every message. |
| `ISC.unsubscribe(channel:int) -> bool` | Stop receiving a broadcast channel; pending copies are dropped. |

### ISC.claim(channel:int, ch_type:int) -> bool

Claim a channel before writing to it.

| Parameter | Type | Description |
|-----------|------|-------------|
| `channel` | int | Channel id, 0–100 |
| `ch_type` | int | `ISC.CH_TYPE_PRIVATE` — single writer, `ISC.CH_TYPE_PUBLIC` — shared writers, or `ISC.CH_TYPE_BROADCAST` — single writer, every subscriber gets each message |

**Returns:** `bool` — `true` if the claim succeeded; `false` if the channel is already taken: a private/broadcast channel claimed by another script, a type mismatch, no writer slots left, or the channel has subscribers and the type is not broadcast

- **Private** channel: the claiming script becomes the only writer. `claim()` from any other script returns `false` — that means the channel is busy.
- **Public** channel: several scripts can write — each writer calls `claim(ch, ISC.CH_TYPE_PUBLIC)` on the same channel. Each message still goes to one reader.
- **Broadcast** channel: one writer, any number of subscribed readers — see [Broadcast Channels](#broadcast-channels).
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

### ISC.send(channel:int, value:int\|real\|string\|bytes) -> bool\|int

Send a message to a channel claimed by this script. Never blocks. Raises an error if the channel is not claimed, or is claimed by another script (private).

| Parameter | Type | Description |
|-----------|------|-------------|
| `channel` | int | Channel id, 0–100 (101–255 are reserved for the system) |
| `value` | any | Message: `int`, `real`, `string` or `bytes` (string / bytes max 64 KB) |

**Returns:** `bool` — `true` if the message was queued, `false` if the channel is full (8 pending messages) or out of memory. On a **broadcast** channel: `int` — the number of subscribers the message was delivered to (`0` = nobody is subscribed, or every subscriber queue is full).

```berry
import ISC

ISC.send(1, 42)              # int
ISC.send(1, 21.5)            # real
ISC.send(1, "hello there")   # string
ISC.send(1, bytes("A1B2C3"))  # bytes - binary-safe, arrives as bytes()
```

### ISC.receive(channel:int, timeout_ms:int=0) -> int\|real\|string\|bytes

Receive the oldest message from a channel (FIFO order). Blocks the calling script until a message arrives or the timeout expires.

| Parameter | Type | Description |
|-----------|------|-------------|
| `channel` | int | Channel id, 0–100 (101–255 are reserved for the system) |
| `timeout_ms` | int | (optional) How long to wait, milliseconds. `0` (default) — return immediately; `ISC.TIMEOUT_FOREVER` (`-1`) — wait forever |

**Returns:** the received `int`, `real`, `string` or `bytes` (the same type that was sent), or `nil` if no message arrived within the timeout

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

On a broadcast channel `clear()` drops only the calling subscriber's own pending copies.

### ISC.subscribe(channel:int) -> bool

Subscribe to a broadcast channel. From now on every message sent to the channel is copied into this script's own queue (up to 8 pending messages); read them with `receive()` as usual. Subscribing is allowed before the writer claims the channel — the start order of the scripts does not matter.

| Parameter | Type | Description |
|-----------|------|-------------|
| `channel` | int | Channel id, 0–100 |

**Returns:** `bool` — `true` if subscribed (repeating the call is a no-op); `false` if the channel is a private/public channel, or the subscription limit (32 across all scripts) is reached

```berry
import ISC
ISC.subscribe(5)
var msg = ISC.receive(5, 1000)   # this script's own copy
```

### ISC.unsubscribe(channel:int) -> bool

Stop receiving a broadcast channel. Messages still pending for this script are dropped. Called automatically for every subscription when the script stops.

| Parameter | Type | Description |
|-----------|------|-------------|
| `channel` | int | Channel id, 0–100 |

**Returns:** `bool` — `false` if the calling script was not subscribed

```berry
import ISC
ISC.unsubscribe(5)
```

## Broadcast Channels

A regular channel is a single queue: with several readers every message goes to whoever receives it first. A **broadcast** channel delivers every message to **every** subscribed script:

- the writer claims the channel with `ISC.claim(ch, ISC.CH_TYPE_BROADCAST)` — like private, only one script may write;
- each reader calls `ISC.subscribe(ch)` once and then uses `receive()` / `available()` / `clear()` as usual — they work on the reader's own copy of the stream;
- `send()` returns the number of subscribers the message reached;
- a slow subscriber only loses its own messages: when its queue (8 messages) is full, the new message is dropped for that subscriber, the others still get it;
- messages are not stored for scripts that subscribe later — a new subscriber sees only messages sent after `subscribe()`;
- string and bytes messages are stored once in PSRAM and shared by all subscribers, so broadcasting a long payload to many scripts does not multiply memory use.

```berry
# Publisher script — the only writer
import ISC
import TIMER
import WEATHER

ISC.claim(5, ISC.CH_TYPE_BROADCAST)

TIMER.setInterval(def ()
    var n = ISC.send(5, WEATHER.get()["temp"])
    if n == 0
        # nobody listens at the moment
    end
end, 60000)
```

```berry
# Any number of subscriber scripts, each gets every value
import ISC
import SLZB

ISC.subscribe(5)

while true
    var temp = ISC.receive(5, ISC.TIMEOUT_FOREVER)
    SLZB.log("temperature: " .. str(temp))
end
```

## Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `ISC.TIMEOUT_FOREVER` | -1 | Pass as `timeout_ms` to `receive()` to wait forever |
| `ISC.MAX_CHANNEL` | 100 | Highest channel id available to scripts |
| `ISC.CH_TYPE_PRIVATE` | 1 | Channel with a single writer |
| `ISC.CH_TYPE_PUBLIC` | 2 | Shared channel — several scripts may claim and write; each message goes to one reader |
| `ISC.CH_TYPE_BROADCAST` | 3 | Broadcast channel — a single writer, every subscribed script gets each message |

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
- Broadcast: `receive()` on a broadcast channel without `subscribe()` raises an error; subscriptions (up to 32 in total) are removed automatically when the script stops. A channel that has subscribers accepts only a `CH_TYPE_BROADCAST` claim, and subscribing to a private/public channel returns `false`
- Broadcast: when the writer stops, the subscriptions stay — a restarted writer claims the channel again and the subscribers keep receiving
- Firmware features use broadcast on reserved system channels too — e.g. incoming SMS of the 4G/LTE add-on are broadcast to every script that calls `LTE.smsReceive()`
