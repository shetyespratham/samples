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

function getsensors()
   if file.exists("SystemSensors.mcu")
      open = file.open or io.open
      fh = open("Routers.mcu", "r")
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
         dhtp = " "
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
      dhtp = " "
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
      filerec=read("ThingSpeak.mcu","r",1)
      tokens=split(filerec.."!", "!")
      usrapikey=tokens[1]
      twisid=tokens[2]
      twitkn=tokens[3]
      thttpk=tokens[4]
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
    http.post("https://api.thingspeak.com/apps/thinghttp/send_request?api_key="..thttpk.."&message="..SMSText,
        "Content-Type: application/x-www-form-urlencoded\r\n",
        "",
        function(code,data)
        if (code < 0) then
           print("Send SMS Failed")
        else
           print(code, data)
           print("SMS sent"..SMSText)
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
   
 
if file.exists("Routers.mcu") then
   rourecs=splitr(routers.."!", "!")
end
function Routers()
   aptimer:unregister()
   if file.exists("Routers.mcu") then
      open = file.open or io.open
      fh = open("Routers.mcu", "r")
      routers=fh:read()
      fh:close()
      routimer=tmr.create()
      wifi.setmode(wifi.STATION)
      wifi.setphymode(wifi.PHYMODE_N)
      recs=split(routers.."!", "!")
      i=1
      routimer:register(10000, tmr.ALARM_SEMI, function()
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
                dofile("aeroponics.lc")
            end)
            if (i < #recs) then
               i=i+1;
               routimer:start();
            end
         end
      end)
      routimer:start()
   end
end

ussid="ShetyesAero"
userpwd="12345678"
syslgn="kailas"
syspwd="shetye"
function motcb()
-- value becomes 1 after motions
   gpio.trig(motpin, gpio.INTR_DISABLE)
   motdet=1
end

function ldrcb(level, pulse1, eventcnt)
-- value becomes 1 after light goes dark
   gpio.trig(ldrpin, gpio.INTR_DISABLE)
   ldrdet=gpio.read(ldrpin)
end

kailasshetye
if file.exists("Credentials.mcu") then
   ussid=readline("Credentials.mcu","r",1)
   ussid=ussid:gsub("[\n\r]", "")
   if ussid == "" then
      ussid="ShetyesAero"
   end
   userpwd=readline("Credentials.mcu","r",2)
   userpwd=userpwd:gsub("[\n\r]", "")
   if userpwd == "" then
      userpwd="12345678"
   end
   syslgn=readline("Credentials.mcu","r",3)
   syslgn=syslgn:gsub("[\n\r]", "")
   if syslgn == "" then
      syslgn="kailas"
   end
   syspwd=readline("Credentials.mcu","r",4)
   syspwd=syspwd:gsub("[\n\r]", "")
   if syspwd == "" then
      syspwd="shetye"
   end
end
wifi.setmode(wifi.SOFTAP)
wifi.setphymode(wifi.PHYMODE_N)
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

ussid="ShetyesAero"
userpwd="12345678"
connected="N"
myip=nil

wifi.sta.on("got_ip", function(ev, info)
    myip = info.ip
    connected="Y"
end)
wifi.sta.on("disconnected", function(ev, info)
    myip = nil
    connected="N"
end)

kailasshetye - move from here
wifi.sta.scan({ hidden = 1 }, function(err,arr)
  if err then
    print ("Scan failed:", err)
  else
    for i,ap in ipairs(arr) do
      print(ap.ssid.."kvs")
    end
    print("-- Total APs: ", #arr)
  end
end)
kailasshetye - move upto here

-- Run the main file
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
ldrdet=0
mottim=0
daynight=0
nutcap=0
if file.exists("CurrentSettings.cfg") then
   filerec=read("CurrentSettings.cfg","r",1)
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

function m.onTouch(pads)
   if m._padState == 0 then
      m._padState = 1
      m._tmr:start()
      touchstart = math.floor(node.uptime()/1000))
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
  touchend = math.floor(node.uptime()/1000))
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
m.init()

aptctr=0
aptimer=tmr.create()
aptimer:register(5000, tmr.ALARM_SEMI, function()
       localTime = time.getlocal()
       lowbits = node.uptime()
       hours = math.floor(lowbits/1000000/60/60)
       mins = math.floor((lowbits - (hours * 1000000*60*60)) /1000000/60)
       secs = math.floor((lowbits - ((hours * 1000000*60*60) + (mins * 1000000 * 60)))/1000000)
       print(string.format("%04d-%02d-%02d %02d:%02d:%02d DST:%d", localTime["year"], localTime["mon"], localTime["day"], localTime["hour"], localTime["min"], localTime["sec"], localTime["dst"]))
       print(string.format("%02d:%02d:%02d", hours, mins, secs))

       aptctr = aptctr + 1
       table=wifi.ap.getclient()
       ccnt = 0
       for mac,ip in pairs(table) do
           ccnt = ccnt + 1
       end
       if ccnt > 0 then
          node.setcpufreq(160)
          print("Starting web server")
          dofile("SprayWorld.lc")
       end
       if (aptctr > 6) then
          aptctr=0
          Routers()
       else
          aptimer:start()
       end
end)
tptimer=tmr.create()
tptimer:register(15000, tmr.ALARM_SINGLE, function()
        wifi.start()
        wifi.mode(wifi.STATIONAP)
        wifi.ap.config(cfg)
        wifi.ap.setip(cfg)
--      wifi.ap.dhcp.config(cfgdh)
--      wifi.ap.dhcp.start()
        aptimer:start();
end)
tptimer:start();
