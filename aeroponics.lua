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
ticks=0
read_temp_busy="N"
onofftimer = tmr.create()
onofftimer:register(1000, tmr.ALARM_AUTO, function()
-- print("doing aeroponics")
   ticks = ticks + 1
-- if ticks == 597 then
--    if read_temp_busy == "N" then
--       read_temp_busy = "Y"
--       t:read_temp(readout, dspin, t.C)
--       read_temp_busy = "N"
--    end
-- end
-- if ticks == 600 then
--    getsensors()
-- end
   if table.maxn(adtable) > 0 then
      if ad_busy == "N" then
         set_volume(dayvol)
         insert_ad()
      end
   end
   if ticks == 601 then
      dht_readweb()
      if dhtstats == dht.OK then
         sendRecord("Temperature%20"..tostring(currtemp).."!Humidity%20"..tostring(currhumid).."!Motor%20ON%20Time%20"..tostring(curron).."!Motor%20OFF%20Time%20"..tostring(curroff).."!Light%20"..tostring(daynight).."!Nutrient%20Temp%20"..tostring(nuttemp))
      end
   end
   if ticks > 601 then
      ticks = 0
   end
   if end_router == "Y" then
      print("routimer unregistered")
      routimer:unregister();
   end
   if motdetbal > motact then
      motsent = 0
      motdet=0
      gpio.trig(motpin, gpio.INTR_UP, motcb)
      gpio.write(motlightpin, 0) -- put motion light off
   end
   if ldrbal > 12 and ldrbal < 14 then
      print("INTR Enabled")
      gpio.trig(ldrpin, gpio.INTR_UP_DOWN, ldrcb)
      daynight=gpio.read(ldrpin)
      ad_busy="N"
      if daynight == 1 then
         set_volume(nightvol)
      else
         set_volume(dayvol)
      end
   end
   if ldrbal < 14 then
      ldrbal = ldrbal + 1
--    print(ldrbal)
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
      if dhtstats ~= dht.OK then
         if dhtsent == 0 and thng_done == "Y" then
            table.insert(SMSStack,"Raindrop%20Sensor%20did%20not%20get%20water%20from%20Fogger")
            rainsent = 1
         end
      end
      if ds18b20p == "Y" then
         if read_temp_busy == "N" then
            read_temp_busy = "Y"
            t18:read_temp(readout, dspin, t18.C)
            read_temp_busy = "N"
         end
      end
      if nuttemp == 0 then
         if nutfsent == 0 and thng_done == "Y" then
            table.insert(adtable,0803)
            nutfsent = 1
         end
      end
      mainoffbal = curroff
      mainstat = 1
      gpio.write(mainpin, 1) -- put ON the main motor
      sendRecord("Main%20motor%20Started")
   end
   if mainonbal >= curron and mainstat == 1 then
      mainoffbal = 0
      mainonbal = 0
      mainstat = 0
      sendRecord("Main%20motor%20stopped")
      gpio.write(mainpin, 0) -- put OFF the main motor
      if rainp == "Y" then
         if (gpio.read(rainpin)) == 1 then
            table.insert(adtable,0204)
            if rainsent == 0 and thng_done == "Y" then
               table.insert(SMSStack,"Raindrop%20Sensor%20did%20not%20get%20water%20from%20Fogger")
               rainsent = 1
            end
         end
         if hx711p == "Y" then
            if isTare ~= 0 then
               getAverageWeight(10)
               if weight < 2 then
                  table.insert(adtable,0306)
                  if hxsent == 0 and thng_done == "Y" then
                     table.insert(SMSStack,"Nutrient%20is%20remaining%20only%20"..string.format("%0.3f",weight).."%20litres")
                     hxsent = 1
                  end
               end
            end
            if isTare == 0 then
               table.insert(adtable,0410)
               if taresent == 0 and thng_done == "Y" then
                  table.insert(SMSStack,"Nutrient%20weight%20is%20not%20tared")
                  taresent = 1
               end
            end
         end
         if ds18b20p == "Y" then
            if nuttemp > currtemp then
               table.insert(adtable,0508)
               if connected == "Y" then
                  if nuttsent == 0 and thng_done == "Y" then
                     table.insert(SMSStack,"Nutrient%20temperature%20has%20increased%20to%20"..nuttemp)
                     nuttsent = 1
                  end
               end
            end
         end
      end
   end

   if fsp == "Y" then
      if fsoffbal >= fsoff and fsstat == 0 then
         fsoffbal = 0
         fsonbal = 0
         sendRecord("Failsafe%20motor%20started")
         gpio.write(fspin, 1) -- put ON fail safe motor
         fsstat = 1
      end
      if fsonbal >= fson and fsstat == 1 then
         fsoffbal = 0
         fsonbal = 0
         sendRecord("Failsafe%20motor%20stopped")
         gpio.write(fspin, 0) -- put OFF fail safe motor
         fsstat = 0
      end
   end

   if airp == "Y" then
      if airoffbal >= airoff and airstat == 0 then
         airoffbal = 0
         aironbal = 0
         sendRecord("AirPump%20started")
         gpio.write(airpin, 1) -- put ON air pump
         airstat = 1
      end
      if aironbal >= airon and airstat == 1 then
         airoffbal = 0
         aironbal = 0
         sendRecord("AirPump%20stopped")
         gpio.write(airpin, 0) -- put OFF air pump
         airstat = 0
      end
   end

end)
onofftimer:start();
