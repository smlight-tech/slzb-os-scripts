#META {"start":0}
import FS # import filesystem module
var file = FS.open("/be/test.be") # open file for read

if file # if opened
  SLZB.log("filesize: " .. file.size() .. " bytes")
else
  SLZB.log("file not exists!")
end

file.close() # don't forget to close the file