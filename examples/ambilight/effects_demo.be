#META {"start":0}
# Cycle through all LED effects, showing each for 5 seconds
# Ultima devices only!

var effects = [
  AMBILIGHT.SOLID, AMBILIGHT.BLUR, AMBILIGHT.RAINBOW,
  AMBILIGHT.BREATHING, AMBILIGHT.COLOR_WIPE, AMBILIGHT.COMET,
  AMBILIGHT.FIRE, AMBILIGHT.TWINKLE, AMBILIGHT.POLICE,
  AMBILIGHT.CHASE, AMBILIGHT.COLOR_CYCLE, AMBILIGHT.GRADIENT,
  AMBILIGHT.STROBE
]

var names = [
  "SOLID", "BLUR", "RAINBOW",
  "BREATHING", "COLOR_WIPE", "COMET",
  "FIRE", "TWINKLE", "POLICE",
  "CHASE", "COLOR_CYCLE", "GRADIENT",
  "STROBE"
]

AMBILIGHT.setColor(0x0062FF)
AMBILIGHT.setColor2(0xFF6200)
AMBILIGHT.setBrightness(150)
AMBILIGHT.setSpeed(50)

for i : 0 .. size(effects) - 1
  SLZB.log("Effect: " .. names[i])
  AMBILIGHT.setEffect(effects[i])
  SLZB.delay(5000)
end

AMBILIGHT.setEffect(AMBILIGHT.OFF)
SLZB.log("Demo complete")
