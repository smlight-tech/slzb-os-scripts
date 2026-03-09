#META {"start":0}
# Cycle through all LED effects, showing each for 5 seconds
# Ultima devices only!

import AMBILIGHT

var effects = [
  AMBILIGHT.Eff_Solid, AMBILIGHT.Eff_Blur, AMBILIGHT.Eff_Rainbow,
  AMBILIGHT.Eff_Breathing, AMBILIGHT.Eff_ColorWipe, AMBILIGHT.Eff_Comet,
  AMBILIGHT.Eff_Fire, AMBILIGHT.Eff_Twinkle, AMBILIGHT.Eff_Police,
  AMBILIGHT.Eff_Chase, AMBILIGHT.Eff_ColorCycle, AMBILIGHT.Eff_Gradient,
  AMBILIGHT.Eff_Strobe
]

var names = [
  "Solid", "Blur", "Rainbow",
  "Breathing", "ColorWipe", "Comet",
  "Fire", "Twinkle", "Police",
  "Chase", "ColorCycle", "Gradient",
  "Strobe"
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

AMBILIGHT.setEffect(AMBILIGHT.Eff_Off)
SLZB.log("Demo complete")
