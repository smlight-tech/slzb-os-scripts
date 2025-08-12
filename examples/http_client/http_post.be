#META {"start":0}
#insert your code below
import HTTP
import json

# req url: https://echo.free.beeceptor.com/sample-request
# method: post
# we expect a response of no more than 1024 characters
if (HTTP.open("https://echo.free.beeceptor.com/sample-request", "post", 1024)) # init http client. HTTP.start(2048) - set response text buffer size to 2048
  var pd = {"test": "val"} # prepare post data
  
  HTTP.setPostData(json.dump(pd)) # convert data to json
  HTTP.setHeader("Content-Type", "application/json") # tell server that we sending json

  var code = HTTP.perform() # make req
  
  if (code == 200)
    SLZB.log("response text: " .. HTTP.getResponse()) # !warning! You cannot log a response longer than 1024 characters! Otherwise it will crash!

  else
    SLZB.log("req failed! code: " .. code)
  end

  HTTP.close() # dont forget to stop client

else
  SLZB.log("http client open failed!")
end