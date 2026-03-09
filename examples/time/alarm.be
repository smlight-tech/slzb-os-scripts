#META {"start":1}
# Configurable alarm — gentle wake-up with ambilight and buzzer
# Ultima3 only!
#
# The alarm gradually increases LED brightness and plays
# melodies from quiet to loud over several stages.
#
# Configuration:
#   Set alarm time per day of the week, or nil to skip that day.
#   alarm_color — LED color during alarm (0xRRGGBB)

import TIME, AMBILIGHT, BUZZER

# --- Configuration ---
# Set [hour, min] for each day, or nil to disable
var sun = nil          # Sunday    — no alarm
var mon = [7, 0]       # Monday    — 7:00
var tue = [7, 0]       # Tuesday   — 7:00
var wed = [7, 30]      # Wednesday — 7:30
var thu = [7, 0]       # Thursday  — 7:00
var fri = [7, 30]      # Friday    — 7:30
var sat = [9, 0]       # Saturday  — 9:00

var schedule = [sun, mon, tue, wed, thu, fri, sat]
var alarm_color = 0xFFAA00  # warm orange
# ----------------------

SLZB.log("Waiting for NTP sync...")
TIME.waitSync(0xff)
SLZB.log("Alarm configured")

def run_alarm()
  SLZB.log("Alarm started!")

  AMBILIGHT.setColor(alarm_color)
  AMBILIGHT.setEffect(AMBILIGHT.Eff_Breathing)

  # Stage 1 — soft glow, gentle melody
  AMBILIGHT.setBrightness(30)
  AMBILIGHT.setSpeed(20)
  BUZZER.play("s1:d=8,o=6,b=80:c,e,g,e,c")
  SLZB.delay(15000)

  # Stage 2 — brighter, cheerful tune
  AMBILIGHT.setBrightness(80)
  AMBILIGHT.setSpeed(35)
  BUZZER.play("s2:d=8,o=6,b=100:c,e,g,c7,g,e,c")
  SLZB.delay(15000)

  # Stage 3 — bright, upbeat melody
  AMBILIGHT.setBrightness(150)
  AMBILIGHT.setSpeed(50)
  BUZZER.play("s3:d=4,o=6,b=120:c,e,g,c7,8p,g,e,c,e,g,c7")
  SLZB.delay(15000)

  # Stage 4 — full brightness, lively tune
  AMBILIGHT.setBrightness(254)
  AMBILIGHT.setEffect(AMBILIGHT.Eff_Rainbow)
  AMBILIGHT.setSpeed(60)
  BUZZER.play("s4:d=4,o=6,b=140:c,e,g,c7,e7,c7,g,e,c,e,g,c7,e7,g7")
  SLZB.delay(15000)

  # Finish — keep rainbow going, no more buzzer
  SLZB.log("Alarm complete — good morning!")
end

var triggered_today = false

while true
  var t = TIME.getAll()
  var today = schedule[t["weekday"]]

  if today == nil
    triggered_today = false
    SLZB.delay(30000)
    continue
  end

  var a_hour = today[0]
  var a_min = today[1]

  # reset trigger flag after alarm minute passes
  if t["hour"] != a_hour || t["min"] != a_min
    triggered_today = false
  end

  if t["hour"] == a_hour && t["min"] == a_min && !triggered_today
    triggered_today = true
    run_alarm()
  end

  SLZB.delay(30000) # check every 30 seconds
end
