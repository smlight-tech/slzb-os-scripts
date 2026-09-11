# UI Module

Talk to the user through the coordinator's web interface — show modal messages from a script and get notified when the user has seen and closed them.

Under the hood the module uses reserved ISC system channels: the payload travels to the browser as SSE event, the page shows the modal and posts acknowledgements back to the firmware.

## Setup

No configuration needed, but the web UI must be **claimed** first — every other call raises an error until `UI.claim()` succeeds:

```berry
import UI

if UI.claim()
    UI.showMessage("Hello", "Script attached to the web UI")
end
```

The web page of the coordinator must be open in a browser — use `UI.available()` to check before sending.

## API Reference

| Function | Description |
|----------|-------------|
| `UI.claim() -> bool` | Take exclusive ownership of the web UI — required before any other UI call. |
| `UI.release() -> bool` | Release this script's claim on the web UI. |
| `UI.available() -> bool` | Ask the page whether a message can be shown right now. |
| `UI.showMessage(title:string, body:string, buttons:list?) -> int` | Show a modal message in the web UI, optionally with custom buttons. |
| `UI.showPrompt(title:string, body:string, placeholder:string?) -> int` | Show a modal dialog with a text input. |
| `UI.receive(timeout_ms:int=0) -> string` | Next raw acknowledgement payload from the web page. |

### UI.claim() -> bool

Take exclusive ownership of the web UI for this script: both reserved channels are claimed (private) in the ISC claim table. **Required** — `message()`, `available()` and `receive()` raise an error until the calling script owns the web UI.

**Returns:** `bool` — `false` if another script already owns the web UI

The claim is released by `UI.release()` or automatically when the script stops. When a script stops, its open dialog is closed automatically and its undelivered dialogs are dropped.

```berry
import UI

if !UI.claim()
    # another script owns the web UI
    return
end
```

### UI.release() -> bool

Manually release this script's claim on the web UI.

**Returns:** `bool` — `false` if the calling script was not the owner

### UI.available() -> bool

Ask the web page whether a message can be shown right now. Sends `{"action":"status"}` to the page and waits up to ~1.5 s for the reply `{"action":"status","status":"free"|"busy"}` — the page answers `"busy"` while a previous script message is still on screen (system modals do not matter — script messages have their own window).

**Returns:** `bool` — `true` only when the page answered `"free"`; `false` when the page is closed, did not answer in time, or the previous script message is not closed yet. Raises an error if the web UI is not claimed by this script.

> `available()` blocks the calling script while waiting for the page. Do not call it from `TIMER` or event callbacks — they run in the same task that serves web requests, so the page's reply cannot arrive until the callback finishes and the call always times out. Use it from the main script flow.

```berry
import UI

UI.claim()
if UI.available()
    UI.showMessage("Hello", "The coordinator has something to say")
end
```

### UI.showMessage(title:string, body:string, buttons:list?) -> int

Show a message in the script modal window (rendered under the system modals). By default the footer has a single **Ok** button; pass `buttons` to replace it with your own set.

| Parameter | Type | Description |
|-----------|------|-------------|
| `title` | string | Modal title |
| `body` | string | Message text (newlines are rendered as line breaks) |
| `buttons` | list | (optional) Footer button labels, e.g. `["Yes", "No"]` (strings, max 4). Clicking a button closes the dialog and reports its label |

**Returns:** `int` — `1` if the message was queued for the browser, `0` if the page is closed or the queue is full. Raises an error if the web UI is not claimed by this script.

The page answers through the return channel (read with `UI.receive()`):

| Payload | Meaning |
|---------|---------|
| `{"action":"message","status":"shown"}` | The modal is displayed |
| `{"action":"message","status":"button","value":"<label>"}` | A custom button was clicked — `value` holds its label |
| `{"action":"message","status":"closed"}` | The dialog was closed (always follows, also after a button click) |
| `{"action":"message","status":"busy"}` | The previous script message is still on screen — the message was not shown |

```berry
import UI

UI.claim()
UI.showMessage("Water leak!", "Sensor in the bathroom reported a leak")
```

### Ask the user a question with custom buttons

```berry
import UI
import json
import SLZB

UI.claim()

if UI.showMessage("Confirm", "Restart the Zigbee network now?", ["Restart", "Later"]) == 1
    var ack = UI.receive(60000)
    while ack != nil
        var data = json.load(ack)
        if data["status"] == "button"
            SLZB.log("user picked: " .. data["value"])
            break
        elif data["status"] == "closed"
            SLZB.log("dialog dismissed")
            break
        end
        ack = UI.receive(60000)
    end
end
```

### UI.showPrompt(title:string, body:string, placeholder:string?) -> int

Show a modal dialog with a text input field and an **Ok** button.

| Parameter | Type | Description |
|-----------|------|-------------|
| `title` | string | Dialog title |
| `body` | string | Text shown above the input field |
| `placeholder` | string | (optional) Placeholder text inside the input |

**Returns:** `int` — `1` if the dialog was queued for the browser, `0` if the page is closed or the queue is full. Raises an error if the web UI is not claimed by this script.

After the user presses **Ok**, the entered text arrives on the return channel (read with `UI.receive()`):

| Payload | Meaning |
|---------|---------|
| `{"action":"prompt","status":"shown"}` | The dialog is displayed |
| `{"action":"prompt","status":"ok","value":"<text>"}` | The user pressed **Ok** — `value` holds the entered text |
| `{"action":"prompt","status":"closed"}` | The dialog was dismissed without pressing **Ok** |
| `{"action":"prompt","status":"busy"}` | Another script dialog was already open — not shown |

```berry
import UI
import json
import SLZB

UI.claim()

if UI.showPrompt("Device name", "Enter a name for the new device:", "e.g. Kitchen sensor") == 1
    var ack = UI.receive(60000)
    while ack != nil
        var data = json.load(ack)
        if data["status"] == "ok"
            SLZB.log("user entered: " .. data["value"])
            break
        elif data["status"] == "closed"
            SLZB.log("user cancelled")
            break
        end
        ack = UI.receive(60000)
    end
end
```

### UI.receive(timeout_ms:int=0) -> string

Read the next acknowledgement payload sent by the web page.

| Parameter | Type | Description |
|-----------|------|-------------|
| `timeout_ms` | int | (optional) How long to wait, milliseconds. `0` (default) — return immediately; negative — wait forever |

**Returns:** `string` — raw JSON payload (parse with `json.load()`), or `nil` if nothing arrived within the timeout

```berry
import UI
import json

UI.claim()

if UI.showMessage("Attention", "Please confirm you saw this") == 1
    var ack = UI.receive(60000)   # wait up to a minute
    while ack != nil
        var data = json.load(ack)
        if data["status"] == "closed"
            break
        end
        ack = UI.receive(60000)
    end
end
```

## Examples

### Notify the user when a device goes offline

```berry
import UI
import ZHB
import TIMER

UI.claim()
ZHB.waitForStart(0xff)

TIMER.setInterval(def()
    # message() is non-blocking and safe in callbacks; if another modal is open
    # the page just answers "busy". Do NOT call UI.available() here (see above).
    var devices = ZHB.getDevices()
    for dev : devices
        if !dev.isOnline()
            UI.showMessage("Device offline", dev.getName() .. " stopped responding")
        end
    end
end, 600000)
```

### Wait until the user confirms

```berry
import UI
import json
import SLZB

UI.claim()

while !UI.available()
    SLZB.delay(1000)   # wait for the user to open the web page
end

UI.showMessage("Maintenance", "Zigbee network will restart in 1 minute")

var ack = UI.receive(120000)
while ack != nil
    if json.load(ack)["status"] == "closed"
        SLZB.log("user confirmed")
        break
    end
    ack = UI.receive(120000)
end
```

## Notes

- Available only on U series, MRU series and Ultima
- Requires the coordinator web page to be open in a browser — messages are delivered over SSE (`/events`)
- `UI.claim()` is mandatory: every other call raises an error until the script owns the web UI; the claim is dropped automatically when the script stops
- Stopping the owner script closes its dialog on the page automatically and drops its queued, not-yet-shown dialogs
- The modal state lives on the page: `available()` asks the page every time, the firmware keeps no state
- Acknowledgements are best effort: the module works fine if the script never calls `UI.receive()`; when the return queue is full, new acks are dropped
- Uses reserved ISC channels — scripts cannot access them directly through the ISC module
