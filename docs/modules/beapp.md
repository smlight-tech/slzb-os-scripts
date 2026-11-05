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

Append a line to the app's private ring log — viewable in the coordinator UI via the **Log** button on the app card. **No `claim()` needed** — a background app script can log at any time; the app is identified by the script's own path (`/beapps/<folder>/app.be`). The buffer lives in PSRAM, is created on first use (4096 bytes by default) and silently drops the oldest lines when full; it survives script restarts, so the log stays readable while the app is stopped. Lines are prefixed with the current time. The firmware writes into the same log too: a load or runtime error of the backend (also in TIMER / event callbacks) with its traceback as an `[E]` line, and the crash-restarts of **Restart if crashed** as `[W]` lines — a crashed app can be diagnosed from its own log.

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
<link rel="stylesheet" href="/css/merged.css">
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

## Page styles

Link the coordinator's stylesheet and include the SDK, and the page looks like the rest of the web UI:

```html
<link rel="stylesheet" href="/css/merged.css">
<script src="/js/beAppSdk.js"></script>
```

The stylesheet holds a part of Bootstrap 5.3 in the colours of the web UI. Its text size is 14 px (`1rem`). The list below is what it offers: anything else of Bootstrap (nav, modal, dropdown, list group, progress, spinner, form validation, ...) is not there, style it in the page's own CSS.

**Light and dark theme.** The SDK sets `data-bs-theme` and `data-theme` (`light` / `dark`) on `<html>` and follows a change of the theme. The stylesheet needs nothing more; for the page's own CSS use the variables below, or `[data-theme="dark"]`.

**Accent colour.** The user chooses it under General → Appearance. The SDK sets it on `<html>` through the variables below and follows a change while the page is open, so a `btn-primary`, a switch or a link have it without any code. Without the SDK the page keeps the default teal. Use the variables in the page's own CSS rather than a fixed colour:

```css
.my-tag { background: var(--bs-primary-bg-subtle); color: var(--bs-primary-text-emphasis); }
.my-button { background: var(--bs-primary); color: var(--app-on-accent); }
.my-glow { box-shadow: 0 0 0 3px rgba(var(--bs-primary-rgb), .25); }
```

| Variable | What it is |
|----------|------------|
| `--bs-primary` | The accent colour |
| `--bs-primary-rgb` | The same as numbers, for `rgba(var(--bs-primary-rgb), .25)` |
| `--app-on-accent` | Text on the accent colour (dark in the dark theme, whose accent is light) |
| `--bs-primary-bg-subtle` | A soft background in the accent's hue |
| `--bs-primary-text-emphasis`, `--bs-primary-border-subtle` | Text and border in the accent colour |
| `--bs-link-color`, `--bs-link-hover-color` (and `-rgb`) | Links |
| `--bs-body-bg`, `--bs-body-color` | The background of the page and of cards, the text |
| `--bs-secondary-color` | Secondary text |
| `--bs-secondary-bg`, `--bs-tertiary-bg` | Two more backgrounds, for parts that stand out from it |
| `--bs-border-color` | Borders |
| `--bs-secondary`, `--bs-success`, `--bs-danger` | Status colours (`--bs-warning-rgb`, `--bs-info-rgb` as numbers only) |
| `--bs-font-monospace`, `--bs-border-radius` | The monospace font, the corners |

`BeApp.ready()` resolves with the accent too: `accent: {color, soft, on}`, each `#rrggbb` (accent, soft background, text on the accent). That is the value at the page's start; the variables follow a change, so prefer them.

**Classes.** `{n}` is `0` to `5`, `{bp}` is `sm`, `md` or `lg` (there is no `xl`, `xxl`). Only the grid columns and `d-*` have the `{bp}` forms.

| Group | Classes |
|-------|---------|
| Grid | `container`, `container-fluid`, `row`, `col`, `col-auto`, `col-1` to `col-12`, `col-{bp}`, `col-{bp}-auto`, `col-{bp}-1` to `col-{bp}-12`, `g-{n}`, `gx-{n}`, `gy-{n}` |
| Buttons | `btn`, `btn-primary`, `btn-secondary`, `btn-success`, `btn-danger`, `btn-warning`, `btn-link`, `btn-outline-primary`, `btn-outline-secondary`, `btn-outline-success`, `btn-outline-danger`, `btn-outline-warning`, `btn-sm`, `btn-lg`, `btn-check`, `btn-close`, `btn-group`, `btn-group-sm`, `btn-group-lg`, `btn-group-vertical`, `btn-toolbar`, `active`, `disabled` |
| Forms | `form-label`, `form-text`, `form-control`, `form-control-sm`, `form-control-lg`, `form-control-plaintext`, `form-control-color`, `form-select`, `form-select-sm`, `form-select-lg`, `form-check`, `form-check-inline`, `form-check-reverse`, `form-check-input`, `form-check-label`, `form-switch`, `form-range`, `col-form-label`, `col-form-label-sm`, `col-form-label-lg` |
| Input groups | `input-group`, `input-group-sm`, `input-group-lg`, `input-group-text` |
| Tables | `table`, `table-sm`, `table-hover`, `table-striped`, `table-striped-columns`, `table-bordered`, `table-borderless`, `table-active`, `table-group-divider`, `table-responsive`, `table-responsive-sm`, `table-responsive-md`, `table-responsive-lg`, `table-primary`, `table-secondary`, `table-success`, `table-danger`, `table-warning`, `table-info`, `table-light`, `table-dark` |
| Cards | `card`, `card-body`, `card-title`, `card-subtitle`, `card-text`, `card-link`, `card-header`, `card-footer`, `card-group`, `card-img`, `card-img-top`, `card-img-bottom`, `card-img-overlay` |
| Alerts | `alert`, `alert-primary`, `alert-secondary`, `alert-success`, `alert-danger`, `alert-warning`, `alert-info`, `alert-light`, `alert-dark`, `alert-heading`, `alert-link`, `alert-dismissible` |
| Badges | `badge` (with a `bg-*` of the list below) |
| Text | `h1` to `h6`, `small`, `lead`, `mark`, `fs-1` to `fs-6`, `fw-normal`, `fw-medium`, `fw-semibold`, `fw-bold`, `font-monospace`, `text-start`, `text-center`, `text-end`, `text-wrap`, `text-nowrap`, `text-break`, `text-truncate`, `text-lowercase`, `text-uppercase`, `text-capitalize`, `text-decoration-none` |
| Text colour | `text-body`, `text-body-secondary`, `text-muted`, `text-primary`, `text-secondary`, `text-success`, `text-danger`, `text-warning`, `text-info`, `text-light`, `text-dark`, `text-white` |
| Background | `bg-body`, `bg-body-secondary`, `bg-body-tertiary`, `bg-primary`, `bg-secondary`, `bg-success`, `bg-danger`, `bg-warning`, `bg-info`, `bg-light`, `bg-dark`, `bg-white`, `bg-transparent` |
| Borders | `border`, `border-0`, `border-top`, `border-bottom`, `border-start`, `border-end`, `border-top-0`, `border-bottom-0`, `border-start-0`, `border-end-0`, `border-primary`, `border-secondary`, `border-success`, `border-danger`, `border-warning`, `rounded`, `rounded-0` to `rounded-3`, `rounded-circle`, `rounded-pill` |
| Display | `d-none`, `d-block`, `d-inline`, `d-inline-block`, `d-flex`, `d-inline-flex`, `d-grid`, `d-{bp}-none`, `d-{bp}-block`, `d-{bp}-inline`, `d-{bp}-inline-block`, `d-{bp}-flex`, `d-{bp}-inline-flex`, `d-{bp}-grid`, `invisible`, `visually-hidden` |
| Flex | `flex-row`, `flex-row-reverse`, `flex-column`, `flex-column-reverse`, `flex-wrap`, `flex-nowrap`, `flex-fill`, `flex-grow-0`, `flex-grow-1`, `flex-shrink-0`, `flex-shrink-1`, `justify-content-start`, `justify-content-end`, `justify-content-center`, `justify-content-between`, `justify-content-around`, `justify-content-evenly`, `align-items-start`, `align-items-end`, `align-items-center`, `align-items-baseline`, `align-items-stretch`, `align-self-start`, `align-self-end`, `align-self-center`, `align-self-stretch`, `gap-{n}`, `row-gap-{n}`, `column-gap-{n}` |
| Spacing | `m-{n}`, `mt-{n}`, `mb-{n}`, `ms-{n}`, `me-{n}`, `mx-{n}`, `my-{n}`, `m-auto`, `mt-auto`, `mb-auto`, `ms-auto`, `me-auto`, `mx-auto`, `my-auto`, `p-{n}`, `pt-{n}`, `pb-{n}`, `ps-{n}`, `pe-{n}`, `px-{n}`, `py-{n}` |
| Size, position | `w-25`, `w-50`, `w-75`, `w-100`, `w-auto`, `h-25`, `h-50`, `h-75`, `h-100`, `h-auto`, `mw-100`, `mh-100`, `img-fluid`, `position-relative`, `position-absolute`, `position-sticky`, `overflow-auto`, `overflow-hidden`, `pe-none`, `pe-auto`, `align-baseline`, `align-top`, `align-middle`, `align-bottom` |

## Notes

- Available only on U series, MRU series and Ultima
- For the page's look see [Page styles](#page-styles)
- The app backend is sandboxed: it can read and write files only inside its own folder `/beapps/<app_folder>/` (`meta.json` is read-only) — keep the app's config and data there. `/be/`, system configs and other apps' folders are not accessible (see [FS](fs.md#notes)). An app that really needs them declares `"fs.system"` in the `permissions` of its `meta.json`; the manifest is read when the backend starts, and the permission is shown to the user before the install
- The app main script is always `/beapps/<app_folder>/app.be` — when the user opens the app page while it is not running, the coordinator offers to start it first; apps without `app.be` are UI-only
- The app folder is in the module path of the backend: split the code into several files and load them with `import <name>` (`/beapps/<app_folder>/<name>.be`)
- **OpenThread CLI**: the module [OT_CLI](ot_cli.md) controls the whole Thread network (including its network key), so an app backend may use it only with the `"thread.cli"` permission in `meta.json` (shown to the user before the install); without it `OT_CLI.exec()` raises `io_error`
- **Bytecode**: Berry does not validate bytecode, crafted bytecode can break out of the sandbox. So the backend loads precompiled bytecode only with the `"bytecode"` permission in `meta.json` (shown to the user before the install as full trust): `import <name>` then takes `<name>.bec` before `<name>.be`. Without it `.bec` files do not exist for the backend (`import` takes `<name>.be`) and any other file is parsed as source
- **Compatibility**: `"minFw"` (minimal SLZB-OS version) and `"models"` (compatible coordinator models, `*` wildcard) in `meta.json` are checked by the coordinator UI before the install — the APPS repository and the local installer do not install an app on an older OS or another model. The app's `README.md` (in the app folder, packed into the app zip) opens with the **README** button on the APPS repository card and on the installed app card; relative links and images point to files of the app folder
- **Developer mode**: `"dev": true` in `meta.json` adds a **DEV** badge and a **Files** button to the app card. It opens a file manager for the app folder (browse, upload, download, create, rename, delete); `.be` files open in the script editor and are saved in place, the editor stays open after a save. Restart the app with Stop / Start on its card to run the changed code. Remove the key before publishing the app
- Start the backend script **before** the user opens the app page — `open` events sent while no backend is running stay in the queue but are cleared on a fresh `claim()`
- A blocking `receive()` blocks the whole script; the same TIMER-callback restrictions apply as for `ISC.receive()` — block only in the main script flow
- Channels are allocated dynamically from the reserved ISC range (fixed system channels are skipped); scripts cannot access reserved channels directly through the ISC module
- The app card in the coordinator UI has per-app toggles: **Start on boot** (the app main script is loaded and started with the other scripts at boot), **Restart if crashed** (an app that entered the error state is restarted automatically after a short delay) and **Show in sidebar**
- The **Remove** button on the app card uninstalls the app: the backend script is stopped, `/beapps/<folder>/` is deleted with all files, and the app's config entry, pending restarts and ring log are dropped
- `BEAPP.log()` writes to a per-app circular buffer (PSRAM, up to 8 apps); read it with the **Log** button on the app card in the coordinator UI. Backend errors land there automatically (`[E]` lines, shown in red), no `BEAPP.log()` call is needed for that
