print("inside aeroponics.lua")
routimer:unregister()
print("router timer unregistered")
mainstat=1
mainonbal=0
mainoffbal=10000
fsstat=1
fsonbal=0
fsoffbal=10000
airstat=1
aironbal=0
airoffbal=10000

onofftimer = tmr.create()
onofftimer:register((1000), tmr.ALARM_AUTO, function()
   motdetbal = motdetbal + 1
   if mainstat == 1 and mainonbal == 0 then
      dhr_read()
      if stats == dht.OK then
         for i=1, #temps do
             if currtemp >= tempfrom[i] and currtemp < tempto[i] then
                curron=tempon[i]
                curroff=tempoff[i]
                if stats == dht.OK then
                   if currhumid > 50 then
                      curroff = curroff * ((currhumid-50) / 1000 * humidoff)
                   else
                      curroff = curroff / ((50-currhumid) / 1000 * humidoff)
                   end
                end
             end
         end
      else
         if connected == "Y" then
            sendSMS("Humidity%20and%20Temperature%20Sensor%20did%20not%20read%20data")
         end
         print("Temperature and Humidity Sensor failed")
         curron=3
         curroff=600
      end
      daynight=gpio.read(ldrpin)
      if daynight == 1 then
         curroff = curroff + (curroff * nightoff / 100)
      end
      mainoffbal = curroff
      mainstat = 0
      gpio.write(mainpin, gpio.LOW) -- put ON the main motor
   end
   if mainstat == 0 and mainoffbal == 0
      mainonbal = curron
      mainstat = 1
      gpio.write(mainpin, gpio.HIGH) -- put OFF the main motor
   end

   if fsstat == 1 and fsonbal == 0 then
      fsoffbal = fsoff
      gpio.write(fspin, gpio.LOW) -- put ON the main motor
      fsstat == 0
   end
   if fsstat == 0 and fsoffbal == 0 then
      fsonbal = fson
      gpio.write(fspin, gpio.LOW) -- put ON the main motor
      fsstat == 1
   end

   if airstat == 1 and aironbal == 0 then
      airoffbal = airoff
      gpio.write(airpin, gpio.LOW) -- put ON the main motor
      airstat == 0
   end
   if airstat == 0 and aironbal == 0 then
      aironbal = airon
      gpio.write(airpin, gpio.HIGH) -- put ON the main motor
      airstat == 1
   end

   if mainstat == 1 and mainonbal > 0 then
      mainonbal = mainonbal - 1
      if mainonbal == 0 then
         if (gpio.read(rainpin)) == 1 then
            sendstr="Dry"
            sendSMS("Raindrop%20Sensor%20did%20not%20get%20water%20from%20Fogger")
         else
            sendstr="Wet"
         end
      end
      if isTare == 0
         sendstr=sendstr.."!0" -- weight unTared (Nutrient Weight)
      else
         weight=getAverageWeight(10)
         sendstr=sendstr.."!"..string.format("%0.3f",weight)
         if weight < 2 then
            sendSMS("Nutrient%20is%20remaining%20only%20"..string.format("%0.3f",weight).."%20litres")
         end
      end
      nuttemp = -60
      t = require("ds18b20")
      function readout(temp)
         if t.sens then
         end
         for addr, temp in pairs(temp) do
--           nutaddr=addr:byte(1,8)
             nutaddr=addr
             nuttemp = temp
         end
         sendstr=sendstr.."!"..tostring(nuttemp)
         t = nil
         package.loaded["ds18b20"] = nil
      end
      t:read_temp(readout, dspin, t.C)
      if nuttemp > 28 and connected == "Y" then
         sendSMS("Nutrient%20temperature%20has%20increased%20to%20"..nuttemp)
      end


   end

   if mainstat == 0 and mainoffbal > 0 then
      mainoffbal = mainoffbal - 1
   end

   if fsstat == 1 and fsonbal > 0 then
      fsonbal = fsonbal - 1
   end
   if fsstat == 0 and fsoffbal > 0 then
      fsoffbal = fsoffbal - 1
   end

   if airstat == 1 and aironbal > 0 then
      aironbal = aironbal - 1
   end
   if airstat == 0 and airoffbal > 0 then
      airoffbal = airoffbal - 1
   end

=============================================
--  move below part after sprayer motor off

print("Starting web server on router")
dofile("SprayWorld.lc")

