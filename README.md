## Basic Information
SLZB-OS is the universal operating system for all SLZB-06x/MRx/06xU/MRxU devices and future devices in this series.
<br>SLZB-OS uses Berry Script Language [Official page](https://berry-lang.github.io/) Documentation: [berry’s documentation](https://berry.readthedocs.io/en/latest/) and [Berry in 20 minutes or less](https://berry.readthedocs.io/en/latest/source/en/Berry-in-20-minutes.html)

## Features of Berry on SLZB-OS
- Currently, you can run up to 3 scripts simultaneously (this may be increased in the future)
- If a script does not use events, each running script operates in a separate task and has a maximum stack of 5120 words (this may be increased in the future)
- If a script uses events, it runs in the event task (see the "Events" section for details)
- The ```SLZB``` module is loaded automatically for each script, but all other modules must be imported using ```import``` before use
- A script must contain metadata so that the system can correctly load it. Read more about this in the "Metadata" section.

## Metadata
Metadata is system information that SLZB-OS uses to determine how to load a script and its additional parameters.
<br>Metadata is divided into mandatory and optional.

### Mandatory Metadata
```#META {"start":1}``` This is the basic mandatory metadata. Mandatory metadata must always begin with the comment ```#META ``` (the space after #META is required!) and must end with a newline character (```\n```).
<br>If a script does not contain mandatory metadata, it will not be loaded at system startup, but you can still launch it manually.
<br>The ```start``` parameter defines the script's launch mode. Supported values:
- 0 - the script starts manually
- 1 - the script starts automatically at system startup

### Optional Metadata
`stack` - force stack size for this script. The default stack size is 5120, if your script is very large and crashes, it is probably out of memory, try using this option to increase the amount of memory.<br>
`psram` - If `true` then forces the script task to be placed in PSRAM completely. **Works only for U series devices.**<br>
**WARNING! If this option is active then you cannot access the file system from this script! Any attempt will result in a crash!**

## Event System (available since v2.8.2.dev0)
The event system allows you to "subscribe" to a specific event in SLZB-OS and specify a function to be called when this event occurs.
- The script runs in the task that triggered the event to which it is subscribed.
- The script's state is preserved between event calls (all global variables retain their state).
- The script will be stopped and subscriptions canceled if an error occurs during execution.
- A script that uses the event system should not use ```SLZB.delay()```.
- The script should not run for too long.
- No infinite loops inside.
- Different events may provide additional data when launching the script. Please check the documentation for the specific event.
- Some events take into account what you return via ```return```, so please check the documentation for the specific event.

Example: You subscribed to the event of receiving a new data packet from the Zigbee chip: ```ZB.on_pkt(zb_pkt_handler)```
- Reading and sending data to the Zigbee socket will be paused until the ```zb_pkt_handler()``` script function completes.
- If execution takes too long, it will cause a loss of connection to Z2M/ZHA, so you should not use delays here.
- If ```zb_pkt_handler()``` returns ```true```, the current data packet will not be sent to the Zigbee socket.

If a script is subscribed to multiple events and they occur simultaneously, they will be executed sequentially with a timeout of 500ms.<br>
This means that if your script function execution takes more than 500ms, you may miss one of the events. Please check the flowchart below:<br>
<img src="./images/be_events_ex.png?raw=true" width=650px/>

## API Modules of SLZB-OS
### SLZB - General Functions
```SLZB.delay(x)``` pauses script execution for X milliseconds. The maximum delay is 4,294,967,295 milliseconds or 1193 hours. Takes a single argument of type ```integer```.
<br>Example: ```SLZB.delay(1000)``` pauses script execution for 1 second.

```SLZB.millis()``` returns the number of milliseconds that have elapsed since the device started.
<br>Example: ```SLZB.log("device has been running for " .. SLZB.millis() / 1000 .. " seconds")``` prints the number of seconds since device startup to the console.

```SLZB.reboot()``` reboots the device.
<br>Example: ```SLZB.reboot()``` reboots the device immediately!

```SLZB.log(x)``` sends text to the SLZB-06 debug console.
<br>Example: ```SLZB.log("Hello world!")``` prints the text ```Hello world!``` to the developer console.

```SLZB.freeHeap()``` returns the total amount of free RAM in the system.
<br>Example: ```SLZB.log("Free RAM: " .. SLZB.freeHeap())``` prints the amount of free RAM in the console.

(Starting from v2.8.2.dev1)<br>
```SLZB.deviceModel()``` returns the device model (string).
<br>Example: ```SLZB.log("Device model: " .. SLZB.deviceModel())``` prints the device model (SLZB-06/SLZB-06P7/SLZB-06P10/SLZB-06M/SLZB-06Mg24) to the console.

### ZB - Access to the Zigbee Chip (Use with Caution)
#### Coexistence of the Zigbee Socket and the ZB Module
<img src="./images/zigbee access control.png?raw=true" width=650px/>
<br>SLZB-OS uses parallel task execution. This means that when you want to access the Zigbee chip, you must first "lock" access using ```ZB.suspend()```
<br>Most functions do this automatically, so you don’t need to worry, but some functionality requires doing this manually.

#### What Requires Access Locking?
- ```ZB.readBytes()``` You must lock access using ```ZB.suspend()``` before reading bytes from the Zigbee module; otherwise, the parallel Zigbee socket processing task may capture the Zigbee chip’s response.

#### Coexistence with the Event System
After executing ```ZB.suspend(true)```, events will no longer be generated:
- ```ZB.on_pkt```
- ```ZB.on_disconnect```
- ```ZB.on_connect```

#### Available Functions
```ZB.reboot()``` immediately reboots the Zigbee chip.
<br>Example: ```ZB.reboot()``` reboots the Zigbee chip.

```ZB.flashMode()``` switches the Zigbee chip to firmware mode. To return the chip to normal mode, restart it or send the appropriate bootloader command.
<br>Example: ```ZB.flashMode()``` puts the Zigbee chip into firmware mode.

```ZB.routerPairMode()``` starts a network search for pairing if the Zigbee chip is flashed as a router.
<br>Example: ```ZB.routerPairMode()``` starts a network search for pairing if the Zigbee chip is flashed as a router.

```ZB.writeBytes(x)``` sends bytes directly to the Zigbee chip. Takes a single argument of type ```bytes``` and returns an ```integer``` with the number of bytes sent.
<br>Example: ```ZB.writeBytes(bytes("FE00210120"))``` sends a ping packet to the Zigbee chip.

```ZB.readBytes()``` reads bytes from the Zigbee chip and returns ```bytes```. Before using this, stop the Zigbee socket processing using ```ZB.suspend(true)```, otherwise, the response from the Zigbee chip may be taken by the socket processing task.
<br>Example: ```ZB.readBytes()```.

```ZB.availableBytes()``` returns the number of bytes available for reading from the Zigbee chip. Returns an ```integer```.
<br>Example: ```ZB.availableBytes()```.

```ZB.getZbClients()``` returns the number of clients connected to the Zigbee socket. Returns an ```integer```.
<br>Example: ```ZB.getZbClients()```.

```ZB.suspend(x)``` stops or resumes Zigbee socket processing. Takes a single argument of type ```boolean```.
<br>Example: ```ZB.suspend(true) SLZB.delay(5000) ZB.suspend(false)```. Stops Zigbee socket processing for 5 seconds.

#### Available Events (available from v2.8.2.dev0)
```ZB.on_pkt(f)``` is called when a new data packet is received from the Zigbee chip in network coordinator mode. **Generated only if "Zigbee Socket packet processing" is enabled!!!**<br>
Takes one argument of type ```function```.<br>
When executed, provides two arguments:
- The ID of the received packet, type ```int```
- The full packet buffer, type ```bytes```

If you return ```true``` after execution, this data packet will not be sent to the Zigbee socket **(does not work for EFR32x)**
<br>Example: See [reports_stats.be](https://github.com/smlight-tech/slzb-os-scripts/blob/main/examples/report_stats/report_stats.be)

```ZB.on_connect(f)``` is called when a new socket client connects in network coordinator mode.<br>
Takes one argument of type ```function```.<br>
When executed, provides two arguments:
- The IP of the new client, type ```string```
- The ID of the new client (position in the client array), type ```int```

If you return ```true``` after execution, the connection from this client will not be accepted.
<br>Example:
```berry
def conn_cb(ip, id)
  SLZB.log("ip: " .. ip .. " id: " .. id)
  return true
end
ZB.on_connect(conn_cb)
```

```ZB.on_disconnect(f)``` is triggered when a socket client disconnects in network coordinator mode.  
Takes one argument of type ```function```.  
When executed, it provides one argument:
- The ID of the client (position in the client array), type ```int```

#### Example:
See [reports_stats.be](https://github.com/smlight-tech/slzb-os-scripts/blob/main/examples/report_stats/report_stats.be)

---

### FS - Access to the File System (Use with Caution)
(Available from v3.0.6)<br>
`bool` FS.deleteFile(filename:`string`) - Deletes a file by its full path. **Does not delete folders!** Returns `true` if the file was deleted successfully.<br>
#### Example:
```berry
FS.deleteFile("/be/test.be")
```
<br>
(Available from v3.0.6)<br>

FS.deleteDir(patch:`string`) - Deletes all files in a folder and deletes the folder itself. **Does not support recursion**, i.e. if a folder has **subfolders**, they will **not be deleted**.

#### Example:
```berry
FS.deleteDir("/be/my_test_directory")
```

<br>

`bool` FS.exists(filename:`string`) - checks if file(or folder) with `filename` exists. Returns `bool`.
#### Example:
```berry
if FS.exists("/be/test.be")
  SLZB.log("File exists")
else
  SLZB.log("File does not exists")
end
```

<br>

`File` FS.open(filename:`string`, mode:`string`) - native function for working with files.  
[Documentation](https://berry.readthedocs.io/en/latest/source/en/Chapter-7.html?highlight=open#open-function)  
#### Example:
See [get_file_size.be](https://github.com/smlight-tech/slzb-os-scripts/blob/main/examples/basic/get_file_size.be)

---

### WEBSERVER (Available from v2.8.2.dev0) - Allows Receiving or Sending Data via POST/GET Requests

The web server module provides a webhook at ```<device ip>/script/webhook```.  
Your script can receive POST/GET parameters when this webhook is called, and you can also return any text in response.

#### Features:
- Retrieve the number of GET/POST parameters
- Retrieve the value of GET/POST parameters
- Send any text in response to a request

#### Available Functions

```WEBSERVER.getArg(x)``` returns the value of argument ```x```.  
Takes as input an ```int``` (to get an argument by ID) or a ```string``` (to get an argument by name).  
Returns a ```string```. If the argument does not exist, it returns an empty string ```""```.

```WEBSERVER.hasArg(x)``` returns ```true``` if the argument ```x``` exists.  
Takes as input a ```string``` (argument name).

```WEBSERVER.send(x, y, z)``` sends a response to the client's request.<br>
**PLEASE USE THIS ONLY INSIDE ```WEBSERVER.on_webhook()```**  

Takes as input:
- `x` - response status code, type ```int```
- `y` - response content type, type ```string```
- `z` - response text, type ```string```

Returns: nothing.  

#### Example:
See [reports_stats.be](https://github.com/smlight-tech/slzb-os-scripts/blob/main/examples/report_stats/report_stats.be)

---

### Available Events

```WEBSERVER.on_webhook(f)``` - is triggered when a GET/POST request is made to ```<device ip>/script/webhook```.  
Takes one argument of type ```function```.  
When executed, it provides one argument:
- The number of GET/POST request arguments, type ```int```

#### Example:
See [reports_stats.be](https://github.com/smlight-tech/slzb-os-scripts/blob/main/examples/report_stats/report_stats.be)

---

### ZHB (Available from v2.9.6) - Allows you to access your ZigBee devices

| Attribute                                                                                                             | Description                                                                                                                                                                                                                                                                                                                                  |
| --------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `ZigbeeDevice`  getDevice( device name:`string` \| device network addr :`int` \| device ieee : `string` )  | this function allows you to get a device by its **name&#x20;**&#x6F;r **network address or IEEE**. Returns the `ZigbeeDevice` class if the device is found or an **error&#x20;**&#x69;f not.&#xA;Please note!&#xA;IEEE format must be `0x0000000000000000` (hex string).&#xA;Network addr must be a number!                                  |
| waitForStart( wait time:`int`)                                                                         | blocks script execution for \<wait time> seconds until Zigbee Hub starts.&#xA;Maximum 254 seconds to wait, if you specify 255 it will wait forever                                                                                                                                                                                           |
| permitJoin( time:`int`, addr:`int`)|(Available from v3.0.6)<br>Enables adding new devices to the network.<br>`time` - time in seconds that the network will be open.<br>Minimum 1 sec, maximum 254 seconds.<br>If you specify 0, the network will be closed immediately.<br>If you specify 255, the network will be open permanently.<br><br>`addr` - (optional) network address of the device on which you want to enable adding new devices. If not specified, the entire network will be opened |

#### Available classes

##### ZigbeeDevice
<table>
<tr><td> Attribute </td> <td> Description </td></tr>

<tr>
<td>

`bool`  matcher( manufacturer:`string`, model:`string`)
</td>
<td>

Matches the provided `model` and `manufacturer` with the device data, returns `true` if they match.&#xA;**Case sensetive.**
</td>
</tr>

<tr>
<td>

`string`  getName()
</td>
<td>

Returns the `name` of the device set by the user
</td>
</tr>

<tr>
<td>

`string`  getModel()
</td>
<td>

Returns device `model`
</td>
</tr>

<tr>
<td>

`string`  getManuf()</td>
<td>

Returns device `manufacturer`
</td>
</tr>

<tr>
<td>

`int`  getNwk()</td>
<td>

Returns the `network address` of the device
</td>
</tr>

<tr>
<td>

`int`  getPS()</td>
<td>

Returns the device `power source`
</td>
</tr>

<tr>
<td>

`int`  getBattery()</td>
<td>

Returns the device `battery percentage`
</td>
</tr>

<tr>
<td>

`int`  getIAS()</td>
<td>

Returns the device `IAS type`
</td>
</tr>

<tr>
<td>

`int`  getLastSeen()</td>
<td>

Returns the `timestamp` of the last time a data packet was received from the device
</td>
</tr>

<tr>
<td>

`int`  getLqi()</td>
<td>

Returns the device `LQI`
</td>
</tr>

<tr>
<td>

sendOnOff( state:`int`, channel:`int`)</td>
<td>

Sends a `state` command to the device to turn on or off. If your relay has multiple channels then specify the `channel` number as the second argument.**&#xA;**`channel` is optional, if not specified, **channel 1** will be used.
```berry
dev.sendOnOff(1) # turn on relay
dev.sendOnOff(0) # turn off relay
dev.sendOnOff(1, 2) # turn on relay channel 2
```
</td>
</tr>

<tr>
<td>

sendBri( brightness:`int`, channel:`int`)</td>
<td>

Changes the `brightness` of the lamp.&#xA;`brightness` range: 1 - 254&#xA;`channel` is optional, if not specified, **channel 1** will be used.
</td>
</tr>

<tr>
<td>

sendColor( color:`string`, channel:`int` )
</td>
<td>

Changes the color of the lamp.&#xA;Color format should be [#rrggbb](https://www.w3schools.com/colors/colors_hexadecimal.asp) or `r,g,b` <br>`channel` is optional, if not specified, **channel 1** will be used.
```berry
dev.sendColor("#0062ff") # send hex color
dev.sendColor("0,0,255") # send color in RGB format
```
</td>
</tr>

<tr>
<td>

sendColorTemp( mireds:`int`, channel:`int`)
</td>
<td>

Changes the color tempetature of the lamp in `mireds` - https://en.wikipedia.org/wiki/Mired&#xA;channel is optional, if not specified, **channel 1** will be used.
```berry
dev.sendColorTemp(180) # send Daylight(average) color temp
```
</td>
</tr>

<tr>
<td>

getVal( endpoint:`int`, cluster:`int`, attribute:`int` )
</td>
<td>

Returns the last saved value from the ZigBee end device.&#xA;Returns `nil` if the value is empty (has not been reported yet).&#xA;The type of the returned value depends on data type sent by the ZigBee device. It can be `bool`/`float`/`int`/`string`/`bytes`
</td>
</tr>

<tr>
<td>

`int` sendCmd(endpoint:`int`, cluster:`int`, command:`int`, payload:`bytes`(optional))
</td>
<td>

Allows you to send any ZCL command to your device!<br>Returns the ZCL transaction number (currently not used).
```berry
sendCmd(1, 6, 1) # turn on the relay
sendCmd(1, 6, 0) # will turn off the relay
```
</td>
</tr>

<tr>
<td>

`int` readAttr(endpoint:`int`, cluster:`int`, attr:`int`, ...)
</td>
<td>

(Available from v3.0.6)<br>Sends a request to read the attributes of the end device.<br>**Does not wait for a response**<br>You can add more attributes to the query by adding more arguments.

```berry
#0x0b04 - Electrical Measurement cluster
#0x0505 - RMSVoltage attribute
readAttr(1, 0x0b04, 0x0505) # req AC voltage report
readAttr(1, 0x0b04, 0x0505, 0x0508, 0x050b) # req AC voltage, current and power
```
</td>
</tr>

<tr>
<td>

`bool` bindToHub(scrEp:`int`, scrCl:`int`)
</td>
<td>

(Available from v3.0.6)<br>Sends a request to the end device to bind the `scrEp` and `scrCl` to the hub.
</td>
</tr>

<tr>
<td>

`bool` bindToDevice(scrEp:`int`, scrCl:`int`, dstIeee:`string`, dstEp:`int`)
</td>
<td>

(Available from v3.0.6)<br>Sends a request to the end device to bind the `scrEp` and `scrCl` to another end device with `dstIeee` and `dstEp`.<br>
`dstIeee` - IEEE address of the target device in HEX format (string).
</td>
</tr>

<tr>
<td>

`bool` bindToGroup(scrEp:`int`, scrCl:`int`, dstGroupAddr:`int`)
</td>
<td>

(Available from v3.0.6)<br>Sends a request to the end device to bind the `scrEp` and `scrCl` to the group with the address `dstGroupAddr`
</td>
</tr>
</table>

#### Example:
See [Zigbee Hub examples](https://github.com/smlight-tech/slzb-os-scripts/tree/main/examples/zigbee_hub)

---

### HTTP (Available from v2.9.8) - Allows your script to perform HTTP(S) POST/GET requests and receive a response

**All scripts share one common HTTP client! So you can only use it with one script at a time**

#### Features:
- HTTPS support (without certificate verification)
- GET/POST requests
- You can add headers
- You can add POST payload

#### Available Functions

| Attribute | Description |
|---|---|
| `bool` HTTP.open(url:`string`, method:`string`:`get\|post`, buffer:`int`) | Takes as input:<br>- `url` - Request URL<br>- `method` - Request method, `get` and `post` methods are supported, **case sensitive!**<br>- `buffer` - The size of the response buffer in which the server response will be stored.<br>It is not recommended to use a buffer larger than ```4096```.<br>If the server returns short text, you should use a small buffer accordingly.<br>If the size of the server response is larger than the buffer size, you will receive a truncated response.<br>**U-series devices can use a larger buffer.**<br>Returns `true` if HTTP client opened successfully. |
| `int` perform() | Executes the request and returns HTTP server response code. 200 is OK |
| `string` getResponse() | Returns server response text but no more than the buffer size.<br>**WARNING! You should not log text (SLZB.log()) longer than 1024 characters, this will lead to a crash!** |
| `bool` setPostData(data:`string`) | Sets the POST data for a POST request.<br>Returns ```true``` if post data set successfully.<br>Takes as input\:<br>- `data` - POST data, type ```string``` |
| `bool` setHeader(name:`string`, value:`string`) | Sets the header for request.<br>Returns `true` if successfully.<br>Takes as input\:<br>- `name` - header name, type `string`<br>- `value` - header value, type `string` |
| `bool` setMethod(method:`string`:`get\|post`) | **reuse api**<br>Call this function to change the `method` for an already opened client.<br>Sets the request method. Returns `true` if successfully.<br>Takes as input\:<br>- `method` - header name, type `string` |
| `bool` setUrl(url:`string`) | **reuse api**<br>Call this function to change the `url` for an already open client.<br>Sets the request method. Returns `true` if successfully.<br>Takes as input:<br>- `url` - new request url |
| `bool` isOpened() | Returns `true` if the HTTP client is already opened. |
| close() | Closes the client and frees memory |

##### Stream mode (Available from v3.1.6.dev3)
If you set buffer size to 0, the HTTP client will be run in <b>stream mode</b>, without buffer. You can read response in <b>chunks</b>, this allows you to process large pages or download files.

| Attribute | Description |
|---|---|
| `int` streamReadBytes(count:`int`, buffer:`bytes`) | Reads bytes from a stream in to external `bytes` buffer.<br>Will read no more than `count`, but not more than available in stream.<br>Returns the number of bytes readed.<br>IMPORTANT: `buffer` size must be equal or greater than `count` |
| `str` streamReadString(count:`int`) | Same as `streamReadBytes()` but make and return string from readed bytes |
| streamFlush(count:`int`) | Discard `count` number of bytes |
| `int` streamGetLen() | Returns the total number of bytes in the stream (from Content-Length header) |

#### HTTP client examples:
See [HTTP client examples folder](https://github.com/smlight-tech/slzb-os-scripts/blob/main/examples/http_client/)

---

### TIME (Available from v3.0.6) - Accurate date/time from the internal clock with NTP synchronization

#### Features:
- Can wait for NTP synchronization.
- Accurate time: hours, minutes, seconds.
- Accurate date: year, month, day, day of the week (**counting from Sunday**).
- Takes into account time zone and daylight saving time.

#### Available Functions

<table>
<tr><td> Attribute </td> <td> Description </td></tr>

<tr>
<td> 

bool waitSync(timeout:`int`)</td>
<td> 

Waiting for time synchronization for `timeout` seconds.<br>
If time is already synchronized it will return instantly.<br>
Maximum 254 seconds. Will return `false` if the time is not synchronized after the `timeout` expires.<br>
If you specify 255 seconds it will wait forever.
</td>
</tr>

<tr>
<td> 

`datetime` getAll()</td>
<td> 

returns an `datetime` map containing the **time** and **date**. Map structure is below:
```js
{
  year,
  month,
  day,
  hour,
  min,
  sec,
  weekday
}
```
</td>
</tr>

<tr>
<td> 

`time` getTime()</td>
<td> 

returns an `time` map. Map structure is below:
```js
{
  hour,
  min,
  sec
}
```
</td>
</tr>
</table>

#### TIME examples:
```berry
import TIME

var time = TIME.getAll()

if(!time)
  SLZB.log("Waiting for NTP sync...")
  
  TIME.waitSync(0xff)
  
  time = TIME.getAll()
end

SLZB.log("year: " .. time["year"] .. " month: " .. time["month"] .. " day: " .. time["day"] .. " hour: " .. time["hour"] .. " min: " .. time["min"] .. " sec: " .. time["sec"] .. " weekday: " .. time["weekday"])
```

---
### GPIO (Available from v3.1.6.dev3) - Direct GPIO control. Use with EXTREME caution

#### Features:
- GPIO mode selection (INPUT/OUTPUT).
- Reading the digital gpio state (HIGH/LOW).
- Reading voltage on GPIO inputs (maximum 3.3V).
- Changing the digital state for GPIO outputs (HIGH 3.3v /LOW 0v).
- PWM generation with 0 - 100% duty cycle.
- Frequency generator.

#### Available Functions

<table>
<tr><td> Attribute </td> <td> Description </td></tr>

<tr>
<td> 

MOD_OUTPUT</td>
<td> 

GPIO output mode constant
</td>
</tr>

<tr>
<td> 

MOD_INPUT</td>
<td> 

GPIO input mode constant
</td>
</tr>

<tr>
<td> 

pinMode(pin:`int`, mode: `GPIO input mode constant`)</td>
<td> 

Changes the operating mode for `pin` to `GPIO input mode constant`<br>
Must be called before using `pin` GPIO!
</td>
</tr>

<tr>
<td> 

`bool` digitalRead(pin:`int`)</td>
<td> 

Returns the digital state for `pin`
</td>
</tr>

<tr>
<td> 

digitalWrite(pin:`int`, state:`bool`)</td>
<td> 

Set `state` on gpio `pin`
</td>
</tr>

<tr>
<td> 

`int` analogRead(pin:`int`)</td>
<td> 

Returns voltage on `pin`.<br>
Range 0 - 4096 (0 - 3.3v)
</td>
</tr>

<tr>
<td> 

analogWrite(pin:`int`, dutycycle:`int`)</td>
<td> 

Generates a PWM with duty cycle `dutycycle` on gpio `pin`
</td>
</tr>

<tr>
<td> 

tone(pin:`int`, freq:`int`)</td>
<td> 

Generates a frequency `freq` on gpio `pin`
</td>
</tr>

<tr>
<td> 

noTone(pin:`int`)</td>
<td> 

Cancels frequency generation on gpio `pin`
</td>
</tr>

</table>

#### GPIO examples:
```berry
import GPIO

var power_pin = 46 # blue LED on SLZB-06p7u

GPIO.pinMode(power_pin, GPIO.MOD_OUTPUT)
GPIO.digitalWrite(power_pin, 1)
```

---

### MQTT (Available from v3.2.4) - Receiving/sending MQTT messages
**To use this module, please enable MQTT in the coordinator interface.**

#### Features:
- Subscribe to topics.
- Send messages.
- Receive messages.
- Connect to a local broker or a remote.

#### Available Functions

<table>
<tr><td> Attribute </td> <td> Description </td></tr>

<tr>
<td> 

`bool` waitConnect(time:`int`)</td>
<td> 

Waits for a connection to the MQTT broker.<br>
`time` in seconds from 1 to 254 seconds.<br>
If 255 is specified, it will wait forever.<br>
Returns `true` on success.<br>
</td>
</tr>

<tr>
<td> 

`bool` isConnected()</td>
<td> 

Returns `true` if the connection is active.
</td>
</tr>

<tr>
<td>

`bool` subscribe(topic:`string`)</td>
<td> 

Subscription to a `<base topic>/<topic>`. Returns `true` on success.<br>
This function adds `<base topic>/` to your `topic`<br>
To subscribe to **all** subtopics use `#`, for example: `#` - will subscribe to all topics that `<base topic>` include.
You can configure `<base topic>` on the MQTT page.
</td>
</tr>

<tr>
<td> 

`bool` subscribeCustom(topic:`string`)</td>
<td> 

Subscription to a `topic`. Returns `true` on success.<br>
To subscribe to **all** subtopics use `/#`, for example: `/#` - will subscribe to all topics.
</td>
</tr>

<tr>
<td> 

`bool` publish(topic:`string`, payload:`string`)</td>
<td> 

Send `data` to a `<base topic>/<topic>`. Returns `true` on success.
</td>
</tr>

<tr>
<td> 

`bool` publishCustom(topic:`string`, payload:`string`)</td>
<td> 

Send `data` to a `/<topic>`. Returns `true` on success.
</td>
</tr>

<tr>
<td> 

on_message(handler:`func(topic, data)`)</td>
<td> 

This event is called when a new message is received.<br>
2 arguments are provided: `topic` - the topic to which the message was sent, `data` - the message text.
</td>
</tr>

</table>

#### MQTT examples:
```berry
import MQTT

MQTT.waitConnect(0xff) # wait for connection
MQTT.subscribe("my_test_topic") # subscribe to '<base topic>/my_test_topic' only
# MQTT.subscribe("my_test_topic/#") # subscribe to '<base topic>/my_test_topic' all subtopics.

def handler(topic, data)
  SLZB.log("Topic: " .. topic .. " data: " .. data)
end

MQTT.on_message(handler)

MQTT.publish("my_test_send", "hello from SLZB-OS!") # will send message to '<base topic>/my_test_send'
```

---

### BUZZER (FOR Ultima3 ONLY! Available from v3.2.5.dev1) - Plays a melody on the built-in buzzer
**This module is only available for Ultima3!**

#### Available Functions

<table>
<tr><td> Attribute </td> <td> Description </td></tr>

<tr>
<td> 

play(string:`melody`)</td>
<td> 

Plays a melody on the built-in buzzer<br>
`melody` - A string with a melody in RTTL format
</td>
</tr>

</table>

#### MQTT examples:
```berry
import BUZZER
BUZZER.play("Arkanoid:d=4,o=5,b=140:8g6,16p,16g.6,2a#6,32p,8a6,8g6,8f6,8a6,2g6")
```
