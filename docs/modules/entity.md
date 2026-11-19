# ENTITY Module

> Available since: v3.4.5.dev3 · U series and Ultima

The states of the device as **entities**: named values such as the chip temperature, the network links or a button press, read by id and followed as they change. The automations of the web interface are built on this module; your own scripts can use it too.

An entity id is `<domain>.<object>[.<key>]`, for example `network.internet` or `button.btn1`. Each entity has a **state** (`bool`, `int`, `real` or `string`), knows whether it is **available** (a value was reported) and when it last **changed**.

## Setup

No configuration needed:

```berry
import ENTITY
```

## Entities

| Id | State | Description |
|----|-------|-------------|
| `device.temperature` | real | Chip temperature in °C (with the temperature calibration), reported when it changes by 0.5 °C |
| `network.connected` | bool | The device has a network (Ethernet, Wi-Fi or 4G/LTE) |
| `network.ethernet` | bool | Ethernet has an IP address |
| `network.wifi` | bool | Wi-Fi (station) has an IP address |
| `network.internet` | bool | Result of the last internet check (at the start, and whenever the web interface checks) |
| `button.btn1` | string | `"short"` / `"long"` at every press of the device button — an *event*: pressing twice gives two changes |
| `button.btn2` | string | The second button (SLZB-Ultima, SLZB-U2L) |

`ENTITY.list()` shows what your device has. More entities (Zigbee Hub devices) follow in later versions.

## API Reference

| Function | Description |
|----------|-------------|
| `ENTITY.get(id:string) -> map` | The current state of an entity, `nil` if there is no such entity. |
| `ENTITY.list(prefix:string="") -> list` | Every entity whose id starts with `prefix`, as state maps. |
| `ENTITY.subscribe(ids:list) -> bool` | Follow the changes of these entities (a list of ids, or one id as a string). |
| `ENTITY.unsubscribe() -> bool` | Stop following; pending changes are dropped. |
| `ENTITY.receive(timeout_ms:int=0) -> map` | The next change of a followed entity, `nil` if none came within the timeout. |

### State map

`get()`, `list()` and `receive()` return maps with these keys:

| Key | Type | Description |
|-----|------|-------------|
| `id` | string | Entity id |
| `state` | bool / int / real / string / nil | Current value, `nil` while none was reported |
| `available` | bool | `true` once a value was reported |
| `changed` | int / nil | Time of the last change, epoch seconds (`nil` while the clock is not set) |
| `changedMs` | int / nil | `SLZB.millis()` of the last change |
| `dropped` | int | `receive()` only, when changes were lost: how many (see [Notes](#notes)) |

### ENTITY.get(id:string) -> map

| Parameter | Type | Description |
|-----------|------|-------------|
| `id` | string | Entity id |

**Returns:** `map` — the state map, or `nil` if there is no such entity

```berry
import ENTITY
var t = ENTITY.get("device.temperature")
if t != nil && t["available"]
    SLZB.log("chip: " .. str(t["state"]) .. " °C")
end
```

### ENTITY.list(prefix:string="") -> list

| Parameter | Type | Description |
|-----------|------|-------------|
| `prefix` | string | (optional) Only ids starting with it, e.g. `"network."` |

**Returns:** `list` — state maps

```berry
import ENTITY
for e: ENTITY.list("network.")
    SLZB.log(e["id"] .. " = " .. str(e["state"]))
end
```

### ENTITY.subscribe(ids:list) -> bool

Adds entities to this script's subscription. An id that does not exist yet is accepted (entities of devices that appear later). Calling it again adds more ids.

| Parameter | Type | Description |
|-----------|------|-------------|
| `ids` | list | Entity ids (strings), or a single id as a string; at most 32 per script |

**Returns:** `bool` — `true`. Raises `entity_error` for an invalid id, more than 32 ids, or when every subscription is taken (one per script, 10 in all).

```berry
import ENTITY
ENTITY.subscribe(["network.internet", "button.btn1"])
```

### ENTITY.unsubscribe() -> bool

**Returns:** `bool` — `false` if this script had no subscription. Called automatically when the script stops.

### ENTITY.receive(timeout_ms:int=0) -> map

Waits for the next change of a subscribed entity. Only the script itself waits: its timers and other callbacks keep running meanwhile.

| Parameter | Type | Description |
|-----------|------|-------------|
| `timeout_ms` | int | (optional) How long to wait, milliseconds. `0` (default) — return immediately; `ENTITY.TIMEOUT_FOREVER` (`-1`) — wait until a change comes |

**Returns:** `map` — the state map of the changed entity, `nil` on timeout

A timeout other than `0` is allowed in the main script code only; in a callback (`TIMER`, `MQTT`, ...) use `receive(0)`.

```berry
import ENTITY
ENTITY.subscribe("button.btn1")
while true
    var ev = ENTITY.receive(ENTITY.TIMEOUT_FOREVER)
    SLZB.log("button: " .. ev["state"])
end
```

## Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `ENTITY.TIMEOUT_FOREVER` | `-1` | `receive()` waits until a change comes |

## Examples

### Notify when the internet goes away

```berry
import ENTITY
import TELEGRAM

ENTITY.subscribe("network.internet")
while true
    var ev = ENTITY.receive(ENTITY.TIMEOUT_FOREVER)
    if ev["state"] == true
        TELEGRAM.send("Internet is back")
    end
end
```

## Notes

- A change is kept for the script until `receive()` takes it, up to 16 changes. When more come meanwhile, the oldest are dropped and the next change reports how many in `dropped`.
- A state entity reports a change only when its value or availability changes; an event entity (a button) reports every press.
- Waiting in `receive()` costs no CPU. Prefer one `while true` loop with `receive(ENTITY.TIMEOUT_FOREVER)` over polling with timers.
- Entities are read only in this version.

## See Also

- [ISC — Inter-script communication](isc.md)
- [BUTTON — Physical Button Override](button.md)
- [NETWORK — Network state](network.md)
