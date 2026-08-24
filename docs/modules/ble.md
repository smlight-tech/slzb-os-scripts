# BLE Module

Interface for receiving BLE advertisements.<br>
**This module requires SLZB-OS v3.3.3.dev7 or later and a U-series or Ultima device!**

## Setup

1. Go to **BLE** page
2. Enable the **BLE**
3. Reboot device

## API Reference

| Function | Description | Returns |
|----------|-------------|---------|
| `BLE.on_packet(callback:function(bytes:addr, int:addr_type, int:rssi, int:adv_type, bytes:adv_data))` | Sets the callback that will be called when a BLE advertisement is received.<br>`addr` - 6 bytes of sender MAC<br>`addr_type` - BLE Device address type, can be:<br>(0) - public,<br>(1) - radnom,<br>(255) - anonymous<br>`rssi` - signal quality of the received packet<br>`adv_type` - advertising PDU type. Can be one of following constants:<br>(0) - indirect advertising - connectable and scannable,<br>(1) - direct advertising - connectable,<br>(2) - indirect scan response - not connectable - scannable,<br>(3) - beacon only - not connectable - not scannable,<br>(4) - scan response<br>`adv_data` - raw advertising data |
| `BLE.getStatus()` | Returns the current status of the BLE controller. See "BLE controller status enum". | `int` |
| `BLE.waitStart(int:timeout)` | Waits for the BLE controller to start. Returns `true` when the controller is started, otherwise returns `false`.<br>`timeout` - Specifies the wait time in milliseconds. The script will be paused during the wait time, so you should not call this function with a timeout in timer or event callbacks.<br>minimum wait time: 0ms<br>maximum wait time: 254ms<br>for values ​​greater than 254ms the wait time will be **forever** | `bool` |

BLE controller status enum:

| Key | Value | Description |
|-----|-------|-------------|
| `BLE.STATUS_IDLE` | 0 | controller is not enabled |
| `BLE.STATUS_STARTING` | 1 | controller is starting |
| `BLE.STATUS_STARTED` | 2 | controller started successfully |
| `BLE.STATUS_ERROR` | 3 | a fatal error occurred in the BLE controller. device reboot required |

## Examples

### Log BLE packets
```berry
import BLE

BLE.waitStart(0xff)

BLE.on_packet(def(addr, addr_type, rssi, adv_type, payload)
  # Please never use delays here, it can lead to packet drops!
  # If you still need to perform some action with a delay here, use a TIMER module!

  SLZB.log("BLE device MAC: " .. addr)
  SLZB.log("RSSI: " .. rssi)
  SLZB.log("Payload: " .. payload)
end)
```