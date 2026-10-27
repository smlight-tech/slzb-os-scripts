**This script requires SLZB-OS v3.4.2 or higher**<br>
**TI radios only (CC2652P / CC2652P7 / CC2674P10) with the Zigbee coordinator firmware**<br>

# znp_router.be
Turns a TI radio module with the Z-Stack coordinator (ZNP) firmware into a Zigbee **router** of another network, without flashing the router firmware. The script talks to the radio over the Z-Stack Monitor and Test API (MT): it switches the radio's logical type to router, joins an open network (BDB network steering) and then answers the Basic cluster reads of the coordinator's interview. The routing itself runs in the radio.

## Before the start
- Mode page: the radio works as a **Zigbee coordinator** (network socket), not in Zigbee Hub mode.
- Nothing is connected to this radio (Zigbee2MQTT / ZHA of this coordinator): they would form their own network on it again.
- **Permit join** is open on the network the radio has to join.

> [!WARNING]
> The first run **clears the network of the radio** (its PAN, keys and devices): the radio stops being a coordinator. To make it a coordinator again, start Zigbee2MQTT / ZHA on it — they form a new network on it, or flash the coordinator firmware again.

## Settings
At the top of the script:

| Variable | Default | Description |
|----------|---------|-------------|
| `CHIP` | `1` | Radio module number |
| `CHANNELS` | `0x07FFF800` | Channels to search: bit n = channel n (11..26 by default). `0x00000800` = channel 11 only |
| `EXT_PAN_ID` | `nil` | Extended PAN ID of the network to join, e.g. `"00124b0001abcdef"`; `nil` joins the first open network |
| `REJOIN` | `false` | `true`: leave the current network and search again (set it back to `false` afterwards) |
| `MANUFACTURER`, `MODEL` | `"SMLIGHT"`, `"SLZB ZNP router"` | What the coordinator shows for the router |

## How it works
1. Checks that the radio is a TI chip with the coordinator firmware, that no socket client is connected and that the firmware has the router role compiled in (`UTIL_GET_DEVICE_INFO`).
2. If the radio is not a router yet (or `REJOIN = true`): clears the network state (`STARTUP_OPTION`), writes the router settings to NV (logical type, any PAN, extended PAN ID, channels, network key from the trust center) and restarts the radio.
3. A radio that is already in a network comes back to it (`ZDO_STARTUP_FROM_APP`). Otherwise it searches for an open network every 30 s until one lets it in.
4. While it runs, the script answers Basic cluster reads (manufacturer, model, power source, ...) so the coordinator finishes the interview. When the radio restarts (a Leave from the coordinator, a crash), the script sets it up again.

## Notes
- The script holds the radio UART (`ZB.suspend`) while it runs. Stopping it hands the UART back to the Zigbee socket; the radio stays in the network as a router until it restarts.
- After a reboot of the device or the radio, the radio is back in the network only with the script running — keep **autostart** on (`#META {"start":1}` at the top of the script).
- Progress and errors are in the device log, prefixed with `[ZNP router]`.
