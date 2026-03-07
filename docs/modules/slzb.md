# SLZB — Core Functions

> Available since: v2.8.0

General-purpose functions for delays, logging, device info, and system control. This module is **loaded automatically** — no `import` needed.

## Quick Example

```berry
SLZB.log("Device: " .. SLZB.deviceModel())
SLZB.log("Free RAM: " .. SLZB.freeHeap() .. " bytes")
SLZB.log("Uptime: " .. SLZB.millis() / 1000 .. " seconds")
```

## API Reference

| Function | Description | Returns |
|----------|-------------|---------|
| `SLZB.delay(ms:int)` | Pause script execution for `ms` milliseconds. Max: 4,294,967,295 ms (~1193 hours). | — |
| `SLZB.millis()` | Milliseconds since device started. | `int` |
| `SLZB.reboot()` | Reboot the device immediately. | — |
| `SLZB.log(text:string)` | Send text to the debug console. | — |
| `SLZB.freeHeap()` | Total free RAM in the system (bytes). | `int` |
| `SLZB.deviceModel()` | Device model name (e.g. `"SLZB-06P7"`). *(since v2.8.2.dev1)* | `string` |

## See Also

- [Getting Started](../getting-started.md) — Metadata and event system basics
- [ZB — Zigbee Chip Access](zb.md) — Low-level Zigbee control
- [TIME — Date and Time](time.md) — `TIME.getAll()` for accurate clock, vs `SLZB.millis()` for relative timing
- [Example: Reboot every day](../../examples/basic/reboot_every_day.be)
