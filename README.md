## Basic Information
SLZB-OS is the unified operating system for all SLZB-06/06p7/06p10/06M/06Mg24 devices and future devices in this series.  
SLZB-OS uses the Berry Script Language [Official page](https://berry-lang.github.io/). Documentation: [Berry’s documentation](https://berry.readthedocs.io/en/latest/) and [Berry in 20 minutes or less](https://berry.readthedocs.io/en/latest/source/en/Berry-in-20-minutes.html).  

## Features of Berry on SLZB-OS
- You can currently run up to 3 scripts simultaneously (this limit may increase in the future).
- Each running script operates in a separate task with a maximum stack of 5120 words (this limit may also increase in the future).
- The module `SLZB` is loaded automatically for every script, but all other modules must be imported via `import` before use.
- A script must include metadata for the system to load it correctly. Read more about this in the "Metadata" section.

## Metadata
Metadata is system information used by SLZB-OS to determine how to load a script and its additional parameters.  
Metadata is divided into mandatory and optional categories.

### Mandatory Metadata
```#META {"start":1}``` is an example of basic mandatory metadata. Mandatory metadata must always begin with the comment `#META ` (a space after `#META` is required!) and end with the new line symbol `\n`.  
If a script does not contain mandatory metadata, it will not load at system startup but can still be run manually.  
The `start` parameter defines the script's launch mode. Supported values:
- `0` - script is disabled.
- `1` - script launches at system startup (autorun).

### Optional Metadata
Currently under development.

## SLZB-OS API Modules
### SLZB - General Functions
```SLZB.delay(x)``` Pauses script execution for `x` milliseconds. Maximum delay is 4,294,967,295 milliseconds or approximately 1193 hours. Accepts one argument of type `integer`.  
Example: ```SLZB.delay(1000)``` pauses script execution for 1 second.

```SLZB.millis()``` Returns the number of milliseconds since the device started.  
Example: ```SLZB.log("device has been running for " .. SLZB.millis() / 1000 .. " seconds")``` logs the number of seconds since device startup.

```SLZB.reboot()``` Reboots the device.  
Example: ```SLZB.reboot()``` immediately reboots the device.

```SLZB.log(x)``` Sends text to the SLZB-06 debug console.  
Example: ```SLZB.log("Hello world!")``` logs the text `Hello world!` to the developer console.

```SLZB.freeHeap()``` Returns the total amount of free system memory (RAM).  
Example: ```SLZB.log("Free RAM: " .. SLZB.freeHeap())``` logs the available RAM.

### ZB - Access to the ZigBee Chip (Use with Caution)
#### ZigBee Socket and Module Coexistence
<img src="./images/zigbee access control.png?raw=true" width=650px/>  
SLZB-OS supports parallel task execution. To access the ZigBee chip, you must first "lock" access using ```ZB.suspend()```.  
Most functions handle this automatically, but some require manual suspension.

#### Functions Requiring Access Lock
- ```ZB.readBytes()``` requires locking access via ```ZB.suspend()``` before reading bytes from the ZigBee module. Otherwise, the parallel ZigBee socket task might intercept the chip's response.

#### Available Functions
```ZB.reboot()``` Immediately reboots the ZigBee chip.  
Example: ```ZB.reboot()``` reboots the ZigBee chip.

```ZB.flashMode()``` Switches the ZigBee chip to firmware update mode. To return to normal mode, reboot the chip or send the appropriate bootloader command.  
Example: ```ZB.flashMode()``` switches the ZigBee chip to firmware update mode.

```ZB.routerPairMode()``` Initiates network pairing if the ZigBee chip is flashed as a router.  
Example: ```ZB.routerPairMode()``` starts network pairing.

```zb.writeBytes(x)``` Sends bytes directly to the ZigBee chip. Accepts one argument of type `bytes` and returns an `integer` representing the number of bytes sent.  
Example: ```ZB.writeBytes(bytes("FE00210120"))``` sends a ping packet to the ZigBee chip.

```ZB.readBytes()``` Reads bytes from the ZigBee chip and returns `bytes`. Before using, stop the ZigBee socket task with ```ZB.suspend(true)```; otherwise, the socket task might intercept the response.  
Example: ```ZB.readBytes()```.

```ZB.availableBytes()``` Returns the number of bytes available to read from the ZigBee chip as an `integer`.  
Example: ```ZB.availableBytes()```.

```ZB.getZbClients()``` Returns the number of clients connected to the ZigBee socket as an `integer`.  
Example: ```ZB.getZbClients()```.

```ZB.suspend(x)``` Suspends or resumes the ZigBee socket task. Accepts one argument of type `boolean`.  
Example: ```ZB.suspend(true) SLZB.delay(5000) ZB.suspend(false)``` suspends the ZigBee socket task for 5 seconds.

### FS - File System Access (Use with Caution)
```FS.exists(x)``` Checks if the specified file exists. Returns `boolean`.  
Example: ```FS.exists("/be/test.be")``` returns `true` if the script `/be/test.be` exists.

```FS.open(filename, mode)``` Native function for file operations. [Documentation](https://berry.readthedocs.io/en/latest/source/en/Chapter-7.html?highlight=open#open-function).  
Example: Refer to the [get_file_size.be](https://github.com/smlight-tech/slzb-os-scripts/blob/main/examlpes/basic/get_file_size.be) example.
