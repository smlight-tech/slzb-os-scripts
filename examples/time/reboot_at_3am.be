#META {"start":1}
# Reboot the device every day at 3:00 AM
# Checks the clock every 60 seconds

import TIME

SLZB.log("Waiting for NTP sync...")
TIME.waitSync(0xff)
SLZB.log("Time synced!")

while true
  var t = TIME.getTime()

  if t["hour"] == 3 && t["min"] == 0
    SLZB.log("It's 3:00 AM — rebooting!")
    SLZB.reboot()
  end

  SLZB.delay(60000) # check every 60 seconds
end
