#!/usr/bin/env lua

-- This script will let you see stuff

GOLDRATE_OFFLINE = {}
GOLDRATE_OFFLINE.isRunning = true

-- Data file:
GOLDRATE_OFFLINE.dataFile = "/Applications/World of Warcraft/WTF/Account/OPUSSF/SavedVariables/GoldRate.lua"
GoldRate_data = {}
dataStructure = {}  -- Used to store computed values from the data
timeRanges = {}  -- Used to store the time info from the data

function GOLDRATE_OFFLINE.FileExists(name)
   local f=io.open(name,"r")
   if f then io.close(f) return true else return false end
end
function GOLDRATE_OFFLINE.DoFile( filename )
	local f = assert( loadfile( filename ) )
	return f()
end
function PairsByKeys( t, f )
	local a = {}
	for n in pairs(t) do table.insert(a, n) end
	table.sort(a, f)
	local i = 0
	local iter = function()
		i = i + 1
		if a[i] == nil then return nil
		else return a[i], t[a[i]]
		end
	end
	return iter
end
function GOLDRATE_OFFLINE.ProcessData()
	-- process GoldRate_data into internal structures that make processing easier.
	timeRanges.all = {}
	timeRanges.all.oldestEntry = os.time()  -- track the oldest entry
	timeRanges.all.newestEntry = 0  -- track the newest entry
	-- Process the saved data into a better internal format
	for realm, rdata in pairs(GoldRate_data) do
		print(realm)
		dataStructure[realm] = {}
		timeRanges[realm] = {}
		timeRanges[realm].oldestEntry = os.time()  -- track the oldest entry per realm
		timeRanges[realm].newestEntry = 0
<<<<<<< HEAD
		for player, pdata in pairs(rdata) do
			print("\t"..player)
			dataStructure[realm][player] = {}
			timeRanges[realm][player] = {}
			timeRanges[realm][player].oldestEntry = os.time() -- track the oldest entry per player
			timeRanges[realm][player].newestEntry = 0
			for ts, gold in pairs(pdata) do
				if ts ~= "last" then
					timeRanges[realm][player].oldestEntry = math.min( timeRanges[realm][player].oldestEntry, ts )  -- find oldestEntry for player
					timeRanges[realm][player].newestEntry = math.max( timeRanges[realm][player].newestEntry, ts )  -- find newestEntry for player
				end
			end
			timeRanges[realm].oldestEntry = math.min( timeRanges[realm].oldestEntry, timeRanges[realm][player].oldestEntry ) -- find oldestEntry for realm
			timeRanges[realm].newestEntry = math.max( timeRanges[realm].newestEntry, timeRanges[realm][player].newestEntry )  -- find newestEntry for realm
=======
		for faction, fdata in pairs( rdata ) do
			print("\t"..faction)
			dataStructure[realm][faction] = {}
			timeRanges[realm][faction] = {}
			timeRanges[realm][faction].oldestEntry = os.time() -- track the oldest entry per player
			timeRanges[realm][faction].newestEntry = 0
			for player, pdata in pairs( fdata ) do
				print("\t\t"..player)
				dataStructure[realm][faction][player] = {}
				timeRanges[realm][faction][player] = {}
				timeRanges[realm][faction][player].oldestEntry = os.time() -- track the oldest entry per player
				timeRanges[realm][faction][player].newestEntry = 0
				for ts, gold in pairs(pdata) do
					if ts ~= "last" then
						timeRanges[realm][faction][player].oldestEntry = math.min( timeRanges[realm][faction][player].oldestEntry, ts )  -- find oldestEntry for player
						timeRanges[realm][faction][player].newestEntry = math.max( timeRanges[realm][faction][player].newestEntry, ts )  -- find newestEntry for player
					end
				end
				timeRanges[realm][faction].oldestEntry = math.min( timeRanges[realm][faction].oldestEntry, timeRanges[realm][faction][player].oldestEntry ) -- find oldestEntry for faction
				timeRanges[realm][faction].newestEntry = math.max( timeRanges[realm][faction].newestEntry, timeRanges[realm][faction][player].newestEntry )  -- find newestEntry for faction
			end
			timeRanges[realm].oldestEntry = math.min( timeRanges[realm].oldestEntry, timeRanges[realm][faction].oldestEntry ) -- find oldestEntry for realm
			timeRanges[realm].newestEntry = math.max( timeRanges[realm].newestEntry, timeRanges[realm][faction].newestEntry )  -- find newestEntry for realm
>>>>>>> develop
		end
		timeRanges.all.oldestEntry = math.min( timeRanges.all.oldestEntry, timeRanges[realm].oldestEntry ) -- find oldestEntry for all
		timeRanges.all.newestEntry = math.max( timeRanges.all.newestEntry, timeRanges[realm].newestEntry ) -- find newestEntry for all
	end
end
function GOLDRATE_OFFLINE.ReportData()
	print("ReportData\n==========")
	print( string.format( "Data ranges from %s  -->  %s",
			os.date( "%x %X", timeRanges.all.oldestEntry ), os.date( "%x %X", timeRanges.all.newestEntry ) ) )
	for realm, rdata in pairs( dataStructure ) do
		print( string.format( "% 15s: Date range: %s  -->  %s",
				realm, os.date( "%x %X", timeRanges[realm].oldestEntry), os.date( "%x %X", timeRanges[realm].newestEntry ) ) )
<<<<<<< HEAD
		for player, pdata in pairs( rdata ) do
			print( string.format( "% 27s: Date range: %s  -->  %s",
					player, os.date( "%x %X", timeRanges[realm][player].oldestEntry ), os.date( "%x %X", timeRanges[realm][player].newestEntry ) ) )
=======
		for faction, fdata in pairs( rdata ) do
			print( string.format( "% 27s: Date range: %s  -->  %s",
					faction, os.date( "%x %X", timeRanges[realm][faction].oldestEntry ), os.date( "%x %X", timeRanges[realm][faction].newestEntry ) ) )
			for player, pdata in pairs( fdata ) do
				print( string.format( "% 39s: Date range: %s  -->  %s",
						player, os.date( "%x %X", timeRanges[realm][faction][player].oldestEntry ), os.date( "%x %X", timeRanges[realm][faction][player].newestEntry ) ) )
			end
>>>>>>> develop
		end
	end
end
function GOLDRATE_OFFLINE.printHelp()
	for cmd, info in pairs(GOLDRATE_OFFLINE.CommandList) do
		print(string.format("\t%s %s -> %s",
			cmd, info.help[1], info.help[2]));
	end
end
GOLDRATE_OFFLINE.CommandList = {
	['help'] = {
		["func"] = GOLDRATE_OFFLINE.printHelp,
		["help"] = {"", "Prints this help text" },
	},
	['q'] = {
		["func"] = function() GOLDRATE_OFFLINE.isRunning = false end,
		["help"] = {"", "Quit" },
	},
}
function GOLDRATE_OFFLINE.parseCmd( line )
	if line then
		line = string.lower( line )
		local a,b,c = string.find( line, "(%S+)" )  --contiguous string of non-space characters
		if a then
			-- c is the matched string, strsub is everything after that, skipping the space
			return c, string.sub( line, b+2 )
		else
			return ""
		end
	end
end
function GOLDRATE_OFFLINE.performPrompt()
	io.write( "GOLDRATE: ")
	cmd, param = GOLDRATE_OFFLINE.parseCmd( io.read("*l") ) -- read a line, parse it
	if cmd then
		cmdFunc = GOLDRATE_OFFLINE.CommandList[cmd]
		if cmdFunc then
			cmdFunc.func( param )
		else
			GOLDRATE_OFFLINE.printHelp()
		end
	else
		GOLDRATE_OFFLINE.isRunning = false
	end
end

-------------------------------------------------

if GOLDRATE_OFFLINE.FileExists( GOLDRATE_OFFLINE.dataFile ) then
	GOLDRATE_OFFLINE.DoFile( GOLDRATE_OFFLINE.dataFile )
end
GOLDRATE_OFFLINE.ProcessData()
GOLDRATE_OFFLINE.ReportData()

while GOLDRATE_OFFLINE.isRunning do
	GOLDRATE_OFFLINE.performPrompt()
end
