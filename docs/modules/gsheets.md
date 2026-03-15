# GSHEETS Module

Log data to Google Sheets from Berry scripts. Uses a Google Apps Script webhook to receive data and append rows to your spreadsheet.

## Setup

### Step 1 — Create a Google Sheet

1. Go to [Google Sheets](https://sheets.google.com) and create a new spreadsheet
2. Optionally add column headers in the first row (e.g. `Timestamp`, `Sensor`, `Value`, `Unit`)

### Step 2 — Add the Apps Script

1. In your spreadsheet, go to **Extensions** → **Apps Script**
2. Delete any existing code and paste the following:

```javascript
function doPost(e) {
  var sheet = SpreadsheetApp.getActiveSpreadsheet().getActiveSheet();
  var data = JSON.parse(e.postData.contents);
  var values = data.values || [];

  // Add timestamp as first column
  var row = [new Date()];
  for (var i = 0; i < values.length; i++) {
    row.push(values[i]);
  }

  sheet.appendRow(row);

  return ContentService.createTextOutput(
    JSON.stringify({ status: "ok", row: sheet.getLastRow() })
  ).setMimeType(ContentService.MimeType.JSON);
}
```

3. Click **Save** (Ctrl+S)

### Step 3 — Deploy as Web App

1. Click **Deploy** → **New deployment**
2. Click the gear icon next to "Select type" → choose **Web app**
3. Set:
   - **Description**: SLZB data logger (or anything)
   - **Execute as**: Me
   - **Who has access**: Anyone
4. Click **Deploy**
5. **Authorize** the script when prompted (click through the "unsafe app" warning — this is your own script)
6. Copy the **Web app URL** — it looks like:
   ```
   https://script.google.com/macros/s/AKfycbx.../exec
   ```

### Step 4 — Configure in SLZB

**Option A — Via UI (recommended):**

1. Go to **Scripts Integrations** page
2. Click the **GOOGLE SHEETS** tile
3. Paste the Web app URL
4. Enable and save

**Option B — In script:**

```berry
import GSHEETS
GSHEETS.setup("https://script.google.com/macros/s/AKfycbx.../exec")
```

## Functions

### GSHEETS.setup(webhook_url)

Override the webhook URL for this script session.

| Parameter | Type | Description |
|-----------|------|-------------|
| `webhook_url` | string | Google Apps Script Web app URL |

```berry
import GSHEETS
GSHEETS.setup("https://script.google.com/macros/s/AKfycbx.../exec")
```

### GSHEETS.append(value1 [, value2, ...])

Append a row to the spreadsheet. Accepts any number of arguments — strings, integers, or real numbers. Each argument becomes a column in the new row.

| Parameter | Type | Description |
|-----------|------|-------------|
| `value1` | string / int / real | First column value |
| `value2` | string / int / real | (optional) Second column value |
| `...` | string / int / real | (optional) Additional column values |

**Returns:** `int` — HTTP status code (200 on success)

The Apps Script above automatically adds a timestamp as the first column, so your data starts from the second column.

```berry
import GSHEETS

# Single value
GSHEETS.append("device started")

# Multiple values
GSHEETS.append("temperature", 23.5, "kitchen")

# Numbers and strings
GSHEETS.append("sensor_1", 42, 3.14, "ok")
```

**Result in Google Sheet:**

| Timestamp | Col B | Col C | Col D | Col E |
|-----------|-------|-------|-------|-------|
| 2025-01-15 10:30:00 | temperature | 23.5 | kitchen | |
| 2025-01-15 10:35:00 | sensor_1 | 42 | 3.14 | ok |

## Examples

### Log temperature periodically

```berry
import GSHEETS
import ZB
import TIMER

TIMER.setInterval(def()
    # Assuming a Zigbee temperature sensor
    GSHEETS.append("living_room", 22.5)
end, 300000)
```

### Log Zigbee sensor data

```berry
import GSHEETS
import ZB

ZB.on_message(def (msg)
    if msg["cluster"] == 0x0402
        var temp = msg["value"] / 100.0
        GSHEETS.append("temperature", temp, msg["src_addr"])
    elif msg["cluster"] == 0x0405
        var hum = msg["value"] / 100.0
        GSHEETS.append("humidity", hum, msg["src_addr"])
    end
end, 3600000)
```

### Log button presses

```berry
import GSHEETS
import BUTTON

BUTTON.on_press(def ()
    GSHEETS.append("button_press", "main_button")
end, 86400000)
```

### Log weather data hourly

```berry
import GSHEETS
import WEATHER
import TIMER

TIMER.setInterval(def()
    var w = WEATHER.get()
    if w
        GSHEETS.append(w["city"], w["temp"], w["humidity"], w["description"])
    end
end)
```

### Device uptime tracker

```berry
import GSHEETS
import TIMER
import SLZB

TIMER.setInterval(def()
    GSHEETS.append("daily_report", SLZB.uptime(), "seconds")
end)
```

## Customizing the Apps Script

### Without timestamp

If you don't want the automatic timestamp, modify the Apps Script:

```javascript
function doPost(e) {
  var sheet = SpreadsheetApp.getActiveSpreadsheet().getActiveSheet();
  var data = JSON.parse(e.postData.contents);
  var values = data.values || [];

  sheet.appendRow(values);

  return ContentService.createTextOutput(
    JSON.stringify({ status: "ok" })
  ).setMimeType(ContentService.MimeType.JSON);
}
```

### Log to a specific sheet tab

```javascript
function doPost(e) {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var sheet = ss.getSheetByName("SensorData");  // use specific tab name
  var data = JSON.parse(e.postData.contents);
  var values = data.values || [];

  var row = [new Date()];
  for (var i = 0; i < values.length; i++) {
    row.push(values[i]);
  }

  sheet.appendRow(row);

  return ContentService.createTextOutput(
    JSON.stringify({ status: "ok" })
  ).setMimeType(ContentService.MimeType.JSON);
}
```

### Route data to different tabs

```javascript
function doPost(e) {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var data = JSON.parse(e.postData.contents);
  var values = data.values || [];

  // Use first value as sheet tab name
  var tabName = values[0] || "Default";
  var sheet = ss.getSheetByName(tabName);
  if (!sheet) {
    sheet = ss.insertSheet(tabName);
  }

  var row = [new Date()];
  for (var i = 1; i < values.length; i++) {
    row.push(values[i]);
  }

  sheet.appendRow(row);

  return ContentService.createTextOutput(
    JSON.stringify({ status: "ok" })
  ).setMimeType(ContentService.MimeType.JSON);
}
```

Then in Berry:

```berry
import GSHEETS

# First argument is the tab name
GSHEETS.append("Temperature", 23.5, "kitchen")
GSHEETS.append("Humidity", 65, "kitchen")
GSHEETS.append("Events", "button_pressed")
```

## Updating the Apps Script

When you modify your Apps Script code, you must create a **new deployment** for changes to take effect:

1. Click **Deploy** → **Manage deployments**
2. Click the pencil icon on your deployment
3. Under **Version**, select **New version**
4. Click **Deploy**

The URL stays the same, so no changes needed on the SLZB side.

## Notes

- Each `append()` call makes one HTTPS request (~2-4 KB temporary RAM, freed immediately)
- The device needs internet access to reach `script.google.com`
- Google Apps Script has a daily quota of ~20,000 URL fetch calls for free accounts
- The webhook URL is long — the module supports URLs up to 255 characters
- Google Apps Script may return a 302 redirect on the first call; `SMHTTP` follows redirects automatically
- Data types are preserved: strings stay strings, numbers stay numbers in the spreadsheet
