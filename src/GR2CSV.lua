#!/usr/bin/env lua

dataFile = "/Applications/World of Warcraft/WTF/Account/OPUSSF/SavedVariables/GoldRate.lua"

function FileExists( name )
   local f = io.open( name, "r" )
   if f then io.close( f ) return true else return false end
end
function DoFile( filename )
	local f = assert( loadfile( filename ) )
	return f()
end
function PairsByKeys( t, f )  -- This is an awesome function I found
	local a = {}
	for n in pairs( t ) do table.insert( a, n ) end
	table.sort( a, f )
	local i = 0
	local iter = function()
		i = i + 1
		if a[i] == nil then return nil
		else return a[i], t[a[i]]
		end
	end
	return iter
end
function Rate( realmIn, factionIn )
	-- returns rate/second (slope), seconds till threshold
	-- this uses the least squares method to define the following equation for the data set.
	-- y = mx + b

	-- Step 0 - find the maxInitialTS to filter data
	maxInitialTS = 0
	for name, pdata in pairs( GoldRate_data[realmIn][factionIn].toons ) do
		maxInitialTS = math.max( maxInitialTS, pdata.firstTS )
	end

	-- Step 1 - Calculate the mean for both the x (timestamp) and y (gold) values
	local count, tsSum, goldSum = 0, 0, 0
	for ts, gold in pairs(GoldRate_data[realmIn][factionIn].consolidated) do
		if ts >= maxInitialTS then  -- only compute if the data fits the TS range
			--tsSum = tsSum + (ts - GoldRate.maxInitialTS)
			tsSum = tsSum + ts
			goldSum = goldSum + gold
			count = count + 1
		end
	end
	if count > 1 then
		local tsAve = tsSum / count
		local goldAve = goldSum / count

		-- Step 2 -- m (slope) = sum( (Xi - Xave) * (Yi - Yave) )
	    --                       --------------------------------
	    --                       sum( (Xi - Xave)^2 )
	    local xySum, x2Sum = 0, 0
	    for ts, gold in pairs(GoldRate_data[realmIn][factionIn].consolidated) do -- yes, 2nd loop through data
	    	if ts >= maxInitialTS then  -- only compute if the data fits the TS range
				--xySum = xySum + ((ts - GoldRate.maxInitialTS) - tsAve) * (gold - goldAve)
				--x2Sum = x2Sum + math.pow((ts - GoldRate.maxInitialTS) - tsAve, 2)
				xySum = xySum + (ts - tsAve) * (gold - goldAve)
				x2Sum = x2Sum + math.pow(ts - tsAve, 2)
			end
	    end
	    local m = xySum / x2Sum

	    -- Step 3 -- Calculate the y-intercept.  b = Yave - ( m * xAve )
	    --local b = (tsAve + GoldRate.maxInitialTS) - ( m * goldAve )
	    local b = goldAve  - ( m * tsAve )

	    -- Final Step -- Use the data to solve for TS at Gold Value
	    -- x = ( y - b ) / m
	    local targetTS = GoldRate_data[realmIn][factionIn].goal and (( GoldRate_data[realmIn][factionIn].goal - b ) / m ) or 0

		return m, targetTS
	end
end

if FileExists( dataFile ) then
	DoFile( dataFile )
	local strOut = ""
	if GoldRate_data then
		print("Realm,Faction,TimeStamp,TimeStamp,Gold")
		for realm, rdata in pairs( GoldRate_data ) do
			maxInitialTS = 0
			for faction, fdata in pairs( rdata ) do
				m, targetTS = Rate(realm, faction)

				for name, pdata in pairs( fdata.toons ) do
					maxInitialTS = math.max( maxInitialTS, pdata.firstTS)
				end
				if fdata.consolidated then
					for ts, val in PairsByKeys( fdata.consolidated ) do
						if ts >= maxInitialTS and ts >= (os.time() - (GoldRate_options.graphAgeDays * 86400)) then
							strOut = strOut .. string.format( '%s,%s,%s,%i,%s\n', realm, faction, os.date( "%x %X", ts ),ts, val )
						end
					end
				end
				--[[
				if GoldRate_data[realm][faction].goal then
					strOut = strOut .. string.format("%s,%s,%s,%i,%i,target\n", realm, faction, os.date( "%x %X", targetTS), targetTS, GoldRate_data[realm][faction].goal )
				end
				]]
			end
		end
	end
	if GoldRate_tokenData then
		for ts, val in PairsByKeys( GoldRate_tokenData ) do
			if ts >= (os.time() - (GoldRate_options.graphAgeDays * 86400)) then
				strOut = strOut .. string.format( '%s,%s,%s,%i,%s\n', "TokenData", "Both", os.date( "%x %X", ts ),ts, val )
			end
		end
	end
	print(strOut)
	print("\n")
end