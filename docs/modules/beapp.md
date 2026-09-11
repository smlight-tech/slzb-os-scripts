# BEAPP Module

Advanced module for installed SLZB-OS apps (basic message dialogs for regular scripts live in the [UI](ui.md) module): the app's Berry backend learns when the user opens or closes the app's web page, exchanges messages with that page and keeps a private ring log.

Channels are dynamic: `BEAPP.claim()` allocates a free pair of adjacent reserved ISC channels (the fixed system channels are skipped) and returns the base channel number; every `send()`/`receive()` takes that number — TX (firmware → web) = `ch`, RX (web → firmware) = `ch + 1`. Several apps can run their backends at the same time. On the page side the counterpart is the BeApp SDK (`BeApp.onMessage` / `BeApp.sendMessage`).

## Setup

An app's main script is always `/beapps/<app_folder>/app.be`. The script must claim its app before messaging calls (`send`/`receive`) — `claim()` derives the folder from the script's own path and returns the allocated channel number. `log()`/`setLogSize()` work without a claim:

```berry
import BEAPP

var ch = BEAPP.claim()
if ch == 0
    # no free app channel
    return
end
```

## API Reference

| Function | Description |
|----------|-------------|
| `BEAPP.claim(folder:string?) -> int` | Allocate a channel pair for this app backend — required for `send`/`receive`. |
| `BEAPP.release() -> bool` | Release the app claim manually. |
| `BEAPP.send(ch:int, data:string) -> int` | Send a message to the app's open web page. |
| `BEAPP.receive(ch:int, timeout_ms:int=0) -> string` | Next event addressed to this app (lifecycle or page message). |
| `BEAPP.log(msg:string) -> nil` | Append a line to the app's own ring log. |
| `BEAPP.setLogSize(bytes:int) -> bool` | Set the size of the app's ring log buffer. |

### BEAPP.claim(folder:string?) -> int

Register this script as an app backend: finds a free pair of adjacent reserved ISC channels (the fixed system channels are skipped), claims them privately and returns the base channel number for `send()`/`receive()`. Without arguments the app folder is derived from the script's own path (`/beapps/<app_folder>/app.be`); pass `folder` explicitly only when developing the backend as a regular script in `/be/`. Repeated `claim()` from the same script returns the already-allocated channel.

**Returns:** `int` — the allocated channel number, or `0` when no free channel pair or app slot is left (or the app is already claimed by another script). Raises an error when called without arguments from a script that does not run from `/beapps/`.

The claim is released by `BEAPP.release()` or automatically when the script stops.

### BEAPP.release() -> bool

Manually release this script's app channels and slot.

**Returns:** `bool` — `false` if the calling script has no claimed app channels

### BEAPP.send(ch:int, data:string) -> int

Send a message to the app's web page. Delivered as SSE to the open page and dispatched to `BeApp.onMessage(cb)` callbacks; pass a JSON string (`json.dump(...)`) for structured payloads.

| Parameter | Type | Description |
|-----------|------|-------------|
| `ch` | int | Channel number returned by `claim()` |
| `data` | string | Message content, delivered to the page as-is |

**Returns:** `int` — `1` if queued, `0` if the queue is full. Raises an error before `claim()`.

If the app page is not open, the message waits in the queue and is delivered when the page connects (stale messages are dropped when a backend claims the app anew).

### BEAPP.receive(ch:int, timeout_ms:int=0) -> string

Receive the next event addressed to the claimed app. Events of other apps are dropped automatically.

| Parameter | Type | Description |
|-----------|------|-------------|
| `ch` | int | Channel number returned by `claim()` |
| `timeout_ms` | int | (optional) How long to wait, milliseconds. `0` (default) — return immediately; negative — wait forever |

**Returns:** `string` — raw JSON payload (parse with `json.load()`), or `nil` on timeout

| Payload | Meaning |
|---------|---------|
| `{"app":"<folder>","event":"open"}` | The user opened the app page |
| `{"app":"<folder>","event":"close"}` | The app page was closed |
| `{"app":"<folder>","event":"msg","data":"..."}` | Message from the page (`BeApp.sendMessage`) |

### BEAPP.log(msg:string) -> nil

Append a line to the app's private ring log — viewable in the coordinator UI via the **Log** button on the app card. **No `claim()` needed** — a background app script can log at any time; the app is identified by the script's own path (`/beapps/<folder>/app.be`). The buffer lives in PSRAM, is created on first use (4096 bytes by default) and silently drops the oldest lines when full; it survives script restarts, so the log stays readable while the app is stopped. Lines are prefixed with the current time.

| Parameter | Type | Description |
|-----------|------|-------------|
| `msg` | string | Log line |

```berry
import BEAPP
BEAPP.log("backend started")   # works without claim()
```

### BEAPP.setLogSize(bytes:int) -> bool

Set the size of this app's ring log buffer (clamped to 256..32768 bytes). No `claim()` needed (same rules as `log()`). Reallocates the buffer — existing content is lost, so call it once at script start.

| Parameter | Type | Description |
|-----------|------|-------------|
| `bytes` | int | Buffer size in bytes |

**Returns:** `bool` — `false` when no log slot is available

## Examples

### Minimal app backend

```berry
import BEAPP
import SLZB
import json

if !BEAPP.claim()   # folder derived from /beapps/<app_folder>/app.be
    return
end

while true
    var payload = BEAPP.receive(-1)
    if payload == nil continue end

    var m = json.load(payload)

    if m["event"] == "open"
        SLZB.log("app UI opened")
        BEAPP.send(ch, json.dump({"text": "hello!"}))
    elif m["event"] == "close"
        SLZB.log("app UI closed")
    elif m["event"] == "msg"
        BEAPP.send(ch, "echo: " .. str(m["data"]))
    end
end
```

### Page side (ui.html, BeApp SDK)

```html
<script src="/js/beAppSdk.js"></script>
<script>
    BeApp.onMessage((data) => {
        document.getElementById("status").textContent = JSON.parse(data).text;
    });

    document.getElementById("btn").addEventListener("click", () => {
        BeApp.sendMessage("button clicked");
    });
</script>
```

## Notes

- Available only on U series, MRU series and Ultima
- The app main script is always `/beapps/<app_folder>/app.be` — when the user opens the app page while it is not running, the coordinator offers to start it first; apps without `app.be` are UI-only
- Start the backend script **before** the user opens the app page — `open` events sent while no backend is running stay in the queue but are cleared on a fresh `claim()`
- A blocking `receive()` blocks the whole script; the same TIMER-callback restrictions apply as for `ISC.receive()` — block only in the main script flow
- Channels are allocated dynamically from the reserved ISC range (fixed system channels are skipped); scripts cannot access reserved channels directly through the ISC module
- The app card in the coordinator UI has per-app toggles: **Start on boot** (the app main script is loaded and started with the other scripts at boot), **Restart if crashed** (an app that entered the error state is restarted automatically after a short delay) and **Show in sidebar**
- `BEAPP.log()` writes to a per-app circular buffer (PSRAM, up to 8 apps); read it with the **Log** button on the app card in the coordinator UI
