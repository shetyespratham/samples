-- Global Variables (Modify for your network)

chnlspresent = "Y"
ipchnlid = ""
ipwkey = ""
iprkey = ""
alrtchnlid = ""
alrtwkey = ""
alrtrkey = ""
recschnlid = ""
recswkey = ""
recsrkey = ""
usrapikey=""
twisid=""
twitkn=""
thttpk=""
twytpn=""
twypn=""
twtwn=""
twywn=""

-- GPIO6-11  spi flash
-- GPIO20,24,28-31  not available
-- GPIO34-39 only input

phapin=34
ldrpin=35
ppmapin=36
rainapin=39

phpin=4         
ppmpin=13	
dspin=14
airpin=16	
fspin=17
mainpin=18	
dhtpin=19
rainpin=21
hx711_clk=22
hx711_dat=23
motpin=25       
solnwpin=26
solnapin=27
solnbpin=32
solncpin=33
touchpin=15
padno=3

coefficient=-0.00004906289863605140

nightoff=0
humidoff=0
fson=0
fsoff=0
airon=0
airoff=0
currtemp=0
currhumid=0
curron=0
curroff=0
motdet=0
mottim=0
daynight=0
nutcap=0

-- touchpad configuration at GPIO15
m = {}
m.pad = {padno}
m._tp = nil
m._padState = 0
m._tmr = nil
m._tmrWait = 50
touchstart = 0
touchend = 0
touchms = 0
lastuntouch = 0

ussid="ShetyesAero"
userpwd="12345678"
syslgn="kailas"
syspwd="shetye"
cfg={}
cfg.ssid=ussid
cfg.pwd=userpwd
cfg.auth=AUTH_WPA2_PSK
cfg.hidden=0
cfg.max=4
cfgip={}
cfg.ip="192.168.101.1"
cfg.netmask="255.255.255.0"
cfg.gateway="192.168.101.1"
cfg.dns="8.8.8.8"
cfgdh={}
cfgdh.start="192.168.101.2"
station_cfg={}
station_cfg.auto=true
station_cfg.save=true
connected="N"
cli_connected="N"
myip=nil

-- functions

wifi.sta.on("got_ip", function(ev, info)
    myip = info.ip
    connected="Y"
end)
wifi.sta.on("disconnected", function(ev, info)
    myip = nil
    connected="N"
end)
wifi.ap.on("sta_connected", function(ev, info)
    cli_connected="Y"
end)
wifi.ap.on("sta_disconnected", function(ev, info)
    cli_connected="N"
end)

function getsensors()
   if file.exists("SystemSensors.mcu") then
      open = file.open or io.open
      fh = open("SystemSensors.mcu", "r")
      filerec=fh:read()
      fh:close()
      tokens=split(filerec.."!", "!")
      if tokens[1] == "true" then
         rainp = "Y"
      else
         rainp = " "
      end
      if tokens[2] == "true" then
         dhtp = "Y"
      else
         dhtp = "Y"
      end
      if tokens[3] == "true" then
         mainp = "Y"
      else
         mainp = " "
      end
      if tokens[4] == "true" then
         fsp = "Y"
      else
         fsp = " "
      end
      if tokens[5] == "true" then
         airp = "Y"
      else
         airp = " "
      end
      if tokens[6] == "true" then
         ldrp = "Y"
      else
         ldrp = " "
      end
      if tokens[7] == "true" then
         hx711p = "Y"
      else
         hx711p = " "
      end
      if tokens[8] == "true" then
         ds18b20p = "Y"
      else
         ds18b20p = " "
      end
      if tokens[9] == "true" then
         nutphp = "Y"
      else
         nutphp = " "
      end
      if tokens[10] == "true" then
         nutppmp = "Y"
      else
         nutppmp = " "
      end
      if tokens[11] == "true" then
         motionp = "Y"
      else
         motionp = " "
      end
   else
      rainp = " "
      dhtp = "Y"
      mainp = " "
      fsp = " "
      airp = " "
      ldrp = " "
      hx711p = " "
      ds18b20p = " "
      nutphp = " "
      nutppmp = " "
      motionp = " "
   end
end
read=function(fn,attr,no)
 local _line
 local open = file.open or io.open
 local fh = open(fn,attr)
 local x = 1
 if fh then
 repeat _line = fh:read()
    if _line then
       x = x + 1
    end
 until _line==nil or x == no+1
 end
 fh:close()
 return _line
end

function split(s, delm)
   result = {};
   for k in s:gmatch("(.-)"..delm) do
       result[#result+1] = k
   end 
   return result;
end

function tare(t)
   sum=hx711_read()
   sum=0
   for i=1,t,1 do
     sum=sum+hx711_read()
   end
   offsetAod=sum/t
   isTare=1
   return offsetAod
end
function getAverageWeight(t)
   nowAodValue=0
   for i=1,t,1 do
       nowAodValue=nowAodValue+hx711_read()
   end
   nowAodValue=nowAodValue/t
   print("newAodValue="..nowAodValue)
   weight=(nowAodValue-offsetAod) * coefficient
   return weight / calibrate  -- -2.55
end
function hx711_read()
  tmr.wdclr()
  gpio.write(hx711_dat, 1)
  gpio.config({gpio=hx711_dat, dir=gpio.IN })
  count=1
  ctr=1
  gpio.write(hx711_clk, 0)

  while(count == 1)
  do
     count = gpio.read(hx711_dat)
     ctr=ctr+1
  end
  tmr.wdclr()
  count = 0
  for i=0, 23 do
     gpio.write(hx711_clk, 1)
     gpio.write(hx711_clk, 0)
     count = count * 2
     ctr=0
     ctr=gpio.read(hx711_dat)
     if ctr==1 then
        count=count+1
     end
  end
  if count > 8388607 then
     count = count - 8388608
  end
  gpio.write(hx711_clk, 1)
  gpio.write(hx711_clk, 0)
  gpio.write(hx711_clk, 1)
  gpio.write(hx711_clk, 0)
  gpio.write(hx711_clk, 1)
  gpio.write(hx711_clk, 0)
  return count
end


function ThingSpeak()
   if file.exists("ThingSpeak.mcu") then
      open = file.open or io.open
      fh = open("ThingSpeak.mcu", "r")
      filerec=fh:read()
      fh:close()
      tokens=split(filerec.."!", "!")
      usrapikey=tokens[1]
      twisid=tokens[2]
      twitkn=tokens[3]
      thttpk=tokens[4]
      twytpn=tokens[5]
      twypn=tokens[6]
      twtwn=tokens[7]
      twywn=tokens[8]
      -- verifycert()
      GetChannels()
      if chnlspresent == "Y" then
         writemyip()
         writestartrecord()
      end
   end
end
function writemyip()
--    http.delete("http://api.thingspeak.com/channels/"..ipchnlid.."/feeds.json?api_key="..usrapikey..","","",function(code, data)
--       if (code < 0) then
--          print("Channel clear failed")
--       else
--          print(code, data)
--          print("Channel cleared")
--       end
--  end)
  http.post("http://api.thingspeak.com/update.json",
    "Content-Type: application/json\r\n",
    '{"api_key":"'..ipwkey..'", "field1" : "'..myip..'" }',
    function(code, data)
    if (code < 0) then
      print("HTTP request failed")
    else
      print(code, data)
      print(myip.." Added to channel")
    end
  end)
end
function writestartrecord()
   http.post("http://api.thingspeak.com/update.json",
       "Content-Type: application/json\r\n",
       '{"api_key":"'..alrtwkey..'", "field1" : "System Started" }',
       function(code, data)
       if (code < 0) then
         print("HTTP request failed")
       else
         print(code, data)
         print("System Started alert added to channel")
       end
   end)
end
function sendSMS(SMSText)
   twytpn1 = string.sub(twytpn,2)
   twypn1 = string.sub(twypn, 2)
   headers = {
     ["Content-Type"] = "application/x-www-form-urlencoded\r\n",
     ["Authorization"] = "Basic "..encoded
   }
   body = "To=%2B"..twypn1.."&From=%2B"..twytpn1.."&Body="..SMSText
   http.post("https://api.twilio.com/2010-04-01/Accounts/"..twisid.."/Messages.json",
           {headers = headers}, body,
           function(code,data)
           if (code < 0) then
              print("Send SMS Failed")
           else
              print(code, data)
              print("SMS sent")
           end
       end)
end
function sendWhatsApp(SMSText)
   twtwn1 = string.sub(twtwn, 2)
   twywn1 = string.sub(twywn, 2)
   headers = {
     ["Content-Type"] = "application/x-www-form-urlencoded\r\n",
     ["Authorization"] = "Basic "..encoded
   }
   body = "To=whatsapp%3A%2B"..twywn1.."&From=whatsapp%3A%2B"..twtwn1.."&Body="..SMSText
   http.post("https://api.twilio.com/2010-04-01/Accounts/"..twisid.."/Messages.json",
           {headers = headers}, body,
           function(code,data)
           if (code < 0) then
              print("Send SMS Failed")
           else
              print(code, data)
              print("SMS sent")
           end
       end)
end
function GetChannels()
    http.get("http://api.thingspeak.com/channels.json?api_key="..usrapikey,  function(code, data)
      if (code < 0) then
        print("HTTP request failed")
      else
        ParseData(data)
--      print(code, data)
        chnlspresent = "Y"
        if ipchnlid == "" then
           CreateChannel("AutoSprayerIP", "IP")
           chnlspresent = "N"
        end
        if alrtchnlid == "" then
           CreateChannel("AutoSprayerAlerts", "Alerts")
           chnlspresent = "N"
        end
        if recschnlid == "" then
           CreateChannel("AutoSprayerRecords", "Records")
           chnlspresent = "N"
        end
        if chnlspresent == "N" then
           http.get("http://api.thingspeak.com/channels.json?api_key="..usrapikey, function(code, data)
              if (code < 0) then
                print("HTTP request failed")
              else
                ParseData(data)
                chnlspresent = "Y"
                if ipchnlid == "" or alrtchnlid == "" or recschnlid == "" then
                   chnlspresent = "N"
                else
                   chnlspresent = "Y"
                end
              end
           end)
        end
      end
    end)
end
function ParseData(data)
    t = sjson.decode(data)
    for k,v in pairs(t) do
        for a,b in pairs(v) do 
            if a == "name" then
               chnlname = b
            end
            if a == "id" then
               chnlid = b
            end
            if a == "api_keys" then
               for d,e in pairs(b) do
                  for f,g in pairs(e) do
                       if f == "api_key" then
                          apikey = g
                       end
                       if f == "write_flag" then
                          writeflag = g
                       end
                  end
                  if writeflag then
                     wapikey = apikey
                  else
                     rapikey = apikey
                  end
               end
            end
        end
        if chnlname == "AutoSprayerIP" then
           ipchnlid = chnlid
           ipwkey = wapikey
           iprkey = rapikey
        end
        if chnlname == "AutoSprayerAlerts" then
           alrtchnlid = chnlid
           alrtwkey = wapikey
           alrtrkey = rapikey
        end
        if chnlname == "AutoSprayerRecords" then
           recschnlid = chnlid
           recswkey = wapikey
           recsrkey = rapikey
        end
        if ipchnlid == "" then
           print("Channel Name ="..chnlname)
           print("Channel ID ="..chnlid)
           print("Write API Key ="..wapikey)
           print("Read API Key = "..rapikey)
           print("================")
        end
    end
end
function CreateChannel(chnlname, fldname)
   http.post("http://api.thingspeak.com/channels.json",
          "Content-Type: application/json\r\n",
          '{"api_key": "'..uapikey..'", "name": "'..chnlname..'", "description": "'..chnlname..'", "field1" : "'..fldname..'" }',
          function(code, data)
      if (code < 0) then
        print("HTTP request failed")
      else
        if code == 200 then
           print(code, data)
        end
      end
   end)
end
function Routers()
   aptimer:unregister()
   print("aptimer unregistered")
   if file.exists("Routers.mcu") then
      open = file.open or io.open
      fh = open("Routers.mcu", "r")
      routers=fh:read()
      fh:close()
      routimer=tmr.create()
      wifi.mode(wifi.STATION)
--    wifi.setphymode(wifi.PHYMODE_N)
      recs=split(routers.."!", "!")
      i=1
      routimer:register(10000, tmr.ALARM_SEMI, function()
         print("inside routimer")
         if (connected == "N") then
            flds=split(recs[i].."|", "|")
            station_cfg.ssid=flds[1]
            station_cfg.pwd=flds[2]
            wifi.sta.config(station_cfg)
            wifi.sta.connect()
            wifi.sta.connect(function(T)
                connected="Y"
                i=#recs
                print("Connected to router using "..flds[1])
                ThingSpeak()
                dofile("aeroponics.lua")
            end)
            if (i < #recs) then
               i=i+1;
               routimer:start();
            end
         end
      end)
      routimer:start()
   else
      dofile("aeroponics.lua")
   end
end

function motcb()
-- value becomes 1 after motions
   gpio.trig(motpin, gpio.INTR_DISABLE)
   motdet=1
   motdetbal=0
   if daynight == 1 then
      sendSMS("Motion%20detected%20in%20night%20time%20before%20"..mottim.."%20minutes")
   end
end

function ldrcb(level, pulse1, eventcnt)
-- value becomes 1 after light goes dark
   gpio.trig(ldrpin, gpio.INTR_DISABLE)
   daynight=gpio.read(ldrpin)
end

function dht_read()
   stats, currtemp, currhumid, temp, humi = dht.read2x(dhtpin)
   if stats ~= dht.OK then
      stats, currtemp, currhumid, temp, humi = dht.read2x(dhtpin)
   end
   if stats ~= dht.OK then
      stats, currtemp, currhumid, temp, humi = dht.read2x(dhtpin)
   end
   if stats == dht.OK then
      for i=1, #temps do
          if currtemp >= tempfrom[i] and currtemp < tempto[i] then
             curron=tempon[i]
             curroff=tempoff[i]
          end
      end
   else
      curron=3
      curroff=600
   end
end

function m.onTouch(pads)
   if m._padState == 0 then
      m._padState = 1
      m._tmr:start()
      touchstart = math.floor(node.uptime()/1000)
      lastuntouch = touchstart - touchend
      print("Touch - untouched for millis: ", lastuntouch)
      local raw = m._tp:read()
      print("kvs")
      for key,value in pairs(raw) do
          print(value)
      end
   else
      m._tmr:stop()
      m._tmr:start()
   end
end
function m.onTmr()
  touchend = math.floor(node.uptime()/1000)
  touchms = touchend - touchstart
  m._padState = 0
  print("Untouch - touched for millis: ", touchms)
  local raw = m._tp:read()
  for key,value in pairs(raw) do
      print(value)
  end
end
function m.init()
  m._tp = touch.create({
    pad = m.pad, --0=gpio4,1=gpio0,2=gpio2,3=gpio15,4=gpio13,5=gpio12,6=gpio14,7=gpio27,8=gpio33,9=gpio32
    cb = m.onTouch,
    intrInitAtStart = false,
    thresTrigger = touch.TOUCH_TRIGGER_BELOW,
    lvolt = touch.TOUCH_LVOLT_0V5,
    hvolt = touch.TOUCH_HVOLT_2V7,
    atten = touch.TOUCH_HVOLT_ATTEN_1V,
    isDebug = false
   })
   m._tmr = tmr.create()
   m._tmr:register(m._tmrWait, tmr.ALARM_SEMI, m.onTmr)
   m.config()
end
function m.config()
   local raw = m._tp:read()
   local thres = raw[padno] - math.floor(raw[padno] * 0.2)
   m._tp:setThres(padno, thres)
   print("Pad is at ", raw[padno], " as baseline")
   print("will trigger at thres: ", thres)
   m._tp:intrEnable()
end

-- actual execution
getsensors() 

if file.exists("Calibrate.mcu") then
   open = file.open or io.open
   fh = open("Calibrate.mcu", "r")
   x=fh:read()
   fh:close()
   calibrate=tonumber(x) -- -2.55
end
if file.exists("TareData.mcu") then
   open = file.open or io.open
   fh = open("TareData.mcu", "r")
   x=fh:read()
   fh:close()
   offsetAod=tonumber(x)
   isTare=1
else
   isTare=0
end

-- setup HX711 GPIO pins
gpio.config( {gpio=hx711_clk, dir=gpio.OUT, pull=gpio.FLOATING}, {gpio=hx711_dat, dir=gpio.IN_OUT, pull=gpio.FLOATING })
-- HX711 pin setup done

-- setup DHT22 GPIO PIN
-- no need to setup
-- end DHT22 setup

-- setup main, failsafe and airpump pins
gpio.config( {gpio={mainpin,fspin,airpin}, dir=gpio.OUT, pull=gpio.PULL_UP })

-- setup ds18b20 temp sensor
ow.setup(dspin)

-- setup rainpin, ldrpin, dspin, motpin
gpio.config({gpio={rainpin,ldrpin,motpin}, dir=gpio.IN, pull=gpio.PULL_UP })
gpio.trig(ldrpin, gpio.INTR_UP_DOWN, ldrcb)
gpio.trig(motpin, gpio.INTR_UP, motcb)

-- setup 

 


if file.exists("Credentials.mcu") then
   open = file.open or io.open
   fh = open("Credentials.mcu", "r")
   ussid=fh:read()
   -- ussid=ussid:gsub("[\n\r]", "")
   if ussid == "" then
      ussid="ShetyesAero"
   end
   userpwd=fh:read()
   -- userpwd=userpwd:gsub("[\n\r]", "")
   if userpwd == "" then
      userpwd="12345678"
   end
   syslgn=fh:read()
   -- syslgn=syslgn:gsub("[\n\r]", "")
   if syslgn == "" then
      syslgn="kailas"
   end
   syspwd=fh:read()
   -- syspwd=syspwd:gsub("[\n\r]", "")
   if syspwd == "" then
      syspwd="shetye"
   end
   fh:close()
end

wifi.mode(wifi.SOFTAP)
-- wifi.setphymode(wifi.PHYMODE_N)

-- Run the main file
if file.exists("CurrentSettings.cfg") then
   open = file.open or io.open
   fh = open("CurrentSettings.cfg", "r")
   filerec=fh:read()
   fh:close()
   recs=split(filerec.."!", "!")
--   rainthre=tonumber(recs[1])
   nightoff=tonumber(recs[1])
   humidoff=tonumber(recs[2])
   flds=split(recs[3].."|", "|")
   fson=tonumber(flds[1])
   fsoff=tonumber(flds[2])
   flds=split(recs[4].."|", "|")
   airon=tonumber(flds[1])
   airoff=tonumber(flds[2])
   nutcap=tonumber(recs[5])

   tempfrom={};
   tempto={};
   tempon={};
   tempoff={};
   temps=split(recs[5].."|","|")
   for i=1, #temps do
      flds=split(temps[i]..",", ",")
      tempfrom[i]=tonumber(flds[1])
      tempto[i]=tonumber(flds[2])
      tempon[i]=tonumber(flds[3])
      tempoff[i]=tonumber(flds[4])
   end
end

m.init()

aptctr=0
aptimer=tmr.create()
aptimer:register(5000, tmr.ALARM_SEMI, function()
       print("Inside AP Timer")
       localTime = time.getlocal()
       lowbits = node.uptime()
       hours = math.floor(lowbits/1000000/60/60)
       mins = math.floor((lowbits - (hours * 1000000*60*60)) /1000000/60)
       secs = math.floor((lowbits - ((hours * 1000000*60*60) + (mins * 1000000 * 60)))/1000000)
--     print(string.format("%04d-%02d-%02d %02d:%02d:%02d DST:%d", localTime["year"], localTime["mon"], localTime["day"], localTime["hour"], localTime["min"], localTime["sec"], localTime["dst"]))
--     print(string.format("%02d:%02d:%02d", hours, mins, secs))

       aptctr = aptctr + 1
       if cli_connected == "Y" then
--        node.setcpufreq(160)
          print("Starting web server")
          dofile("SprayWorld.lua")
       end
       if (aptctr > 6) then
          aptctr=0
          if file.exists("SystemSensors.mcu") and
             file.exists("CurrentSettings.cfg") then
                Routers()
          end
          aptimer:start()
--     else
--        aptimer:start()
       end
end)
tptimer=tmr.create()
tptimer:register(15000, tmr.ALARM_SINGLE, function()
        print("inside tptimer")
        wifi.start()
        wifi.mode(wifi.STATIONAP)
        wifi.ap.config(cfg)
        wifi.ap.setip(cfg)
--      wifi.ap.dhcp.config(cfgdh)
--      wifi.ap.dhcp.start()
        aptimer:start();
end)
tptimer:start();
