# OT_CLI — OpenThread CLI of the On-Device Border Router

> Available since: v3.4.3.dev2 | **U series, MRU series and Ultima in the mode "Thread+OTBR running on device"**

Run commands of the OpenThread CLI from a script and get their output — the same console as the **OpenThread CLI** card on the OTBR page, and the same commands as with `ot-ctl`, without the `ot` prefix: `state`, `netdata show`, `br omrprefix`, `srp server host`, `ping <address>`, `dataset active`, …

`exec()` **blocks the script** until the command is complete (the CLI printed `Done` or `Error ...`) or its timeout ends.

## Quick Example

```berry
import OT_CLI
import string

var state = OT_CLI.exec("state")           # "leader\nDone"
SLZB.log("Thread role: " .. string.split(state, "\n")[0])

# reachability of a Thread device, from the border router itself (8-byte payload, 1 echo request)
var r = OT_CLI.exec("ping fd2d:a8a4:cd80:1:1a2b:3c4d:5e6f:7a8b 8 1", 10000)
if r != nil && string.find(r, "1 packets received") >= 0
  SLZB.log("node is reachable")
end
```

## API Reference

| Function | Description |
|----------|-------------|
| `OT_CLI.exec(cmd:string, timeout:int=5000) -> string` | Run one CLI command and get its output, `nil` if the command did not end in time. |

### OT_CLI.exec(cmd:string, timeout:int=5000) -> string

| Parameter | Type | Description |
|-----------|------|-------------|
| `cmd` | string | CLI command without the `ot` prefix, 1–255 printable ASCII characters, e.g. `"netdata show"` |
| `timeout` | int | How long the command may run, ms (100 … 120000, values outside are clamped; default 5000) |

**Returns:** `string` — the output of the command, lines separated by `\n`, ending with the final `Done` or `Error <n>: <text>` line (the echo of the command and the prompt are not included). Output longer than 8 KB: its last 8 KB. `nil` — the command did not end within `timeout`: asynchronous commands such as `ping`, `scan`, `dns resolve` or `meshdiag` end only when their answers arrive, give them a longer timeout.

**Raises:**

| Error | When |
|-------|------|
| `value_error` | Empty or too long command, or a blocked command (see the notes) |
| `otbr_not_ready` | OpenThread is not running: the mode is not active, the border router is starting or restarting |
| `otbr_busy` | The command queue is full: several scripts and the OTBR page send commands at the same time |
| `internal_error` | The output was overwritten before it could be read (other commands printed more than 16 KB meanwhile), out of memory |
| `io_error` | An app backend without the `"thread.cli"` permission |

```berry
try
  var role = OT_CLI.exec("state")
except "otbr_not_ready"
  SLZB.log("the border router is not running")
end
```

```berry
var nd = OT_CLI.exec("netdata show")
var omr = OT_CLI.exec("br omrprefix")
var scan = OT_CLI.exec("scan", 15000)
```

## Notes

- Blocked commands: `reset`, `factoryreset`, `rcp …`, `diag …` and `ifconfig down` — they would restart or stop the stack in a way the firmware cannot follow. Use the OTBR page instead (Thread stop / start, *Reset this OTBR node*) or `SLZB.reboot()`.
- Changes made with CLI commands (`br omrconfig`, `br routeprf`, `nat64 disable`, `dataset …`) are applied at once but most of them are not saved by OpenThread: after a restart the settings of the OTBR page apply again. The Thread network itself (`dataset commit active`) is saved.
- Commands run one after another, together with the commands of the OTBR page: a command waits until the ones before it are complete. Its output also appears in the console on the OTBR page.
- A command takes the OpenThread stack only for the moment it runs — the border router keeps working while a script waits for the answer of an asynchronous command.
- App backends (BEAPP) need the `"thread.cli"` permission in `meta.json`, otherwise `exec()` raises `io_error`. Regular scripts have no such limit.

## See Also

- [BEAPP](beapp.md) — app permissions
- [PING](ping.md) — ping hosts of the LAN
