#META {"start":0}
# Log the current date and time to the console

import TIME

if !TIME.waitSync(30)
  SLZB.log("NTP sync failed after 30 seconds")
  return
end

var t = TIME.getAll()

SLZB.log("Date: " .. t["year"] .. "-" .. t["month"] .. "-" .. t["day"])
SLZB.log("Time: " .. t["hour"] .. ":" .. t["min"] .. ":" .. t["sec"])
SLZB.log("Weekday: " .. t["weekday"]) # 0 = Sunday
