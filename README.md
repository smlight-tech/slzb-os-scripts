## Basic Information
SLZB-OS is the only operating system for all SLZB-06/06p7/06p10/06M devices and future devices in this series.
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
Currently under development.

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

```FS.exists(x)``` checks if the specified file exists. Returns ```boolean```.  
#### Example:
```FS.exists("/be/test.be")```  
Returns ```true``` if the script ```/be/test.be``` exists.

```FS.open(filename, mode)``` is a native function for working with files.  
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

### ZHB (Available from v2.9.6)

| Attribute                                                                                                             | Description                                                                                                                                                                                                                                                                                                                                  |
| --------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `ZigbeeDevice`  getDevice( device name:`string` \| device network addr :`int` \| device ieee : `string` )  | this function allows you to get a device by its **name&#x20;**&#x6F;r **network address or IEEE**. Returns the `ZigbeeDevice` class if the device is found or an **error&#x20;**&#x69;f not.&#xA;Please note!&#xA;IEEE format must be `0x0000000000000000` (hex string).&#xA;Network addr must be a number!                                  |
| waitForStart( wait time:`int`)                                                                         | blocks script execution for \<wait time> seconds until Zigbee Hub starts.&#xA;Maximum 254 seconds to wait, if you specify 255 it will wait forever                                                                                                                                                                                           |

#### Available classes

##### ZigbeeDevice

| Attribute |                                                                                                                                                                                       Description |
| --------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `bool`  matcher( manufacturer:`string`, model:`string`) | Matches the provided `model` and `manufacturer` with the device data, returns `true` if they match.&#xA;**Case sensetive.** |
| `string`  getName()                                                   | Returns the `name` of the device set by the user                                                                                                                                                                                                                                                                                                                   |
| `string`  getModel()                                                  | Returns device `model`                                                                                                                                                                                                                                                                                                                                             |
| `string`  getManuf()                                                  | Returns device `manufacturer`                                                                                                                                                                                                                                                                                                                                      |
| `int`  getNwk()                                                       | Returns the `network address` of the device                                                                                                                                                                                                                                                                                                                        |
| `int`  getPS()                                                        | Returns the device `power source`                                                                                                                                                                                                                                                                                                                                  |
| `int`  getBattery()                                                   | Returns the device `battery percentage`                                                                                                                                                                                                                                                                                                                            |
| `int`  getIAS()                                                       | Returns the device `IAS type`                                                                                                                                                                                                                                                                                                                                      |
| `int`  getLastSeen()                                                  | Returns the `timestamp` of the last time a data packet was received from the device                                                                                                                                                                                                                                                                                |
| `int`  getLqi()                                                       | Returns the device `LQI`                                                                                                                                                                                                                                                                                                                                           |
| sendOnOff( state:`int`, channel:`int`)                      | Sends a `state` command to the device to turn on or off. If your relay has multiple channels then specify the `channel` number as the second argument.**&#xA;**`channel` is optional, if not specified, **channel 1** will be used.<br>EX:<br>`dev.sendOnOff(1) # turn on relay`<br>`dev.sendOnOff(0) # turn off relay`<br>`dev.sendOnOff(1, 2) # turn on relay channel 2` |
| sendBri( brightness:`int`, channel:`int`)                   | Changes the `brightness` of the lamp.&#xA;`brightness` range: 1 - 254&#xA;`channel` is optional, if not specified, **channel 1** will be used.                                                                                                                                                                                                                     |
| sendColor( color:`string`, channel:`int` )                            | Changes the color of the lamp.&#xA;Color format should be [#rrggbb](https://www.w3schools.com/colors/colors_hexadecimal.asp) or `r,g,b` <br>`channel` is optional, if not specified, **channel 1** will be used. <br>`dev.sendColor("#0062ff") # send hex color dev.sendColor("0,0,255") # send color in RGB format`                                       |
| sendColorTemp( mireds:`int`, channel:`int`)                 | Changes the color tempetature of the lamp in `mireds` - https://en.wikipedia.org/wiki/Mired&#xA;channel is optional, if not specified, **channel 1** will be used. `dev.sendColorTemp(180) # send Daylight(average) color temp`                                                                                                                        |
| getVal( endpoint:`int`, cluster:`int`, attribute:`int` )              | Returns the last saved value from the ZigBee end device.&#xA;Returns `nil` if the value is empty (has not been reported yet).&#xA;The type of the returned value depends on data type sent by the ZigBee device. It can be `bool`/`float`/`int`/`string`/`bytes`                                                                                                   |

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

#### HTTP client examples:
See [HTTP client examples folder](https://github.com/smlight-tech/slzb-os-scripts/blob/main/examples/http_client/)

---