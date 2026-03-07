# TIME — Date and Time

> Available since: v3.0.6

Get accurate date and time from the internal clock with NTP synchronization, respecting your configured time zone and daylight saving time.

## Quick Example

```berry
import TIME

TIME.waitSync(0xff)  # wait for NTP sync

var t = TIME.getAll()
SLZB.log("Time: " .. t["hour"] .. ":" .. t["min"] .. ":" .. t["sec"])
SLZB.log("Date: " .. t["year"] .. "-" .. t["month"] .. "-" .. t["day"])
```

## API Reference

| Function | Description | Returns |
|----------|-------------|---------|
| `TIME.waitSync(timeout)` | Wait for NTP time synchronization. Max 254 seconds. Use `255` to wait forever. Returns instantly if already synced. | `bool` (`false` if timed out) |
| `TIME.getAll()` | Get full date and time. Returns `nil` if time is not yet synced. | `map` |
| `TIME.getTime()` | Get time only. | `map` |

### Return value structure

`TIME.getAll()` returns:
```
{year, month, day, hour, min, sec, weekday}
```

`TIME.getTime()` returns:
```
{hour, min, sec}
```

**Note:** `weekday` counts from Sunday (Sunday = 0).

## See Also

- [SLZB — Core Functions](slzb.md) — `SLZB.millis()` for relative timing (uptime)
- [Example: Reboot at 3 AM](../../examples/time/reboot_at_3am.be)
- [Example: Log date and time](../../examples/time/log_datetime.be)
- [Example: Wake-up alarm](../../examples/time/alarm.be) — gradual LED brightness + buzzer on a schedule
