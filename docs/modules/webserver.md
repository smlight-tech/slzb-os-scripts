# WEBSERVER — Webhooks

> Available since: v2.8.2.dev0

Receive and respond to HTTP GET/POST requests via a built-in webhook endpoint.

Webhook URL: `http://<device-ip>/script/webhook`

## Quick Example

```berry
import WEBSERVER

def web_handler(arg_count)
  var name = WEBSERVER.getArg("name")
  WEBSERVER.send(200, "text/plain", "Hello, " .. name .. "!")
end

WEBSERVER.on_webhook(web_handler)
```

Then visit: `http://<device-ip>/script/webhook?name=World`

## API Reference

| Function | Description | Returns |
|----------|-------------|---------|
| `WEBSERVER.getArg(x:int\|string)` | Get argument value by index (`int`) or by name (`string`). Returns `""` if argument does not exist. | `string` |
| `WEBSERVER.hasArg(name:string)` | Check if argument exists by name. | `bool` |
| `WEBSERVER.send(code:int, content_type:string, body:string)` | Send a response to the client. **Use only inside `on_webhook` callback.** | — |

### Events

#### WEBSERVER.on_webhook(callback:`function`)

Triggered when a GET or POST request is made to `<device-ip>/script/webhook`.

Callback receives one argument:
- `arg_count` (`int`) — number of GET/POST request parameters

## See Also

- [HTTP — Outgoing HTTP requests](http.md) — For making requests *from* your device *to* other servers
- [Example: Report stats as JSON](../../examples/report_stats/) — Serves Zigbee statistics via webhook
