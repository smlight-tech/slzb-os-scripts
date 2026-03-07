#META {"start":0}
# Send an NEC IR command (e.g. TV power button)
# Ultima devices with IR transmitter only!

# Send power on command
# Change protocol, address, and command to match your device
IR.send(IR.NEC, 0x04, 0x08)

SLZB.log("IR command sent!")
