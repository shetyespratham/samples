
-- Start a simple http server
-- aptimer:unregister()
loggedin="no"
sendingidx=0
function split(s)
   result = {};
   s = s:match(".-?(.*).- HTTP") .. "&"
   for k,v in s:gmatch("(.-)=(.-)&") do
       result[k]=v
   end
   return result;
end
--function splitr(s, delm)
--   result = {};
--   for k in s:gmatch("(.-)"..delm) do
--       result[#result+1] = k
--   end
--   return result;
--end
function nextChunk(c, filetype)
    open = file.open or io.open    
    f = open(f2opn, "r")
    f:seek("set", i)
    abcd = f:read(1024)
    if not abcd then
       c:close()
       sendingidx=0
       collectgarbage()
       return
    end
    if i == 0 then
       if filetype == "gz" then
          c:send("HTTP\/1.1 200 \r\nContent-Type: text\/html\r\nContent-Encoding: gzip\r\n\r\n" .. abcd)
       end
       if filetype == "jpg" then
           c:send("HTTP\/1.1 200 \r\nContent-Type: image\/jpeg\r\n\r\n" .. abcd)
       end
       if filetype == "ico" then
           c:send("HTTP\/1.1 200 \r\nContent-Type: image\/x-icon\r\n\r\n" .. abcd)
       end
       if filetype == "text" then
           c:send("HTTP\/1.1 200 OK\r\nAccess-Control-Allow-Origin: *\r\nContent-Type: text\/html\r\n\r\n"..abcd)
       end
    else
       c:send(abcd)
    end
    i = i + 1024
    f:close()
    collectgarbage()
end

function tostringhms(a)
   hours = math.floor(a/1000000/60/60)
   mins = math.floor((a - (hours * 1000000*60*60)) /1000000/60)
   secs = math.floor((a - ((hours * 1000000*60*60) + (mins * 1000000 * 60)))/1000000)
   print(string.format("%02d:%02d:%02d", hours, mins, secs))
   print(tostring(hours)..":"..(mins)..":"..(secs))
   return (tostring(hours)..":"..tostring(mins)..":"..tostring(secs))
end  
ssidlist1=""
function wifi_scan()
   ssidlist=""
   wifi.sta.scan({ hidden = 1 }, function(err,arr)
      if err then
         print ("Scan failed:", err)
      else
         for i,ap in ipairs(arr) do
             print("i="..i)
             print(ap.ssid.."kvs")
             if i == 1 then
                ssidlist=ap.ssid
             else
                ssidlist=ssidlist.."!"..ap.ssid
             end
         end
         print("-- Total APs: ", #arr)
         ssidlist1=ssidlist
       end
   end)
end

print("Starting Web Server from inside SprayWorld.lc")
srv=net.createServer(net.TCP, 2)
srv:listen(80,function(conn)
  conn:on("receive",function(conn,payload)
     if string.find(payload, "GET \/ ") then
        print("KVS Payload \/:"..payload)
        i=0
        sendingidx=1
        f2opn = "ShetyesSprayer.html.gz"
        nextChunk(conn, "gz")
     end
--     if string.find(payload, "GET \/Pratham.jpg") then
--        print("KVS Payload \/Pratham.jpg:"..payload)
--        i=0
--        sendingidx=1
--        f2opn = "Pratham.jpg"
--        nextChunk(conn, "jpg")
--     end
     if string.find(payload, "GET \/failsafe.jpg") then
        print("KVS Payload \/failsafe.jpg:"..payload)
        i=0
        sendingidx=1
        f2opn = "failsafe.jpg"
        nextChunk(conn, "jpg")
     end
--     if string.find(payload, "GET \/favicon.ico") then
--        print("KVS Payload \/favicon.ico:"..payload)
--        i=0
--        sendingidx=1
--        f2opn = "favicon.ico"
--        nextChunk(conn, "ico")
--     end
     if string.find(payload, "GET \/chkcred") then
          print(payload)
          fndt=split(payload)
          print(fndt.user)
          print(fndt.pass)
           if fndt.user == syslgn and fndt.pass == syspwd then
                 conn:send("HTTP\/1.1 200 OK\r\nAccess-Control-Allow-Origin: *\r\nContent-Type: text\/html\r\n\r\nyes")
                 loggedin="yes"
           else
              conn:send("HTTP\/1.1 200 OK\r\nAccess-Control-Allow-Origin: *\r\nContent-Type: text\/html\r\n\r\nno")
              loggedin="no"
           end
     end
     if loggedin == "yes" then
        if string.find(payload,"GET \/getssidlist") then
           print("going for scan")
           wifi_scan()
           if ssidlist1 ~= nil then
              conn:send("HTTP\/1.1 200 OK\r\nAccess-Control-Allow-Origin: *\r\nContent-Type: text\/html\r\n\r\n"..ssidlist1)
           else
              conn:send("HTTP\/1.1 200 OK\r\nAccess-Control-Allow-Origin: *\r\nContent-Type: text\/html\r\n\r\n")
           end
        end     
        if string.find(payload,"GET \/restart") then
           srv:close()
           node.restart()
        end
        if string.find(payload, "GET \/areyouthere") then
           print("Request received through router:"..payload)
           if myip then
              conn:send("HTTP\/1.1 200 OK\r\nAccess-Control-Allow-Origin: *\r\nContent-Type: text\/html\r\n\r\n"..myip)
           else
              conn:send("HTTP\/1.1 200 OK\r\nAccess-Control-Allow-Origin: *\r\nContent-Type: text\/html\r\n\r\n")
           end
        end
        if string.find(payload, "GET \/netsave") then
           print("netsave Request received")
           fndt=split(payload)
           open = file.open or io.open
           fh = open("Credentials.mcu", "w")
           fh:write(fndt.ssid.."!"..fndt.wpass.."!"..fndt.syslgn.."!"..fndt.syspwd)
           fh:flush()
           fh:close()
           conn:send("HTTP\/1.1 200 OK\r\nAccess-Control-Allow-Origin: *\r\nContent-Type: text\/html\r\n\r\nyes")
        end
        if string.find(payload, "GET \/saverourec") then
           print("saverourec Request received:"..payload)
           fndt=split(payload)
           if file.exists("Routers.mcu") then
              open = file.open or io.open
              fh = open("Routers.mcu", "r")
              routers=fh:read()
              fh:close()
              routers1=""
              match="N"
              recs=splitr(routers.."!", "!")
              for i=1, #recs do
                  flds=splitr(recs[i].."|", "|")
                  if (flds[1] == fndt.roussid) then
                      flds[2] = fndt.roupwd
                      match = "Y"
                      i = #recs
                  end
                  if (i < #recs) then
                     routers1=routers1..flds[1].."|"..flds[2].."!"
                  else
                     routers1=routers1..flds[1].."|"..flds[2]
                  end
              end
              if (match == "N") then
                 routers1=routers1.."!"..fndt.roussid.."|"..fndt.roupwd
              end
           else
              routers1=fndt.roussid.."|"..fndt.roupwd
           end
           open = file.open or io.open
           fh = open("Routers.mcu", "w+")
           fh:write(routers1)
           fh:flush()
           fh:close()
           conn:send("Http\/1.0 200 OK\r\nAccess-Control-Allow-Origin: *\r\nContent-Type: text\/html\r\n\r\nRecord saved")
        end
        if string.find(payload, "GET \/loadfile") then
           print("loadfile Request received:"..payload)
           fndt=split(payload)
           if file.exists(fndt.file2load) then
              open = file.open or io.open
              fh = open(fndt.file2load, "r")
              loadedrec=fh:read()
              fh:close()
              conn:send("Http\/1.0 200 OK\r\nAccess-Control-Allow-Origin: *\r\nContent-Type: text\/html\r\n\r\n"..loadedrec)
           else           
              conn:send("Http\/1.0 200 OK\r\nAccess-Control-Allow-Origin: *\r\nContent-Type: text\/html\r\n\r\nnot found")
           end
        end        
        if string.find(payload, "GET \/savefile") then
           print("savefile Request received:"..payload)
           fndt=split(payload)
           open = file.open or io.open
           fh = open(fndt.save2file, "w")
           fh:write(fndt.data)
           fh:flush()
           fh:close()
           conn:send("Http\/1.0 200 OK\r\nAccess-Control-Allow-Origin: *\r\nContent-Type: text\/html\r\n\r\nsaved")
        end        
        if string.find(payload, "GET \/thngload") then
           print("thing loadfile Request received:"..payload)
           fndt=split(payload)
           if file.exists("ThingSpeak.mcu") then
              open = file.open or io.open
              fh = open("ThingSpeak.mcu", "r")
              loadedrec=fh:read()
              fh:close()
              conn:send("Http\/1.0 200 OK\r\nAccess-Control-Allow-Origin: *\r\nContent-Type: text\/html\r\n\r\n"..loadedrec)
           else           
              conn:send("Http\/1.0 200 OK\r\nAccess-Control-Allow-Origin: *\r\nContent-Type: text\/html\r\n\r\nnot found")
           end
        end        
        if string.find(payload, "GET \/thngsave") then
           print("thing savefile Request received:"..payload)
           fndt=split(payload)
           open = file.open or io.open
           fh = open("ThingSpeak.mcu", "w")
           fh:write(fndt.thnguapi.."!"..fndt.twisid.."!"..fndt.twitkn.."!"..fndt.thnghttp.."!"..fndt.twytpn.."!"..fndt.twypn.."!"..fndt.twtwn.."!"..fndt.twywn)
           fh:flush()
           fh:close()
           conn:send("Http\/1.0 200 OK\r\nAccess-Control-Allow-Origin: *\r\nContent-Type: text\/html\r\n\r\nsaved")
        end        
        if string.find(payload,"GET \/stare") then
           if hx711p == "Y" then
              tare(10)
              open = file.open or io.open
              fh = open("TareData.mcu", "w")
              fh:write(tostring(offsetAod))
              fh:flush()
              fh:close()
              conn:send("Http\/1.0 200 OK\r\nAccess-Control-Allow-Origin: *\r\nContent-Type: text\/html\r\n\r\nsaved")
           end
        end
        if string.find(payload,"GET \/calibrate") then
           if hx711p == "Y" then
              fndt=split(payload)
              open = file.open or io.open
              fh = open("Calibration.mcu", "w")
              fh:write(fndt.caldata)
              fh:flush()
              fh:close()
              conn:send("Http\/1.0 200 OK\r\nAccess-Control-Allow-Origin: *\r\nContent-Type: text\/html\r\n\r\nsaved")
           end
        end
        if string.find(payload,"GET \/savesensors") then
           fndt=split(payload)
           open = file.open or io.open
           fh = open("SystemSensors.mcu", "w")
           fh:write(fndt.data)
           fh:flush()
           fh:close()
           getsensors()  --kailasshetye  read sensors from SystemSensors.mcu and update fields
           conn:send("Http\/1.0 200 OK\r\nAccess-Control-Allow-Origin: *\r\nContent-Type: text\/html\r\n\r\nsaved")
        end
        if string.find(payload,"GET /sfunction") then
           sendstr=tostring
           if rainp == "Y" then
              if (gpio.read(rainpin)) == 1 then
                 sendstr="Dry"
              else
                 sendstr="Wet"
              end
           else
              sendstr="Abs"
           end
           if dhtp == "Y" then
              stats, currtemp, currhumid, temp, humi = dht.read(dhtpin)
              if stats ~= dht.OK then
                 stats, currtemp, currhumid, temp, humi = dht.read(dhtpin)
              end
              if stats ~= dht.OK then
                 stats, currtemp, currhumid, temp, humi = dht.read(dhtpin)
              end
              if stats == dht.OK then
                 sendstr=sendstr.."!"..tostring(currtemp)
                 sendstr=sendstr.."!"..tostring(currhumid)
                 for i=1, #temps do
                     if currtemp >= tempfrom[i] and currtemp < tempto[i] then
                        sendstr=sendstr.."!"..tostring(tempon[i])
                        sendstr=sendstr.."!"..tostring(tempoff[i])
                     end
                 end
              else
                 sendstr=sendstr.."!Failed!Failed"
              end
           else
              sendstr=sendstr.."!Abs!Abs"
           end 
           if mainp == "Y" then
              sendstr=sendstr.."!"..tostring(curron)
              sendstr=sendstr.."!"..tostring(curronb)
              sendstr=sendstr.."!"..tostring(curroff)
              sendstr=sendstr.."!"..tostring(curroffb)
           else
              sendstr=sendstr.."!Abs!Abs!Abs!Abs"
           end 
           if fsp == "Y" then
              sendstr=sendstr.."!"..tostring(fson)
              sendstr=sendstr.."!"..tostring(fsonb)
              sendstr=sendstr.."!"..tostring(fsoff)
              sendstr=sendstr.."!"..tostring(fsoffb)
           else
              sendstr=sendstr.."!Abs!Abs!Abs!Abs"
           end 
           if airp == "Y" then
              sendstr=sendstr.."!"..tostring(airon)
              sendstr=sendstr.."!"..tostring(aironb)
              sendstr=sendstr.."!"..tostring(airoff)
              sendstr=sendstr.."!"..tostring(airoffb)
           else
              sendstr=sendstr.."!Abs!Abs!Abs!Abs"
           end 
           if ldrp == "Y" then
              sendstr=sendstr.."!"..tostring(daynight)
           else
              sendstr=sendstr.."!Abs"
           end 
           if hx711p == "Y" then
              sendstr=sendstr.."!"..tostring(weight)
           else
              sendstr=sendstr.."!Abs"
           end 
           if ds18b20p == "Y" then
              sendstr=sendstr.."!"..tostring(nuttemp)
           else
              sendstr=sendstr.."!Abs"
           end 
           if nutphp == "Y" then
              sendstr=sendstr.."!"..tostring(nutph)
           else
              sendstr=sendstr.."!Abs"
           end 
           if nutppmp == "Y" then
              sendstr=sendstr.."!"..tostring(nutppm)
           else
              sendstr=sendstr.."!Abs"
           end 
           if motionp == "Y" then
              if (gpio.read(motpin)) == 1 then
                 sendstr=sendstr.."!Yes"
                 motdet="Yes"
              else
                 sendstr=sendstr.."!No"
                 motdet="No"
              end
              sendstr=sendstr.."!"..tostring(motdetb)
           else
              sendstr=sendstr.."!Abs!Abs"
           end 
           print(sendstr)
           conn:send("Http/1.0 200 OK\r\nAccess-Control-Allow-Origin: *\r\nContent-Type: text/html\r\n\r\n"..sendstr)
        end 
     end
  end)
  if sendingidx == 1 then
     conn:on("sent",nextChunk)
  else
     conn:on("sent", function(conn) conn:close() end)
  end
end)
