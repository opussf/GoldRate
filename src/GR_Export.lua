#!/usr/bin/env lua
-- args:  <accountPath> <xml | json | csv>
accountPath = arg[1]
exportType = arg[2]

pathSeparator = string.sub(package.config, 1, 1) -- first character of this string (http://www.lua.org/manual/5.2/manual.html#pdf-package.config)
-- remove 'extra' separators from the end of the given path
while (string.sub( accountPath, -1, -1 ) == pathSeparator) do
	accountPath = string.sub( accountPath, 1, -2 )
end
-- append the expected location of the datafile
dataFilePath = {
	accountPath,
	"SavedVariables",
	"GoldRate.lua"
}
dataFile = table.concat( dataFilePath, pathSeparator )

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

function ExportXML()
end
function ExportJSON()
	strOut = "No data structure."
	if GoldRate_data then
		strOut = '{"goldRate": {\n'
		strOut = strOut .. '"graphAgeDays": '..GoldRate_options.graphAgeDays..',\n'
		strOut = strOut .. '"realms": [\n'

		realms = {}
		for realm, rdata in pairs( GoldRate_data ) do
			maxInitialTS = 0
			rStr = string.format( '{"realm": "%s","factions": [\n', realm)
			factions = {}
			for faction, fdata in pairs( rdata ) do
				fStr = string.format( '{"faction": "%s",', faction )
				m, targetTS = Rate(realm, faction)
				if fdata.goal and targetTS then
					fStr = fStr .. string.format( '"goal": %s,', fdata.goal )
				end
				for name, pdata in pairs( fdata.toons ) do
					maxInitialTS = math.max( maxInitialTS, pdata.firstTS)
				end
				gdata = {}
				if fdata.consolidated then
					for ts, val in PairsByKeys( fdata.consolidated ) do
						if ts >= maxInitialTS and ts >= (os.time() - (GoldRate_options.graphAgeDays * 86400)) then
							table.insert( gdata, string.format('[%s,%s]', ts, val) )
						end
					end
				end
				fStr = fStr .. '"data": [\n' .. table.concat( gdata, "," ) .. "]}"
				--[[
				if GoldRate_data[realm][faction].goal then
					strOut = strOut .. string.format("%s,%s,%s,%i,%i,target\n", realm, faction, os.date( "%x %X", targetTS), targetTS, GoldRate_data[realm][faction].goal )
				end
				]]
				table.insert( factions, fStr )
			end
			rStr = rStr .. table.concat( factions, ",\n" ) .. "]}"
			table.insert( realms, rStr )
		end
		if GoldRate_tokenData then
			rStr = string.format( '{"realm": "%s","factions": [\n', "TokenData")
			rStr = rStr .. '{"faction": "Both",'

			gdata = {}
			for ts, val in PairsByKeys( GoldRate_tokenData ) do
				if ts >= (os.time() - (GoldRate_options.graphAgeDays * 86400)) then
					table.insert( gdata, string.format('[%s,%s]', ts, val) )
				end
			end
			rStr = string.format( '%s"data": [%s]}]}\n', rStr, table.concat( gdata, "," ) )
			table.insert( realms, rStr )
		end

		strOut = strOut .. table.concat(realms, ",\n") .. ']'
		strOut = strOut .. "}" -- goldRate
		strOut = strOut .. "}" -- file
	end
	return strOut
end
function ExportCSV()
	strOut = "Realm,Faction,TimeStamp,TimeStamp,Gold\n"
	if GoldRate_data then
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
	return strOut
end
----

functionList = {
	["xml"] = ExportXML,
	["json"] = ExportJSON,
	["csv"] = ExportCSV
}

func = functionList[string.lower( exportType )]

if dataFile and FileExists( dataFile ) and exportType and func then
	DoFile( dataFile )
	strOut = func()
	print( strOut )
else
	io.stderr:write( "Something is wrong.  Lets review:\n")
	io.stderr:write( "Data file provided: "..( dataFile and " True" or "False" ).."\n" )
	io.stderr:write( "Data file exists  : "..( FileExists( dataFile ) and " True" or "False" ).."\n" )
	io.stderr:write( "ExportType given  : "..( exportType and " True" or "False" ).."\n" )
	io.stderr:write( "ExportType valid  : "..( func and " True" or "False" ).."\n" )
end
