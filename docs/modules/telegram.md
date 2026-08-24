# TELEGRAM Module

Send and receive Telegram messages from Berry scripts via the Telegram Bot API.<br>

## Setup

### Option A — Configure via UI (recommended)

1. Go to **Scripts Integrations** page
2. Click the **TELEGRAM** tile
3. Enter your **Bot Token** and **Chat ID**
4. Enable and save

Scripts will automatically use the saved credentials — no tokens in your code.

### Option B — Configure in script

```berry
import TELEGRAM
TELEGRAM.setup("123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11", "987654321")
```

This overrides the UI config for the current script session only.

### How to get Bot Token and Chat ID

1. Open Telegram and search for **@BotFather**
2. Send `/newbot` and follow the instructions to create a bot
3. Copy the **Bot Token** (looks like `123456:ABC-DEF...`)
4. To get your **Chat ID**: send a message to your bot, then open `https://api.telegram.org/bot<YOUR_TOKEN>/getUpdates` in a browser — your chat ID is in the `chat.id` field

## Functions

### TELEGRAM.setup(token, chat_id)

Override credentials for this script session.

| Parameter | Type | Description |
|-----------|------|-------------|
| `token` | string | Bot API token from @BotFather |
| `chat_id` | string | Target chat ID |

```berry
import TELEGRAM
TELEGRAM.setup("123456:ABC-DEF...", "987654321")
```

### TELEGRAM.send(text, chat_id)

Send a text message to the configured chat. Returns the HTTP status code (200 = success).

| Parameter | Type | Description |
|-----------|------|-------------|
| `text` | string | Message text to send |
| `chat_id` | string | Optional. if specified, the message will be sent to this chat |

**Returns:** `int` — HTTP status code

```berry
import TELEGRAM

# Simple notification
TELEGRAM.send("Hello from SLZB!")

# With sensor data
var temp = 23.5
TELEGRAM.send("Temperature: " .. str(temp) .. "°C")
```

### TELEGRAM.getUpdates()

Poll Telegram for new incoming messages. Returns a list of message objects, or `nil` if there are no new messages. Automatically tracks the last seen message to avoid duplicates.<br>
Will throw an error if the internet is unavailable.<br>


**Returns:** `list` of `map` objects, or `nil`

Each message map contains:

| Key | Type | Description |
|-----|------|-------------|
| `text` | string | Message text |
| `from` | string | Sender's first name |
| `chat_id` | int | Chat ID the message came from |
| `message_id` | int | Unique message identifier |

```berry
import TELEGRAM
import SLZB

var msgs = TELEGRAM.getUpdates()
if msgs
    for msg : msgs
        SLZB.log("From: " .. msg["from"] .. " Text: " .. msg["text"])
    end
end
```

## Examples

### Send alert on button press

```berry
import TELEGRAM
import BUTTON

BUTTON.on_press(def ()
    TELEGRAM.send("Button pressed!")
end, 10000)
```

### Poll for commands

```berry
import TELEGRAM
import SLZB

while (1)
    var msgs = TELEGRAM.getUpdates()
    if msgs
        for msg : msgs
            if msg["text"] == "/status"
                TELEGRAM.send("Device is online!")
            elif msg["text"] == "/reboot"
                TELEGRAM.send("Rebooting...")
                SLZB.restart()
            end
        end
    end

    SLZB.delay(1000)
end
```

### Interactive light control

```berry
import TELEGRAM
import AMBILIGHT

while (1)
    var msgs = TELEGRAM.getUpdates()
    if msgs
        for msg : msgs
            var cmd = msg["text"]
            if cmd == "/on"
                AMBILIGHT.setEffect(AMBILIGHT.Eff_Solid)
                TELEGRAM.send("Light ON")
            elif cmd == "/off"
                AMBILIGHT.setEffect(AMBILIGHT.Eff_Off)
                TELEGRAM.send("Light OFF")
            elif cmd == "/red"
                AMBILIGHT.setColor(0xFF0000)
                TELEGRAM.send("Color set to red")
            end
        end
    end

    SLZB.delay(1000)
end
```

### Big example of a bot using the ZHB module to control Zigbee devices paired to a coordinator and WLED module to controll A1-SLWF-09 (or any other WLED controller).<br>
*Written for our demo-stand on Home Assistant Community Day 07/25/2026 in Kyiv*

```berry
#META {"start":0}
import TELEGRAM, ZHB, AMBILIGHT, BUZZER, NETWORK, WLED

TELEGRAM.setup("xxxxxxx")

NETWORK.waitReady(0xff)
ZHB.waitForStart(0xff)

var socket1 = ZHB.getDevice("Розетка")
var socket2 = ZHB.getDevice("Розетка 2")
var temperature = ZHB.getDevice("temperature")

AMBILIGHT.setColor(0x7bff00)
BUZZER.playPreset(BUZZER.Snd_Success)
AMBILIGHT.setEffect(AMBILIGHT.Eff_Blur)

def sendWlControll(state, chat)
  var wl_dev = "192.168.31.134"
  
  try
    state = state == 1 ? WLED.on(wl_dev) : WLED.off(wl_dev)
    if (state != 200)
      raise "wled_offline"
    end
    
    var res = state == 1 ? "увімкнено" : "вимкнено"
    TELEGRAM.send("WLED " .. res, chat)
  except ..
    TELEGRAM.send("Помилка: WLED пристрій не знайдено!", chat)
  end
end

def sendZbCotroll(dev, state, chat)
  try
    dev.sendOnOff(state)
    TELEGRAM.send(dev.getName() .. state == 1 ? " увімкнено" : " вимкнено", chat)

  except ..
    TELEGRAM.send("Помилка: цей зігбі пристрій не знайдено! Перевірте чи правильно вказано його назву", chat)
  end
end

while (1)
  var msgs = nil
  try
    msgs = TELEGRAM.getUpdates()
  except ..
    # девайс оффлайн
  end
  
  if msgs
    for msg : msgs
        var cmd = msg["text"]
        var chat_id = str(msg["chat_id"])
        var user = msg["from"]
        
        if (cmd == "/start")
          TELEGRAM.send("Привіт " .. user .. "!\n" ..
          "Це демонстраційний бот який виконується на SLZB-Ultima3 за допомогою скриптової мови Berry.\n" ..
          "Ви можете знайти файл цього бота підключившись до точки доступу 'SLZB-AP' і перейшовши на 192.168.31.165, файл знаходиться за адресою 'Scripts & Automation'-> 'Script Engine & Editor'\n\n" ..
          "Цей бот може напряму управляти підключеними до координатора пристроями завдяки режиму Zigbee Hub, ми підготували декілька команд щоб ви перевірили це особисто:\n" ..
          "/socket1_on\n" ..
          "/socket1_off\n" ..
          "/socket2_on\n" ..
          "/socket2_off\n" ..
          "/led_on\n" ..
          "/led_off\n" ..
          "/temperature", chat_id)
          
        elif (cmd == "/socket1_on")
          sendZbCotroll(socket1, 1, chat_id)
          
        elif (cmd == "/socket1_off")
          sendZbCotroll(socket1, 0, chat_id)
          
        elif (cmd == "/socket2_on")
          sendZbCotroll(socket2, 1, chat_id)
          
        elif (cmd == "/socket2_off")
          sendZbCotroll(socket2, 0, chat_id)
          
        elif (cmd == "/led_on")
          sendWlControll(1, chat_id)
          
        elif (cmd == "/led_off")
          sendWlControll(0, chat_id)
          
        elif (cmd == "/temperature")
          try
            var value = temperature.getVal(1, 0x0402, 0x0000)
            
            if (value != nil)
              TELEGRAM.send("Температура: " .. value, chat_id)
              
            else
              TELEGRAM.send("Пристрій ще не надсилав температуру. Будь ласка спробуйте пізніше", chat_id)
            end
          except
            TELEGRAM.send("Помилка: пристрій не знайдено", chat_id)
          end
        else
          TELEGRAM.send("Схоже, що таких вказівок мені не давали.\nПеревірте /start щоб побачити список доступних дій", chat_id)
        end
        #SLZB.log("Chat ID: " .. msg["chat_id"] .. " From: " .. msg["from"] .. " Text: " .. msg["text"])
    end
  end
  
  SLZB.delay(1000)
end
```

## Notes

- It is not recommended to call TELEGRAM module functions in TIMER callbacks because HTTP requests take a long time and can cause delays
- Messages are sent via HTTPS to `api.telegram.org` — the device needs internet access
- `getUpdates()` uses short polling (no long-polling) to avoid blocking the script
- Each `getUpdates()` and `send()` calls uses ~40 KB of temporary RAM, freed immediately after. On U-series devices PSRAM is used instead of RAM.
- The bot can only receive messages from users who have started a conversation with it first (Telegram requirement)
