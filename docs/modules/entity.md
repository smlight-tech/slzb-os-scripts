# ENTITY Module

> Available since: v3.4.5.dev3 · U series and Ultima

The states of the device and of its Zigbee devices as **entities**: named values such as the chip temperature, a button press or a Zigbee sensor, read by id, followed as they change and - for what a device can be told - set. The automations of the web interface are built on this module; your own scripts can use it too.

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

### Your own entities

The **Entities** page of the web interface lets you make entities of your own: `user.<id>`, an on / off (bool), a
number or a text. They are for values that automations and scripts share and that must survive a restart - a mode, a
counter, a target temperature.

| Id | State | Description |
|----|-------|-------------|
| `user.<id>` | bool, int / real or string, as the entity was made | Read with `ENTITY.get`, followed with `ENTITY.subscribe`, written with `ENTITY.set` |

`ENTITY.set` must bring a value of the entity's type: a text written to a number comes back as the result `"failed"`
with the reason `"not a number"` (`"not on / off"`, `"not a text"`), and the entity keeps its value. A value a script
writes is stored on the device within 30 seconds (and before a planned restart); one written right before a power cut
is lost.

### Zigbee Hub entities

While a radio runs the Zigbee Hub, every entity its dashboard shows is an entity here too:

| Id | State | Description |
|----|-------|-------------|
| `zhb.<ieee>.<ep>_<cluster>_<attr>` | as reported | An attribute of a device, e.g. `zhb.a4c138cf833c687a.1_0402_0000` (temperature of endpoint 1). The same numbers as in the hub's MQTT topics `<base>/data/<ieee>/<ep>/<cluster>/<attr>` (cluster and attribute 4 hex digits); a field of an attribute ends in `_<n>` |
| `zhb.<ieee>.action` | string | An *event* at every action of the device (remote buttons: `"single"`, `"on_1"`, ...) |

The state is the value the hub publishes (`data.val` of its MQTT message); a measurement the hub publishes as a text of a fixed precision (`"227.00"`: power, voltage, energy, ...) is the number. Entities of a device that went offline (hub setting *device availability*) are unavailable until it is back; a removed device's entities are gone.

`ENTITY.list()` shows what your device has; `ENTITY.list("zhb.")` the Zigbee ones.

### Aliases

An id such as `zhb.70b3d52b600a4e57.1_0006_0000` stays the same when a device is renamed, but it is no name for people. An entity can get an **alias** (in this version through the device API: `PATCH /api/v3/entities {"aliases": {"hall_light": "<id>"}}`) - 1 to 32 characters of `a-z`, `0-9` and `_`, e.g. `hall_light`. Every function takes it instead of the id:

```berry
ENTITY.set("hall_light", true)
```

Each entity has at most one alias. An alias is looked up when the function runs: `subscribe()` follows the entity the alias names at that moment.

## API Reference

| Function | Description |
|----------|-------------|
| `ENTITY.get(id:string) -> map` | The current state of an entity, `nil` if there is no such entity. |
| `ENTITY.list(prefix:string="") -> list` | Every entity whose id starts with `prefix`, as state maps. |
| `ENTITY.subscribe(ids:list) -> bool` | Follow the changes of these entities (a list of ids, or one id as a string). |
| `ENTITY.unsubscribe() -> bool` | Stop following; pending changes are dropped. |
| `ENTITY.receive(timeout_ms:int=0) -> map` | The next event: a change of a followed entity or the outcome of a `set()`, `nil` if none came within the timeout. |
| `ENTITY.set(id:string, value:any) -> int` | Tell a device to change an entity; never waits: returns a request number, the outcome comes with `receive()`. |

### State map

`get()`, `list()` and `receive()` return maps with these keys:

| Key | Type | Description |
|-----|------|-------------|
| `id` | string | Entity id |
| `state` | bool / int / real / string / nil | Current value, `nil` while none was reported |
| `available` | bool | `true` once a value was reported |
| `writable` | bool | `set()` can change it |
| `alias` | string | (optional) The entity's alias |
| `changed` | int / nil | Time of the last change, epoch seconds (`nil` while the clock is not set) |
| `changedMs` | int / nil | `SLZB.millis()` of the last change |
| `t` | string | `receive()` only: `"state"` |
| `cause` | string | `receive()` only: `"value"` - the entity reported a value; `"availability"` - only `available` changed (a device went offline or is back) and `state` is the value it had |
| `dropped` | int | `receive()` only, when events were lost: how many (see [Notes](#notes)) |

### Result map

The outcome of a `set()` arrives through `receive()`:

| Key | Type | Description |
|-----|------|-------------|
| `t` | string | `"result"` |
| `id` | string | Entity id |
| `req` | int | The number `set()` returned |
| `status` | string | `"ok"` — the device took it; `"failed"` — refused (see `code` / `reason`); `"timeout"` — the device did not answer; `"offline"` — not sent, the device is offline; `"superseded"` — a newer `set()` of the same entity by this script replaced it |
| `code` | int | (optional) The device's status (ZCL) |
| `reason` | string | (optional) Why it failed |

### ENTITY.get(id:string) -> map

| Parameter | Type | Description |
|-----------|------|-------------|
| `id` | string | Entity id or alias |

**Returns:** `map` — the state map, or `nil` if there is no such entity (or alias)

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
| `ids` | list | Entity ids or aliases (strings), or a single one as a string; at most 32 per script |

**Returns:** `bool` — `true`. Raises `entity_error` for an invalid id, an unknown alias, more than 32 ids, or when every subscription is taken (one per script, 10 in all).

```berry
import ENTITY
ENTITY.subscribe(["network.internet", "button.btn1"])
```

### ENTITY.unsubscribe() -> bool

**Returns:** `bool` — `false` if this script had no subscription. Called automatically when the script stops.

### ENTITY.receive(timeout_ms:int=0) -> map

Waits for the next event: a change of a subscribed entity (`"t": "state"`) or the outcome of a `set()` of this script (`"t": "result"`). Only the script itself waits: its timers and other callbacks keep running meanwhile.

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

### ENTITY.set(id:string, value:any) -> int

Asks a device to change an entity: a switch or light `true` / `false`, a number, an option of a select, a text. Never waits for the device - a device that is asleep or out of range does not stop the script; the outcome comes later through `receive()` as a [result map](#result-map) with the same `req`. A button entity is pressed whatever the value.

| Parameter | Type | Description |
|-----------|------|-------------|
| `id` | string | Entity id or alias |
| `value` | any | `bool`, `int`, `real` or `string` (at most 64 bytes) |

**Returns:** `int` — the request number. Raises `entity_error` for an unknown entity or alias, one that cannot be set (`read only`, `writable` false), or when 16 writes of this script are still waiting for their outcome. `set()` also makes the script's subscription when it has none (the outcome needs it), so call it in the main script code that reads `receive()`.

```berry
import ENTITY
var light = "zhb.70b3d52b600a4e57.1_0006_0000"
var req = ENTITY.set(light, true)
while true
    var ev = ENTITY.receive(10000)
    if ev != nil && ev["t"] == "result" && ev["req"] == req
        SLZB.log("light: " .. ev["status"])
        break
    end
end
```

## Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `ENTITY.TIMEOUT_FOREVER` | `-1` | `receive()` waits until a change comes |

## Examples

### Light on while a sensor sees motion

```berry
import ENTITY
var motion = "zhb.a4c138cf833c687a.1_0500_0002_1"
var light = "zhb.70b3d52b600a4e57.1_0006_0000"
ENTITY.subscribe(motion)
while true
    var ev = ENTITY.receive(ENTITY.TIMEOUT_FOREVER)
    if ev["t"] == "state" && ev["id"] == motion
        ENTITY.set(light, ev["state"] == true)
    elif ev["t"] == "result" && ev["status"] != "ok"
        SLZB.log("light not switched: " .. ev["status"])
    end
end
```

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

- An event (a change or a result) is kept for the script until `receive()` takes it, up to 16. When more come meanwhile, the oldest are dropped and the next event reports how many in `dropped`.
- A `set()` without an outcome from the device within 15 seconds comes back as `"timeout"`.
- A state entity reports a change only when its value or availability changes; an event entity (a button) reports every press.
- A device that is back online brings the value it had before: act on `ev["cause"] == "value"` when only a value the device really reported should count (a button press, a measurement).
- Waiting in `receive()` costs no CPU. Prefer one `while true` loop with `receive(ENTITY.TIMEOUT_FOREVER)` over polling with timers.
- Entities of the device itself (temperature, network, buttons) are read only; Zigbee entities can be set when the hub's dashboard can set them.

## See Also

- [ISC — Inter-script communication](isc.md)
- [BUTTON — Physical Button Override](button.md)
- [NETWORK — Network state](network.md)
