# HTTP — HTTP Client

> Available since: v2.9.8. Stream mode since v3.1.6.dev3.

Make HTTP/HTTPS GET and POST requests from your scripts and process responses.

**All scripts share one HTTP client** — only one script can use it at a time.

## Quick Example

```berry
import HTTP

if HTTP.open("https://example.com/api/data", "get", 1024)
  var code = HTTP.perform()
  if code == 200
    SLZB.log("Response: " .. HTTP.getResponse())
  end
  HTTP.close()
end
```

## API Reference

### Standard Mode

| Function | Description | Returns |
|----------|-------------|---------|
| `HTTP.open(url, method, buffer)` | Open the HTTP client. `method`: `"get"` or `"post"` (**case sensitive**). `buffer`: response buffer size in bytes (recommended max ~4096; U-series can use more). | `bool` |
| `HTTP.perform()` | Execute the request. | `int` (HTTP status code, 200 = OK) |
| `HTTP.getResponse()` | Get the response text, up to `buffer` size. **Do not log responses longer than 1024 characters — this will crash!** | `string` |
| `HTTP.setPostData(data)` | Set POST request body. | `bool` |
| `HTTP.setHeader(name, value)` | Set a request header. | `bool` |
| `HTTP.setMethod(method)` | Change method on an already-open client (**reuse API**). | `bool` |
| `HTTP.setUrl(url)` | Change URL on an already-open client (**reuse API**). | `bool` |
| `HTTP.isOpened()` | Check if the client is currently open. | `bool` |
| `HTTP.close()` | Close the client and free memory. | — |

### Stream Mode *(since v3.1.6.dev3)*

Set `buffer` to `0` in `HTTP.open()` to enable stream mode. This lets you process large responses in chunks without allocating a big buffer.

| Function | Description | Returns |
|----------|-------------|---------|
| `HTTP.streamReadBytes(count, buffer)` | Read bytes from the stream into a `bytes` buffer. `buffer` size must be >= `count`. Returns actual bytes read. | `int` |
| `HTTP.streamReadString(count)` | Read bytes from the stream as a string. | `string` |
| `HTTP.streamFlush(count)` | Discard `count` bytes from the stream. | — |
| `HTTP.streamGetLen()` | Total response size (from `Content-Length` header). | `int` |

## See Also

- [WEBSERVER — Incoming HTTP requests](webserver.md) — For receiving requests *on* your device
- [MQTT — Messaging](mqtt.md) — Alternative communication channel
- [Example: HTTP GET](../../examples/http_client/http_get.be)
- [Example: HTTP POST](../../examples/http_client/http_post.be)
- [Example: Stream mode HTML parser](https://github.com/Tarik2142/slzb-outage-commander/blob/main/parser.be)
