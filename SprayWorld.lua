
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
function hms(a)
   hours = math.floor(a/60/60)
   mins = math.floor((a - (hours * 60 * 60)) /60)
   secs = math.floor(a - ((hours * 60 * 60) + (mins * 60)))
   return (string.format("%02d:%02d:%02d", hours, mins, secs))
end
print("Starting Web Server from inside SprayWorld.lc")
srv=net.createServer(net.TCP, 2)
srv:listen(80,function(conn)
  conn:on("receive",function(conn,payload)
     if string.find(payload, "GET \/ ") then
        i=0
        sendingidx=1
        f2opn = "ShetyesSprayer.html.gz"
        nextChunk(conn, "gz")
     end
--     if string.find(payload, "GET \/Pratham.jpg") then
--        i=0
--        sendingidx=1
--        f2opn = "Pratham.jpg"
--        nextChunk(conn, "jpg")
--     end
     if string.find(payload, "GET \/failsafe.jpg") then
        i=0
        sendingidx=1
        f2opn = "failsafe.jpg"
        nextChunk(conn, "jpg")
     end
--     if string.find(payload, "GET \/favicon.ico") then
--        i=0
--        sendingidx=1
--        f2opn = "favicon.ico"
--        nextChunk(conn, "ico")
--     end
     if string.find(payload, "GET \/chkcred") then
          fndt=split(payload)
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
           if ssidlist ~= nil then
              conn:send("HTTP\/1.1 200 OK\r\nAccess-Control-Allow-Origin: *\r\nContent-Type: text\/html\r\n\r\n"..ssidlist)
           else
              conn:send("HTTP\/1.1 200 OK\r\nAccess-Control-Allow-Origin: *\r\nContent-Type: text\/html\r\n\r\n")
           end
        end     
        if string.find(payload,"GET \/restart") then
           srv:close()
           node.restart()
        end
        if string.find(payload, "GET \/areyouthere") then
           if myip then
              conn:send("HTTP\/1.1 200 OK\r\nAccess-Control-Allow-Origin: *\r\nContent-Type: text\/html\r\n\r\n"..myip)
           else
              conn:send("HTTP\/1.1 200 OK\r\nAccess-Control-Allow-Origin: *\r\nContent-Type: text\/html\r\n\r\n")
           end
        end
        if string.find(payload, "GET \/netsave") then
           fndt=split(payload)
           open = file.open or io.open
           fh = open("Credentials.mcu", "w")
           fh:write(fndt.ssid.."!"..fndt.wpass.."!"..fndt.syslgn.."!"..fndt.syspwd)
           fh:flush()
           fh:close()
           conn:send("HTTP\/1.1 200 OK\r\nAccess-Control-Allow-Origin: *\r\nContent-Type: text\/html\r\n\r\nyes")
        end
        if string.find(payload, "GET \/saverourec") then
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
           fndt=split(payload)
           open = file.open or io.open
           fh = open(fndt.save2file, "w")
           fh:write(fndt.data)
           fh:flush()
           fh:close()
           conn:send("Http\/1.0 200 OK\r\nAccess-Control-Allow-Origin: *\r\nContent-Type: text\/html\r\n\r\nsaved")
        end        
        if string.find(payload, "GET \/thngload") then
--         fndt=split(payload)
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
           if rainp == "Y" then
              if (gpio.read(rainpin)) == 1 then
                 sendstr="Dry"
              else
                 sendstr="Wet"
              end
           else
              sendstr="Abs"
           end
           dht_readweb()
--         if ds18b20p == "Y" then
--            t:read_temp(readout, dspin, t.C)
--         end
           if dhtstats == dht.OK then
              sendstr=sendstr.."!"..tostring(currtemp)
              sendstr=sendstr.."!"..tostring(currhumid)
           else
              sendstr=sendstr.."!Failed!Failed"
           end
           if mainp == "Y" then
              sendstr=sendstr.."!"..tostring(curron)
              if mainstat == 0 then
                 sendstr=sendstr.."!"..hms(mainonbal)
              else
                 sendstr=sendstr.."!".."now ON"
              end
              sendstr=sendstr.."!"..tostring(curroff)
              if mainstat == 1 then
                 sendstr=sendstr.."!"..hms(mainoffbal)
              else
                 sendstr=sendstr.."!".."now OFF"
              end
           else
              sendstr=sendstr.."!Abs!Abs!Abs!Abs"
           end 
           if fsp == "Y" then
              sendstr=sendstr.."!"..tostring(fson)
              if fsstat == 0 then
                 sendstr=sendstr.."!"..hms(fsonbal)
              else
                 sendstr=sendstr.."!".."now ON"
              end
              sendstr=sendstr.."!"..tostring(fsoff)
              if fsstat == 1 then
                 sendstr=sendstr.."!"..hms(fsoffbal)
              else
                 sendstr=sendstr.."!".."now OFF"
              end
           else
              sendstr=sendstr.."!Abs!Abs!Abs!Abs"
           end 
           if airp == "Y" then
              sendstr=sendstr.."!"..tostring(airon)
              if airstat == 0 then
                 sendstr=sendstr.."!"..hms(aironbal)
              else
                 sendstr=sendstr.."!".."now ON"
              end
              sendstr=sendstr.."!"..tostring(airoff)
              if airstat == 1 then
                 sendstr=sendstr.."!"..hms(airoffbal)
              else
                 sendstr=sendstr.."!".."now OFF"
              end
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
--            t:read_temp(readout, dspin, t.C)
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
              sendstr=sendstr.."!"..tostring(motdetbal)
           else
              sendstr=sendstr.."!Abs!Abs"
           end 
           conn:send("Http\/1.0 200 OK\r\nAccess-Control-Allow-Origin: *\r\nContent-Type: text\/html\r\n\r\n"..sendstr)
        end 
     end
  end)
  if sendingidx == 1 then
     conn:on("sent",nextChunk)
  else
     conn:on("sent", function(conn) conn:close() end)
  end
end)
