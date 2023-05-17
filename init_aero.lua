-- Global Variables (Modify for your network)
node.osprint(false)
chnlspresent = "Y"
ipchnlid = ""
ipwkey = ""
iprkey = ""
alrtchnlid = ""
alrtwkey = ""
alrtrkey = ""
recschnlid = ""
hookchnlid = ""
hookwkey = ""
hookrkey = ""
recswkey = ""
recsrkey = ""
usrapikey=""
twisid=""
twitkn=""
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
rainpin=21  -- 0 if wet 1 if dry
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
extip=nil

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
    print("Client connected ")
    cli_connected="Y"
end)
wifi.ap.on("sta_disconnected", function(ev, info)
    print("Client disconnected ")
    cli_connected="N"
end)

function getsensors()
   if file.exists("SystemSensors.mcu") then
      open = file.open or io.open
      fh = open("SystemSensors.mcu", "r")
      filerec=fh:read()
      fh:close()
      tokens=splitr(filerec.."!", "!")
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

function splitr(s, delm)
   result = {};
   for k in s:gmatch("(.-)"..delm) do
       result[#result+1] = k
   end 
   return result;
end
hxsent=0
rainsent=0
taresent=0
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

thng_started = "N"
thng_done = "N"
function ThingSpeak()
   if file.exists("ThingSpeak.mcu") then
      open = file.open or io.open
      fh = open("ThingSpeak.mcu", "r")
      filerec=fh:read()
      fh:close()
      tokens=splitr(filerec.."!", "!")
      usrapikey=tokens[1]
      twisid=tokens[2]
      twitkn=tokens[3]
      twytpn=tokens[4]
      twypn=tokens[5]
      twtwn=tokens[6]
      twywn=tokens[7]
      thng_started = "Y"
   end
end
function getexternalip()
   http.get("https://ifconfig.me/ip",
       function(code, data)
       if (code < 0) then
         print("HTTP request failed")
         extip="Nil"
       else
         extip=data
       end
   end)
end
function sendRecord(SMSText)
   if thng_done == "Y" then
   http.get("https://api.thingspeak.com/update?api_key="..recswkey.."&field1="..SMSText,
       function(code, data)
       if (code < 0) then
         print("HTTP request failed")
       else
         print(code, data)
         print("Record added to channel")
       end
   end)
   end
end
function sendAlert(SMSText)
   if thng_done == "Y" then
   http.get("https://api.thingspeak.com/update?api_key="..alrtwkey.."&field1="..SMSText,
       function(code, data)
       if (code < 0) then
         print("HTTP request failed")
       else
         print(code, data)
         print("alert added to channel")
       end
   end)
   end
end
startwritten="N"
function writestartrecord()
   if thng_done == "Y" then
   http.get("https://api.thingspeak.com/update?api_key="..ipwkey.."&field1="..myip.."!"..extip,
       function(code, data)
       if (code < 0) then
         print("HTTP request failed")
       else
         print(code, data)
         print("IP record added to channel")
         startwritten = "Y"
       end
   end)
   end
end
SMSStack={}
function sendSMS()
   if thng_done == "Y" then
   if file.exists("ThingSpeak.mcu") and connected == "Y" then
      SMSText=SMSStack[table.maxn(SMSStack)] 
      table.remove(SMSStack)
      twytpn1 = string.sub(twytpn,2)
      twypn1 = string.sub(twypn, 2)
      encoded=encoder.toBase64(twisid..":"..twitkn)
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
              table.insert(SMSStack,SMSText)
           else
              print(code, data)
              print("SMS sent")
           end
           tmr.create():alarm(1000, tmr.ALARM_SINGLE, function() sendWhatsApp(SMSText) end)
       end)
   end
   end
end
function sendWhatsApp(SMSText)
   if file.exists("ThingSpeak.mcu") and connected == "Y" then
      twtwn1 = string.sub(twtwn, 2)
      twywn1 = string.sub(twywn, 2)
      encoded=encoder.toBase64(twisid..":"..twitkn)
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
           tmr.create():alarm(1000, tmr.ALARM_SINGLE, function() sendAlert(SMSText) end)
       end)
   end
end
connection_made = "N"
cheaders = {
  Connection = "close",
  ["If-Modified-Since"] = "Sat, 27 Oct 2018 00:00:00 GMT",
}
connection = http.createConnection("https://api.thingspeak.com/channels/4/feeds.json?api_key=F4", http.DELETE, { } )
function make_connection()
   connection = http.createConnection("https://api.thingspeak.com/channels/"..hookchnlid.."/feeds.json?api_key="..usrapikey, http.DELETE, { headers=cheaders } )
   connection:on("complete", function(status)
     print("Request completed with status code =", status)
     if status == 200 then
        connection_made = "Y"
     end
   end)
end

hookcmd="none"
function gethooks()
    hookcmd="none"
    http.get("http://api.thingspeak.com/channels/"..hookchnlid.."/fields/1.json?api_key="..hookwkey.."&results=1", function(code, data)
       if (code < 0) then
          print("Request failed")
       else
          tparse = sjson.decode(data)
          for k,v in pairs(tparse) do
              for a,b in pairs(v) do
                  if a == "field1" then
                     hookcmd = b
                  end
              end
          end
          if connection_made == "Y" then
             connection:request()
          end
       end
    end)
end

got_channels = "N"
function GetChannels()
    got_channels = "N"
    http.get("http://api.thingspeak.com/channels.json?api_key="..usrapikey,  function(code, data)
      if (code < 0) then
        print("HTTP request failed")
      else
        ParseData(data)
        print(code, data)
      end
      got_channels = "Y"
    end)
end
function ParseData(data)
    tparse = sjson.decode(data)
    for k,v in pairs(tparse) do
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
        if chnlname == "AeroSprayerIP" then
           ipchnlid = chnlid
           ipwkey = wapikey
           iprkey = rapikey
        end
        if chnlname == "AeroSprayerAlerts" then
           alrtchnlid = chnlid
           alrtwkey = wapikey
           alrtrkey = rapikey
        end
        if chnlname == "AeroSprayerRecords" then
           recschnlid = chnlid
           recswkey = wapikey
           recsrkey = rapikey
        end
        if chnlname == "AeroWebhook" then
           hookchnlid = chnlid
           hookwkey = wapikey
           hookrkey = rapikey
        end
--      if ipchnlid == "" then
           print("Channel Name ="..chnlname)
           print("Channel ID ="..chnlid)
           print("Write API Key ="..wapikey)
           print("Read API Key = "..rapikey)
           print("================")
--      end
    end
end
ipchnl_created = "N"
alrtchnl_created = "N"
recschnl_created = "N"
hookchnl_created = "N"
chnl_created = "N"
create_free = "Y"
function CreateChannel(chnlname, fldname)
   create_free = "N"
   if chnlname == "AeroSprayerIP" then
      ipchnl_created = "Y"
      ipchnlid = "temp"
   end
   if chnlname == "AeroSprayerAlerts" then
      alrtchnl_created = "Y"
      alrtchnlid = "temp"
   end
   if chnlname == "AeroSprayerRecords" then
      recschnl_created = "Y"
      recschnlid = "temp"
   end
   if chnlname == "AeroWebhook" then
      hookchnl_created = "Y"
      hookchnlid = "temp"
   end
   headers = {
       ["Content-Type"] = "application/x-www-form-urlencoded\r\n"
   }
   body = "api_key="..usrapikey.."&name="..chnlname.."&description="..chnlname.."&field1="..fldname
   print("CreateChannelBody="..body)
   http.post("https://api.thingspeak.com/channels.json",
        {headers = headers}, body,
        function(code, data)
           if (code < 0) then
              print("HTTP request failed")
           else
              print(code, data)
           end
           create_free = "Y"
           chnl_created = "Y"
        end)
end
end_router = "N"
rourecs={}
ri=1
function Routers()
-- aptimer:unregister()
-- print("aptimer unregistered")
   if file.exists("Routers.mcu") then
      open = file.open or io.open
      fh = open("Routers.mcu", "r")
      routers=fh:read()
      fh:close()
      routimer=tmr.create()
--    wifi.mode(wifi.STATION)
--    wifi.setphymode(wifi.PHYMODE_N)
      rourecs=splitr(routers.."!", "!")
--    print("rourecs[1]="..rourecs[1])
      ri=1
      routimer:register(10000, tmr.ALARM_SEMI, function()
--       print("inside routimer")
         if ri > #rourecs then
            ri = 1
         end
         if (connected == "N") then
--          print("ri in routimer="..ri)
--          print("rourecs in routimer="..rourecs[ri])
            rouflds=splitr(rourecs[ri].."|", "|")
            station_cfg.ssid=rouflds[1]
            station_cfg.pwd=rouflds[2]
            wifi.sta.config(station_cfg)
--          wifi.sta.connect()
            wifi.sta.connect(function(T)
--              connected="Y"
                ri=#rourecs
                print("Connected to router using "..rouflds[1])
            end)
            if (ri <= #rourecs) then
               ri=ri+1;
               routimer:start();
            else
               end_router = "Y"
            end
         end
      end)
      routimer:start()
   end
end

motdetbal=0
motsent=0
function motcb()
-- value becomes 1 after motions
   gpio.trig(motpin, gpio.INTR_DISABLE)
   motdet=1
   motdetbal=0
   if daynight == 1 and motsent == 0 and thng_done == "Y" then
      table.insert(SMSStack,"Motion%20detected%20in%20night%20time%20before%20"..mottim.."%20minutes")
      motsent = 1
   end
end

function ldrcb(level, pulse1, eventcnt)
-- value becomes 1 after light goes dark
   gpio.trig(ldrpin, gpio.INTR_DISABLE)
   daynight=gpio.read(ldrpin)
end

dhtstats=0
dhtsent=0
lastdht=0
function dht_readweb()
   if ((node.uptime()/1000000) - 1) > lastdht then
      lastdht=node.uptime()/1000000
      dhtstats, currtemp, currhumid, temp, humi = dht.read2x(dhtpin)
      if dhtstats ~= dht.OK then
         dhtstats, currtemp, currhumid, temp, humi = dht.read2x(dhtpin)
      end
      if dhtstats ~= dht.OK then
         dhtstats, currtemp, currhumid, temp, humi = dht.read2x(dhtpin)
      end
   end
end
function dht_read()
   if ((node.uptime()/1000000) - 1) > lastdht then
      lastdht=node.uptime()/1000000
      dhtstats, currtemp, currhumid, temp, humi = dht.read2x(dhtpin)
      if dhtstats ~= dht.OK then
         dhtstats, currtemp, currhumid, temp, humi = dht.read2x(dhtpin)
      end
      if dhtstats ~= dht.OK then
         dhtstats, currtemp, currhumid, temp, humi = dht.read2x(dhtpin)
      end
   end
   if dhtstats == dht.OK then
--    print("currtemp="..currtemp)
--    print("currhumid="..currhumid)
--    print("temp="..temp)
--    print("humi="..humi)
      for i=1, #tempfrom do
         if currtemp >= tempfrom[i] and currtemp < tempto[i] then
            curron=tempon[i]
            curroff=tempoff[i]
         end
      end
   else
      if dhtsent == 0 then
         if connected == "Y" and thng_done == "Y" then
            table.insert(SMSStack,"Humidity%20and%20Temperature%20Sensor%20did%20not%20read%20data")
            dhtsent = 1
         end
      end
      curron=3
      curroff=600
   end
   if daynight == 1 then
      curroff = curroff + (curroff * nightoff / 100)
   end
   curroff = math.floor(curroff + (curroff * humidoff * ((currhumid - 50) / 10) / 100))
end

function m.onTouch(pads)
   if m._padState == 0 then
      m._padState = 1
      m._tmr:start()
      touchstart = math.floor(node.uptime()/1000)
      lastuntouch = touchstart - touchend
      print("Touch - untouched for millis: ", lastuntouch)
      local raw = m._tp:read()
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
nuttsent=0
function readout(temp)
   if t.sens then
   end
   for addr, temp in pairs(temp) do
--    nutaddr=addr
      nuttemp = temp
   end
end
ssidlist=""
function wifi_scan()
   wifi.sta.scan({ hidden = 1 }, function(err,arr)
      if err then
         print ("Scan failed:", err)
      else
         for i,ap in ipairs(arr) do
             print("i="..i)
             print(ap.ssid)
             if i == 1 then
                ssidlist=ap.ssid
             else
                ssidlist=ssidlist.."!"..ap.ssid
             end
         end
         print("-- Total APs: ", #arr)
       end
   end)
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
t = require("ds18b20")
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

-- wifi.mode(wifi.SOFTAP)
-- wifi.setphymode(wifi.PHYMODE_N)

-- Run the main file
-- 50!30!300|1800!0,25,3,600|25,30,5,600|30,35,6,360|35,40,7,300|40,45,8,240|45,50,10,180|50,60,20,120
if file.exists("CurrentSettings.cfg") then
   open = file.open or io.open
   fh = open("CurrentSettings.cfg", "r")
   filerec=fh:read()
   fh:close()
   recs=splitr(filerec.."!", "!")
   nightoff=tonumber(recs[1])  -- 50
   humidoff=tonumber(recs[2])  -- 30
   fson=tonumber(recs[3]) -- 300
   fsoff=tonumber(recs[4]) -- 1800
   airon=tonumber(recs[5]) -- 1800
   airoff=tonumber(recs[6]) -- 600

   tempfrom={};
   tempto={};
   tempon={};
   tempoff={};
   temprecs=splitr(recs[7].."|","|")
   for i=1, #temprecs do
      flds=splitr(temprecs[i]..",", ",")
      tempfrom[i]=tonumber(flds[1])
      tempto[i]=tonumber(flds[2])
      tempon[i]=tonumber(flds[3])
      tempoff[i]=tonumber(flds[4])
   end
end

m.init()

aptctr=0
rou_started="N"
web_started="N"
aero_started="N"
sysstartedsent="N"
aptimer=tmr.create()
aptimer:register(5000, tmr.ALARM_SEMI, function()
--     print("Inside AP Timer")
       tptimer:unregister()
       if table.maxn(SMSStack) > 0 then
          sendSMS()
       end
       localTime = time.getlocal()
       lowbits = node.uptime()
       hours = math.floor(lowbits/1000000/60/60)
       mins = math.floor((lowbits - (hours * 1000000*60*60)) /1000000/60)
       secs = math.floor((lowbits - ((hours * 1000000*60*60) + (mins * 1000000 * 60)))/1000000)
--     print(string.format("%04d-%02d-%02d %02d:%02d:%02d DST:%d", localTime["year"], localTime["mon"], localTime["day"], localTime["hour"], localTime["min"], localTime["sec"], localTime["dst"]))
--     print(string.format("%02d:%02d:%02d", hours, mins, secs))

       aptctr = aptctr + 1
--     if cli_connected == "N" and
       if rou_started == "N" and
          file.exists("SystemSensors.mcu") and
          file.exists("CurrentSettings.cfg") then
             rou_started = "Y"
             Routers()
       end
       if connected == "Y" and thng_started == "N" then
             getexternalip()
             ThingSpeak()
       end
       if thng_started == "Y" and got_channels == "N" then
             GetChannels()
       end
       if thng_done == "Y" and startwritten == "N" then
          writestartrecord()
       end
       if thng_done == "Y" and startwritten == "Y" and connection_made == "N" then
          make_connection()
       end
       if hookcmd == "restart" then
          node.restart()
       end
       if hookcmd == "getip" then
          writestartrecord()
          hookcmd = "none"
       end
       if hookcmd == "startweb" then
          hookcmd = "none"
          if web_started ~= "Y" then
             web_started = "Y"
             print("Starting web server")
             dofile("SprayWorld.lua")
          end
       end
       if chnl_created == "Y" then
          got_channels = "N"
          chnl_created = "N"
          GetChannels()
       end
       if got_channels == "Y" then
          if ipchnlid == "" and create_free == "Y" then
             ipchnl_created = "N"
             CreateChannel("AeroSprayerIP", "IP")
          end
       end
       if got_channels == "Y" and create_free == "Y" then
          if alrtchnlid == "" and ipchnl_created == "Y" then
             alrtchnl_created = "N"
             CreateChannel("AeroSprayerAlerts", "Alerts")
          end
       end
       if got_channels == "Y" and create_free == "Y" then
          if recschnlid == "" and alrtchnl_created == "Y" then
             recschnl_created = "N"
             CreateChannel("AeroSprayerRecords", "Records")
          end
       end
       if got_channels == "Y" and create_free == "Y" then
          if hookchnlid == "" and recschnl_created == "Y" then
             hookchnl_created = "N"
             CreateChannel("AeroWebhook", "Webhooks")
          end
       end
       if ipchnlid ~= "" and alrtchnlid ~= "" and recschnlid ~= "" and ipchnlid ~= "temp" and alrtchnlid ~= "temp" and recschnlid ~= "temp" and hookchnlid ~= "temp" then
          thng_done = "Y"
          got_channels = "Y"
       end
       if cli_connected == "Y" and
          web_started == "N" then
--        node.setcpufreq(160)
          web_started = "Y"
          print("Starting web server")
          dofile("SprayWorld.lua")
       end
       if connected == "Y" and sysstartedsent == "N" and thng_done == "Y" then
          table.insert(SMSStack,"System%20Started")
          sysstartedsent = "Y"
       end
       aptimer:start()
end)
tptimer=tmr.create()
tpctr=0
tptimer:register(2000, tmr.ALARM_AUTO, function()
        if tpctr == 0 then
           print("inside tptimer")
           wifi.start()
           wifi.mode(wifi.STATIONAP)
        end
        if tpctr == 4 then
           wifi_scan()
        end
        if tpctr == 6 and aero_started == "N" then
           aero_started = "Y"
           dofile("aeroponics.lua")
        end
        if tpctr == 8 then
           wifi.ap.config(cfg)
           wifi.ap.setip(cfg)
        end
        if tpctr > 9 then
           aptimer:start();
        end
        tpctr = tpctr + 1
        if tpctr < 10 then
           tptimer:start();
        end
end)
tptimer:start();
