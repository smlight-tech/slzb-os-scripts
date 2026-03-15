# EMAIL Module

Send email alerts from Berry scripts via SMTP with TLS.

## Setup

### Option A — Configure via UI (recommended)

1. Go to **Scripts Integrations** page
2. Click the **EMAIL** tile
3. Fill in the SMTP settings:
   - **SMTP Host** — your email provider's SMTP server
   - **SMTP Port** — usually `465` for SSL/TLS
   - **Username** — your email login
   - **Password** — your email password or app-specific password
   - **From Address** — sender email address
   - **To Address** — recipient email address
4. Enable and save

### Common SMTP settings

| Provider | SMTP Host | Port |
|----------|-----------|------|
| Gmail | `smtp.gmail.com` | 465 |
| Outlook / Hotmail | `smtp.office365.com` | 465 |
| Yahoo | `smtp.mail.yahoo.com` | 465 |
| Zoho | `smtp.zoho.com` | 465 |

**Gmail users:** You need to create an [App Password](https://myaccount.google.com/apppasswords) instead of using your regular password. 2-Step Verification must be enabled first.

### Option B — Configure in script

```berry
import EMAIL
EMAIL.setup("smtp.gmail.com", 465, "user@gmail.com", "app-password", "user@gmail.com", "recipient@example.com")
```

This overrides the UI config for the current script session only.

## Functions

### EMAIL.setup(host, port, user, pass, from, to)

Override SMTP credentials for this script session.

| Parameter | Type | Description |
|-----------|------|-------------|
| `host` | string | SMTP server hostname |
| `port` | int | SMTP port (usually 465 for TLS) |
| `user` | string | SMTP username |
| `pass` | string | SMTP password |
| `from` | string | Sender email address |
| `to` | string | Recipient email address |

```berry
import EMAIL
EMAIL.setup("smtp.gmail.com", 465, "user@gmail.com", "app-password", "user@gmail.com", "alerts@example.com")
```

### EMAIL.send(subject, body)

Send an email. Returns `true` on success, `false` on failure.

| Parameter | Type | Description |
|-----------|------|-------------|
| `subject` | string | Email subject line |
| `body` | string | Email body (plain text) |

**Returns:** `bool` — `true` if sent successfully

```berry
import EMAIL

EMAIL.send("SLZB Alert", "Sensor triggered!")
```

## Examples

### Send alert on button press

```berry
import EMAIL
import BUTTON

BUTTON.on_press(def ()
    EMAIL.send("Button Alert", "The button on your SLZB device was pressed.")
end, 86400000)
```

### Temperature alert

```berry
import EMAIL
import ZB

ZB.on_message(def (msg)
    if msg["cluster"] == 0x0402
        var temp = msg["value"] / 100.0
        if temp > 30
            EMAIL.send("Temperature Alert", "High temperature detected: " .. str(temp) .. " C")
        end
    end
end)
```

### Daily status report

```berry
import EMAIL
import TIMER
import SLZB

TIMER.setInterval(def()
    EMAIL.send("SLZB Daily Report", "Device is online. Uptime: " .. str(SLZB.uptime()) .. " seconds.")
end)
```

## Notes

- Uses implicit TLS (direct TLS connection on port 465) — STARTTLS on port 587 is not supported
- `send()` uses ~5-8 KB of temporary RAM for the TLS handshake, freed immediately after
- The device needs internet access to reach the SMTP server
- Gmail requires an App Password (not your regular Google password)
- Each `send()` call opens a new connection, sends the email, and closes — no persistent connections
- Only plain text emails are supported (no HTML, no attachments)
