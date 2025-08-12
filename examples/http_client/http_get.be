#META {"start":0}
#insert your code below
import HTTP
import json

# req url: https://formatjsononline.com/api/users/usr_1
# method: get
# we expect a response of no more than 1024 characters
if (HTTP.open("https://formatjsononline.com/api/users/usr_1", "get", 1024))
  var code = HTTP.perform() # make req and get response code and text
  
  if (code == 200)
    # SLZB.log("response text: " .. HTTP.getResponse()) # !warning! You cannot log a response longer than 1024 characters! Otherwise it will crash!
    
    var user = json.load(HTTP.getResponse()) # parse respose json
    SLZB.log("email: " .. user["data"]["email"] .. ", name: " .. user["data"]["firstName"]) # and log data

  else
    SLZB.log("req failed! code: " .. code)
  end

  HTTP.close() # dont forget to free client

else
  SLZB.log("failed to open http client!")
end