import ZB # import zb module
var lastSocketClients = 0 # variable to remember the number of connected clients

#An infinite loop is needed to keep the script running forever.
#If execution reaches the end of the file, the script will terminate.
while true
  var curClients = ZB.getZbClients() # store current clients

  if curClients == 0 && lastSocketClients > 0 # if there are no current clients and there were in the last cycle, it means that the clients has disconnected
    SLZB.log("socket client dissconnected!" ) # log some text
    ZB.reboot() # reboot zigbee chip
  end

  lastSocketClients = curClients # store current clients
  SLZB.delay(500); # sleep for 500ms
end