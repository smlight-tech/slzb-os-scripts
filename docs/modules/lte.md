# LTE — 4G/LTE Add-On Modem (AT Commands, Status, SMS)

> Available since: v3.3.8.dev8 | **Devices with the 4G/LTE add-on only** (SLZB Ultima, SLZB-U2L)

Talk to the 4G/LTE add-on modem (SIMCom A7672G) from a script: send raw AT commands, read the connection status, signal level and operator, read / delete / send SMS and react to incoming SMS.

The add-on must be installed and enabled on the *4G/LTE* page. Everything SMS-related is also available on that page and via `POST /api2?action=22`.

Every function that talks to the modem (`at()`, `getSmsCount()` and the `sms*()` functions except `smsReceive()`) **blocks the script** until the modem answers — usually a fraction of a second, up to a minute or two for `smsSend()` on a bad network.

## Quick Example

```berry
import LTE
import json

SLZB.log("Operator: " .. LTE.getOperator() .. ", RSSI " .. LTE.getRssi() .. " dBm")

# wait for incoming SMS and answer the command "status"
while true
  var sms = LTE.smsReceive(60000)
  if sms != nil
    var msg = json.load(sms)
    SLZB.log("SMS from " .. msg["from"] .. ": " .. msg["text"])
    if msg["text"] == "status"
      LTE.smsSend(msg["from"], "RSSI " .. LTE.getRssi() .. " dBm, state " .. LTE.getStatus())
    end
    LTE.smsDelete(msg["i"])
  end
end
```

## API Reference

### Modem

| Function | Description |
|----------|-------------|
| `LTE.at(cmd:string, timeout:int=3000) -> string` | Send a raw AT command and get the whole reply. |
| `LTE.reboot() -> nil` | Restart the modem: connection teardown, hardware reset, full re-initialisation (about 30 s until it is online again). Non-blocking. |
| `LTE.getStatus() -> int` | Current modem / connection state, one of the `LTE.STATE_*` constants. |
| `LTE.getRssi() -> int` | Signal level in dBm (-113 … -51), `0` if unknown / no signal. Refreshed by the firmware every 30 s. |
| `LTE.getNetworkState() -> int` | Mobile network registration state, one of the `LTE.NWK_*` constants. Refreshed every 30 s. |
| `LTE.getOperator() -> string` | Mobile operator name, `""` if unknown. |

### SMS

| Function | Description |
|----------|-------------|
| `LTE.getSmsCount() -> int` | Number of messages in the SMS storage, `-1` on failure. |
| `LTE.smsRead(index:int) -> map` | Read the message stored in slot `index`. |
| `LTE.smsDelete(index:int) -> bool` | Delete the message stored in slot `index`. |
| `LTE.smsSend(number:string, body:string) -> bool` | Send an SMS (text mode, see the limits below). |
| `LTE.smsReceive(timeout:int=0) -> string` | Next incoming SMS as a JSON string, `nil` if nothing arrived. |

### LTE.at(cmd:string, timeout:int=3000) -> string

| Parameter | Type | Description |
|-----------|------|-------------|
| `cmd` | string | AT command without the line terminator, e.g. `"AT+CSQ"` |
| `timeout` | int | How long to wait for the final result code, ms (100 … 180000, default 3000) |

**Returns:** `string` — the whole reply, trimmed, including the final `OK` / `ERROR` line (lines are separated by `\r\n`). The call ends as soon as `OK` or `ERROR` arrives; after `timeout` whatever arrived so far is returned. `""` — the modem is not ready (not initialised yet, restarting, or busy for more than 15 s).

```berry
var r = LTE.at("AT+CPSI?")          # "+CPSI: LTE,Online,255-01,0x1234,...\r\n\r\nOK"
var clock = LTE.at("AT+CCLK?", 1000)
```

> The command goes to the modem as is. Do not send commands that change the port mode or the data session (`ATD`, `ATO`, `+++`, `AT+CMUX`, `AT+CGACT`, `AT+CFUN`, …) — the firmware will lose the modem and restart it. Commands that wait for an input prompt (`AT+CMGS`) are not supported, use `smsSend()`. Answers that arrive after the final `OK` (unsolicited result codes, e.g. the USSD reply `+CUSD:`) are not returned.

### LTE.smsRead(index:int) -> map

**Returns:** `map` with keys (`nil` if the slot is empty or the modem did not answer):

| Key | Type | Description |
|-----|------|-------------|
| `i` | int | Storage slot index |
| `st` | string | Status **before** this read: `"unread"`, `"read"`, `"unsent"`, `"sent"`. Reading marks a message as read. |
| `from` | string | Sender number or name (`"+380501234567"`, `"Kyivstar"`) |
| `ts` | string | Service centre time stamp as reported by the modem, `"yy/MM/dd,hh:mm:ss+zz"` (`zz` — time zone in quarters of an hour) |
| `text` | string | Message text, UTF-8 (Unicode messages are decoded) |

Slot numbering depends on the modem / SIM (usually starts at 0) and has gaps after deletions, so walk the slots until `getSmsCount()` messages were found:

```berry
var left = LTE.getSmsCount()
var i = 0
while left > 0 && i < 50
  var m = LTE.smsRead(i)
  if m != nil
    SLZB.log(str(i) .. ": " .. m["from"] .. " - " .. m["text"])
    left -= 1
  end
  i += 1
end
```

### LTE.smsSend(number:string, body:string) -> bool

| Parameter | Type | Description |
|-----------|------|-------------|
| `number` | string | Phone number: digits with an optional leading `+`, 3–20 characters |
| `body` | string | Message text, 1–160 characters |

Text mode limits: **one part, max 160 characters, basic Latin only** — letters, digits and common punctuation. No Cyrillic / accented letters / emoji and none of ``[ \ ] ^ { | } ~ ` ``. Returns: `bool` — `false` if the text or number is not acceptable, the modem is not ready or the network rejected the message.

### LTE.smsReceive(timeout:int=0) -> string

| Parameter | Type | Description |
|-----------|------|-------------|
| `timeout` | int | How long to wait for a message, ms. `0` (default) — just check, `-1` — wait forever |

**Returns:** `string` — JSON of the incoming message, the same payload as the web event `LTE_SMS_NEW`: `{"i":3,"from":"+380501234567","ts":"26/09/18,10:00:00+12","text":"Hello"}`. `nil` — nothing arrived within `timeout`.

The message stays in the SMS storage — delete it with `smsDelete(msg["i"])` once it is processed: the storage of a SIM card holds only 10–50 messages.

## Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `LTE.STATE_IDLE` | 0 | Modem support is not started (add-on disabled / not installed) |
| `LTE.STATE_STARTING` | 1 | Modem is being reset and initialised |
| `LTE.STATE_CONNECTING` | 2 | Initialised, data session is being established |
| `LTE.STATE_CONNECTED` | 3 | Online, IP address received |
| `LTE.STATE_ERROR` | 4 | Failure, the firmware is restarting the modem |
| `LTE.STATE_NO_SIGNAL` | 5 | No signal (check the antenna); AT commands and SMS functions still answer |
| `LTE.NWK_NOT_REGISTERED` | 0 | Not registered, not searching |
| `LTE.NWK_REGISTERED` | 1 | Registered, home network |
| `LTE.NWK_SEARCHING` | 2 | Searching for a network |
| `LTE.NWK_DENIED` | 3 | Registration denied |
| `LTE.NWK_UNKNOWN` | 4 | Unknown |
| `LTE.NWK_ROAMING` | 5 | Registered, roaming |
| `LTE.NWK_SMS_ONLY` | 6 | Registered for SMS only |

## Notes

- AT commands and SMS functions work in the states `STATE_CONNECTING`, `STATE_CONNECTED` and `STATE_NO_SIGNAL`; otherwise they return `""` / `-1` / `nil` / `false`.
- Incoming SMS are detected by the firmware within 30 s after arrival. The queue behind `smsReceive()` keeps the 8 newest messages and is shared by all scripts: a message is delivered to the script that reads it first, so handle SMS in one script.
- Messages that arrived while no script was reading stay queued (also from before the script was started) — check `ts` if old commands must be ignored.
- Parts of a long (concatenated) incoming message arrive as separate messages.
- `smsRead()` marks the message as read on the SIM; `smsReceive()` reports every message only once.
- SMS functions wait up to 30 s if the web page or the firmware is using the SMS storage at the same moment.

## Examples

### Forward every SMS to Telegram and free the slot

```berry
import LTE
import TELEGRAM
import json

while true
  var sms = LTE.smsReceive(-1)
  if sms != nil
    var msg = json.load(sms)
    TELEGRAM.send("SMS from " .. msg["from"] .. ": " .. msg["text"])
    LTE.smsDelete(msg["i"])
  end
end
```

### SMS alert from a Zigbee button

```berry
import LTE
import ZHB
ZHB.waitForStart(0xff)

ZHB.on_action(def (action, dev)
  if action == "single"
    LTE.smsSend("+380501234567", "Button pressed: " .. dev.getName())
  end
end)
```

## See Also

- [ISC — Inter-script communication](isc.md) — the mechanism behind `smsReceive()`
- [TELEGRAM](telegram.md) / [NTFY](ntfy.md) — Combine: forward SMS to a messenger
- [ZHB — Zigbee Hub](zhb.md) — Combine: SMS alerts from Zigbee sensors
