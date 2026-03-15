# TIMER — Repeating & One-Shot Timers

> `import TIMER`

Create repeating and one-shot timers for periodic tasks, scheduled checks, and delayed actions.

## Quick Example

```berry
import TIMER

TIMER.setInterval(def()
  SLZB.log("tick every 5 seconds")
end, 5000)
```

## Functions

### TIMER.setInterval(callback, ms) → int

Create a repeating timer. Returns a timer ID for later cancellation.

| Parameter | Type | Description |
|-----------|------|-------------|
| `callback` | function | Function to call on each tick |
| `ms` | int | Interval in milliseconds |

**Returns:** `int` — timer ID

```berry
import TIMER

# Check something every minute
var id = TIMER.setInterval(def()
  SLZB.log("one minute passed")
end, 60000)
```

### TIMER.setTimeout(callback, ms) → int

Create a one-shot timer that fires the callback once after `ms` milliseconds.

| Parameter | Type | Description |
|-----------|------|-------------|
| `callback` | function | Function to call once after delay |
| `ms` | int | Delay in milliseconds |

**Returns:** `int` — timer ID

```berry
import TIMER

TIMER.setTimeout(def()
  SLZB.log("fired once after 10 seconds")
end, 10000)
```

### TIMER.clear(timerId)

Cancel a previously created timer (repeating or one-shot).

| Parameter | Type | Description |
|-----------|------|-------------|
| `timerId` | int | Timer ID returned by setInterval or setTimeout |

```berry
import TIMER

var id = TIMER.setInterval(def()
  SLZB.log("tick")
end, 1000)

# Stop it after 10 seconds
TIMER.setTimeout(def()
  TIMER.clear(id)
  SLZB.log("timer stopped")
end, 10000)
```

## Common Patterns

### Daily alarm at specific time

```berry
import TIMER, TIME, BUZZER

TIME.waitSync(0xff)
TIMER.setInterval(def()
  var t = TIME.getAll()
  if t["hour"] == 8 && t["min"] == 0
    BUZZER.play("alarm:d=4,o=5,b=160:a,p,a,p,a")
  end
end, 60000)
```

### Periodic sensor check with alert

```berry
import TIMER, ZHB, TELEGRAM

ZHB.waitForStart(0xff)
var sensor = ZHB.getDevice("Temp Sensor")

TIMER.setInterval(def()
  var temp = sensor.getVal(1, 0x0402, 0)
  if temp != nil && temp > 3000
    TELEGRAM.send("High temperature: " .. str(temp / 100.0) .. "°C")
  end
end, 300000)
```

## Notes

- Callbacks must return fast — no `SLZB.delay()`, no infinite loops, no blocking operations
- Timer callbacks run in the script's execution context
- Maximum practical interval: ~49 days (2³² ms)
- Minimum practical interval: ~10 ms (lower values may be unreliable)
- Multiple timers can run concurrently within the same script

## See Also

- [TIME — Clock/NTP](time.md) — Get current date/time for scheduled actions
- [SLZB — Core](slzb.md) — `SLZB.delay()` for simple blocking delays (not for use in callbacks)
