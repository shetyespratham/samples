print("inside aeroponics.lua")
--routimer:unregister()
mainstat=0
mainonbal=0
mainoffbal=curroff
fsstat=0
fsonbal=0
fsoffbal=fsoff
airstat=0
aironbal=0
airoffbal=airoff

onofftimer = tmr.create()
onofftimer:register(1000, tmr.ALARM_AUTO, function()
   print("doing aeroponics")
   if end_router == "Y" then
      print("routimer unregistered")
      routimer:unregister();
   end
   if motdetbal > 300 then
      motsent = 0
      gpio.trig(motpin, gpio.INTR_ENABLE)
   end
   motdetbal = motdetbal + 1
   mainonbal = mainonbal + 1
   mainoffbal = mainoffbal + 1
   fsonbal = fsonbal + 1
   fsoffbal = fsoffbal + 1
   aironbal = aironbal + 1
   airoffbal = airoffbal + 1
   if mainoffbal >= curroff and mainstat == 0 then
      mainonbal = 0
      mainoffbal = 0
      dht_read()
      if ds18b20p == "Y" then
         t:read_temp(readout, dspin, t.C)
      end
      mainoffbal = curroff
      mainstat = 1
      gpio.write(mainpin, 0) -- put ON the main motor
   end
   if mainonbal >= curron and mainstat == 1 then
      mainoffbal = 0
      mainonbal = 0
      mainstat = 0
      gpio.write(mainpin, 1) -- put OFF the main motor
      if rainp == "Y" then
         if (gpio.read(rainpin)) == 0 then
            if rainsent == 0 then
               sendSMS("Raindrop%20Sensor%20did%20not%20get%20water%20from%20Fogger")
               rainsent = 1
            end
         end
         if hx711p == "Y" then
            if isTare ~= 0 then
               weight=getAverageWeight(10)
               if weight < 2 then
                  if hxsent == 0 then
                     sendSMS("Nutrient%20is%20remaining%20only%20"..string.format("%0.3f",weight).."%20litres")
                     hxsent = 1
                  end
               end
            end
         end
         if ds18b20p == "Y" then
            if nuttemp > 28 and connected == "Y" then
               if nuttsent == 0 then
                  sendSMS("Nutrient%20temperature%20has%20increased%20to%20"..nuttemp)
                  nuttsent = 1
               end
            end
         end
      end
   end

   if fsp == "Y" then
      if fsoffbal >= fsoff and fsstat == 0 then
         fsoffbal = 0
         fsonbal = 0
         gpio.write(fspin, 0) -- put ON fail safe motor
         fsstat = 1
      end
      if fsonbal >= fson and fsstat == 1 then
         fsoffbal = 0
         fsonbal = 0
         gpio.write(fspin, 1) -- put OFF fail safe motor
         fsstat = 0
      end
   end

   if airp == "Y" then
      if airoffbal >= airoff and airstat == 0 then
         airoffbal = 0
         aironbal = 0
         gpio.write(airpin, 0) -- put ON air pump
         airstat = 1
      end
      if aironbal >= airon and airstat == 1 then
         airoffbal = 0
         aironbal = 0
         gpio.write(airpin, 1) -- put OFF air pump
         airstat = 0
      end
   end

end)
-- print("Starting web server on router")
-- dofile("SprayWorld.lc")
onofftimer:start();
