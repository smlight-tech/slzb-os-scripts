var delayTime = 60 * 60 * 1000 # 1 hour cycle delay
var rebootAfter = 24 # reboot after 24 hours
var timePassed = 0 # variable for storing the number of hours passed

while timePassed < rebootAfter # we execute the loop until timePassed is less than rebootAfter
  SLZB.log("time to reboot: " .. rebootAfter - timePassed .. "hours") # log some text
  SLZB.delay(delayTime) # wait delayTime
  timePassed = timePassed + 1 # increase timePassed by one more
end

SLZB.reboot() # we have reached rebootAfter, reboot the device