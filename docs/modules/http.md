# HTTP — HTTP Client

> Available since: v2.9.8. Stream mode since v3.1.6.dev3.

Make HTTP/HTTPS GET and POST requests from your scripts and process responses.

- HTTPS is supported (without certificate verification).
- **All scripts share one HTTP client** — only one script can use it at a time.

## Quick Example

```berry
import HTTP

if HTTP.open("https://example.com/api/data", "get", 1024, false)
  var code = HTTP.perform()
  if code == 200
    SLZB.log("Response: " .. HTTP.getResponse())
  end
  HTTP.close()
end
```
```berry
# best if you need to send or receive a small payload (up to 5kb for non-U devices and up to 30kb for U devices)
def http_example()
  # 1024 - response buffer size. false - stream mode disabled
  HTTP.open("https://echo.free.beeceptor.com/", "post", 1024, false)
  HTTP.setHeader("Test-header", "test value")
  HTTP.setHeader("Content-Type", "application/x-www-form-urlencoded")
  HTTP.setPostData("post_data=test&post_data2=test2")
  
  var code = HTTP.perform()
  SLZB.log("code: " .. code)
  SLZB.log("response: " .. HTTP.getResponse())
  HTTP.close()
end
```

## API Reference

### Standard Mode

| Function | Description |
|----------|-------------|
| `HTTP.open(url:string, method:string, buffer:int, streamMode:bool?) -> bool` | Open the HTTP client. `method`: `"get"` or `"post"` (**case sensitive**). `buffer`: response buffer size in bytes (recommended max ~4096; U-series can use more). `streamMode`: set client to stream mode, optional |
| `HTTP.perform() -> int` | Execute the request. Returns: `int` (HTTP status code, 200 = OK). |
| `HTTP.getResponse() -> string` | Get the response text, up to `buffer` size. **Do not log responses longer than 1024 characters — this will crash!** |
| `HTTP.setPostData(data:string) -> bool` | Set POST request body. |
| `HTTP.setHeader(name:string, value:string) -> bool` | Set a request header. |
| `HTTP.setMethod(method:string) -> bool` | Change method on an already-open client (**reuse API**). |
| `HTTP.setUrl(url:string) -> bool` | Change URL on an already-open client (**reuse API**). |
| `HTTP.isOpened() -> bool` | Check if the client is currently open. |
| `HTTP.isStreamMode() -> bool` | Check if the client is in stream mode. |
| `HTTP.close() -> nil` | Close the client and free memory. |

### Stream Mode
Stream mode allows you to upload or download large amounts of data because it does not use internal buffer.

## Quick Example

```berry
import HTTP

# option if you need to send/receive a lot of data. Allows you to send/receive in small parts but is a bit more complicated to use
def stream_http_example()
  var payload = "post_data=test&post_data2=test2"

  # size(payload) - the amount of data to be sent. (for "get" it always 0)
  # We add 1 here because the string ends with a special terminator character that size() doesn't see.
  #
  # true - stream mode enabled
  HTTP.open("https://echo.free.beeceptor.com/", "post", size(payload), true)
  HTTP.setHeader("Test-header", "test value")
  HTTP.setHeader("Content-Type", "application/x-www-form-urlencoded")
  
  # HTTP.setPostData("post_data=test&post_data2=test2") does not work in stream mode
  
  HTTP.completeStreamConfig() # required in stream mode. call it after all headers set
  
  # here we write POST data
  # you can call this multiple times to send data in chunks but the total size must not be more than what you specified in open()
  HTTP.streamWriteString(payload)
  
  var code = HTTP.perform()
  SLZB.log("code: " .. code)
  
  if (code != 200)
    HTTP.close()
    return
  end
  
  # SLZB.log("response: " .. HTTP.getResponse()) does not work in stream mode
  
  var responseLen = HTTP.streamGetLen()
  SLZB.log("responseLen: " .. responseLen)
  
  if (responseLen == -1)
    SLZB.log("server returned chunked response! reading it in chunks...")
    var responseString = nil
    
    while (1)
      if (responseString != "")
        responseString = HTTP.streamReadString(128)
        SLZB.log("response chunk: " .. responseString)
        
      else
        break
      end
    end
    
    SLZB.log("done")
  
  else
    var responseString = HTTP.streamReadString(512)
    SLZB.log("response: " .. responseString)
    HTTP.streamFlush(0xff)
  end
  
  HTTP.close()
end

SLZB.log("Running stream example...")
stream_http_example()
```

| Function | Description |
|----------|-------------|
| `HTTP.streamReadBytes(count:int, buffer:bytes) -> int` | Read bytes from the stream into a `bytes` buffer. `buffer` size must be >= `count`. Returns actual bytes read. |
| `HTTP.streamReadString(count:int) -> string` | Read bytes from the stream as a string. |
| `HTTP.streamFlush(count:int) -> nil` | Discard `count` bytes from the stream. |
| `HTTP.streamWriteString(data:string) -> nil` | Write string to stream. |
| `HTTP.streamWriteBytes(data:bytes) -> nil` | Write bytes to stream. |
| `HTTP.completeStreamConfig() -> nil` | Call this after the client settings are complete (headers and timeout are set). |
| `HTTP.streamGetLen() -> int` | Returns response size (from `Content-Length` header). Wil return -1 for chunked response. |

## See Also

- [WEBSERVER — Incoming HTTP requests](webserver.md) — For receiving requests *on* your device
- [MQTT — Messaging](mqtt.md) — Alternative communication channel
- [Example: HTTP GET](../../examples/http_client/http_get.be)
- [Example: HTTP POST](../../examples/http_client/http_post.be)
- [Example: Stream mode HTML parser](https://github.com/Tarik2142/slzb-outage-commander/blob/main/parser.be)
