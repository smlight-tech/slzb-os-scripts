# USBH — USB Serial Devices on the USB Host Port

> Available since: v3.4.2.dev1 · U devices only

Talk to USB serial adapters and dongles (CP210x, FTDI, CH34x, CDC-ACM) plugged into the USB port of the device — directly or through a USB hub: list the connected devices, open one, exchange strings or bytes, set the baud rate and the DTR / RTS lines.

`USBH.open()` returns an instance of the class `USBDEV`. While a script holds it, the script owns one of the two USB passthrough ports: the TCP server of that port is stopped, and everything the device sends waits in a buffer until the script reads it. When the instance is closed or the script stops, the port goes back to the USB passthrough (if it is configured on the **USB Passthrough** page).

## Setup

Enable **USB to Ethernet passthrough mode** on the **USB Passthrough** page and reboot — this switches the USB port to host mode. No device has to be opened on the page.

## Quick Example

```berry
import USBH

var ids = USBH.list()
if ids.size() > 0
  var dev = USBH.open(ids[0], 0, 115200)
  if dev
    dev.write("AT\r\n")
    SLZB.log("reply: " .. str(dev.readString(500)))
    dev.close()
  end
end
```

## API Reference

| Function | Description |
|----------|-------------|
| `USBH.list() -> list` | Ids of the USB devices connected right now. The id is the USB address of the device: it changes when the device is unplugged and plugged in again. Returns: `list` — of `int`, empty when nothing is connected or the USB host is not running. |
| `USBH.info(id:int) -> map` | Information about one device. Returns: `map` — see the keys below, `nil` if there is no such device. |
| `USBH.open(id:int, itf:int?, baud:int?) -> USBDEV` | Open a serial interface of the device. `itf` — interface number, default: the first compatible one (`info()["itf"]`). `baud` — default 115200. If the USB passthrough has this device open, its TCP client is disconnected and the script takes the port. Blocks until the port is open. Returns: `USBDEV` — or `nil` if the device is not there, the interface is not compatible, both ports are taken, or the USB controller has no free host channels. |
| `USBH.getUse(id:int, itf:int?) -> int` | Who has the device open right now. `itf` — check one interface only, default: any interface of the device. Returns: `int` — one of the `USBH.USE_*` constants; `USBH.USE_FREE` also when there is no such device. |
| `USBH.freePorts() -> int` | Number of passthrough ports (0–2) that nobody uses and that are not configured on the USB Passthrough page. A device opened by the USB passthrough can be taken over even when this is 0. |
| `USBH.isRunning() -> bool` | `true` when USB passthrough mode is enabled and the USB host has started. |
| `USBH.channels() -> map` | Host channels of the USB controller. Returns: `map` — `used`, `total`. |

Result of `USBH.info()` and `USBDEV.info()`:

| Key | Type | Description |
|-----|------|-------------|
| `id` | int | Device id (USB address) |
| `manuf` | string | Manufacturer |
| `product` | string | Model |
| `serial` | string | Serial number, `""` if the device has none |
| `vid` | int | Vendor id |
| `pid` | int | Product id |
| `itfCount` | int | Number of interfaces of the device |
| `itf` | list | Interface numbers that can be opened |
| `driver` | string | `"CP210x"`, `"FTDI"`, `"CH34x"`, `"CDC-ACM"` or `"generic"` |
| `alive` | bool | `false` — the device does not answer, unplug it and plug it in again |
| `use` | int | Who has the device open, one of the `USBH.USE_*` constants |

### Class USBDEV

An open serial port of a USB device, returned by `USBH.open()`. When the device is unplugged, the methods do not raise errors: they return `false`.

| Function | Description |
|----------|-------------|
| `USBDEV.isConnected() -> bool` | `true` while the device is connected and the instance owns its port. |
| `USBDEV.read(timeout:int?, max_len:int?) -> bytes` | Read the received data. Waits up to `timeout` ms (default 0 — no waiting) for the first byte, then returns what is there, up to `max_len` bytes (default / maximum 4096). Returns: `bytes` — empty if nothing arrived, `false` if the device is gone. |
| `USBDEV.readString(timeout:int?, max_len:int?) -> string` | Same as `read()`, the data comes as a string (may contain any bytes). Returns: `string` — `""` if nothing arrived, `false` if the device is gone. |
| `USBDEV.readStringUntil(terminator:string, timeout:int?, max_len:int?) -> string` | Collect the received data until it ends with `terminator` (one or more characters, e.g. `"\n"` or `"\r\n"`), `timeout` ms passed since the call (default 1000) or `max_len` bytes were read (default / maximum 4096). The terminator is removed from the stream and is not part of the result; data behind it stays for the next read. Returns: `string` — what was collected (without a terminator it is what arrived until the timeout, may be `""`), `false` if the device is gone. |
| `USBDEV.available() -> int` | Number of received bytes waiting to be read. Returns: `int` — or `false` if the device is gone. |
| `USBDEV.write(data:string) -> bool` | Send data; `bytes()` values are accepted too. The data is queued and sent in the background. Returns: `bool` — `false` if the device is gone or the transmit buffer stayed full for 1 s. |
| `USBDEV.setBaud(baud:int) -> bool` | Set the baud rate (8 data bits, no parity, 1 stop bit). Returns: `bool` — `false` if the device is gone or does not support it. |
| `USBDEV.setLines(dtr:bool, rts:bool) -> bool` | Set the DTR and RTS lines, `true` = active. Both are inactive after `open()`. Returns: `bool` — `false` if the device is gone or does not support it. |
| `USBDEV.info() -> map` | Same as `USBH.info()` for this device. Returns: `map` — or `false` if the device is gone. |
| `USBDEV.getId() -> int` | Id of the device, `0` when it is gone. |
| `USBDEV.close() -> nil` | Close the port and give it back to the USB passthrough. The instance cannot be used any more. |

## Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `USBH.USE_FREE` | 0 | Nobody has the device open |
| `USBH.USE_BRIDGE` | 1 | The USB passthrough (TCP bridge) has it open; `USBH.open()` takes the port over and disconnects the TCP client |
| `USBH.USE_SCRIPT` | 2 | Another script has it open; `USBH.open()` returns `nil` |
| `USBH.USE_SELF` | 3 | This script has it open |

## Notes

- it cannot be used together with active 4G/LTE add-on.
- `import USBH` is needed for the module; `USBDEV` instances come from `USBH.open()` only.
- A script can hold both passthrough ports, one `USBDEV` per port. A port taken by one script cannot be opened by another one.
- The USB controller has 8 host channels: every connected device takes 1, an open port 2–3 more, a USB hub 2. `open()` returns `nil` when they do not suffice — see `USBH.channels()`.
- Up to 4096 received bytes are buffered per port. When the script does not read fast enough, newer data is dropped.
- After the device is unplugged the instance stays dead even when the device comes back: find it with `USBH.list()` / `USBH.info()` and call `USBH.open()` again.
- A port that hits a USB transfer error is re-opened automatically with the settings of the script (baud rate, DTR / RTS).
- `read()` / `readString()` with a timeout block the script, not the firmware — keep the timeout reasonable so the script stays responsive to its other events.
- What a script opens is not saved: after a reboot the ports are what the **USB Passthrough** page configured.

## Examples

### Open a device only when nobody uses it

```berry
import USBH

for id : USBH.list()
  if USBH.getUse(id) == USBH.USE_FREE
    var dev = USBH.open(id)
    if dev
      SLZB.log("opened " .. USBH.info(id)["product"])
      break
    end
  end
end
```

### Find a device by its serial number

```berry
import USBH

def openBySerial(serial, baud)
  for id : USBH.list()
    var info = USBH.info(id)
    if info && info["serial"] == serial
      return USBH.open(id, nil, baud)
    end
  end
  return nil
end

var dev = openBySerial("72f86a7d038bef11906b29ccef8776e9", 115200)
if dev SLZB.log("opened, id " .. str(dev.getId())) end
```

### Read lines and survive a re-plug

```berry
import USBH
import TIMER
import string

var dev = nil
var line = ""

def poll()
  if !dev || !dev.isConnected()
    var ids = USBH.list()
    dev = ids.size() > 0 ? USBH.open(ids[0], nil, 9600) : nil
    return
  end

  var data = dev.readString()
  if data == false return end

  line += data
  var pos = string.find(line, "\n")
  while pos >= 0
    SLZB.log("line: " .. line[0 .. pos - 1])
    line = line[pos + 1 ..]
    pos = string.find(line, "\n")
  end
end

TIMER.setInterval(poll, 200)
```

### Read a reply line by line

```berry
import USBH

var dev = USBH.open(USBH.list()[0], 0, 115200)
if dev
  dev.write("ATI\r\n")

  for i : 0 .. 9                                  # at most 10 lines
    var line = dev.readStringUntil("\r\n", 500)
    if line == false break end                    # device is gone
    if line == "" continue end                    # empty line or timeout
    SLZB.log("line: " .. line)
    if line == "OK" || line == "ERROR" break end
  end

  dev.close()
end
```

### Binary request and the bootloader lines

```berry
import USBH

var dev = USBH.open(USBH.list()[0], 0, 115200)
if dev
  dev.setLines(false, true)   # RTS: reset active
  SLZB.delay(10)
  dev.setLines(false, false)  # release

  dev.write(bytes("FE00210120"))
  var resp = dev.read(1000)
  if resp != false SLZB.log("got " .. str(resp.size()) .. " bytes: " .. resp.tohex()) end
  dev.close()
end
```

## See Also

- [TCP_SERVER](tcpserver.md) — Serve the data of the device to network clients yourself
- [TIMER](timer.md) — Poll the device periodically
- [SLZB — Core](slzb.md) — `SLZB.delay()`, `SLZB.log()`
- [LTE](lte.md) — The 4G/LTE add-on modem (uses the USB host too)
