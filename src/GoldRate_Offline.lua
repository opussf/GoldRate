#!/usr/bin/env lua

-- This script will let you see stuff

GOLDRATE_OFFLINE = {}

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
		end
	end
end
function GOLDRATE_OFFLINE.ReportData()
	print("ReportData\n==========")
	for realm, rdata in pairs( dataStructure ) do
		print( string.format( "% 20s: Date range: %s  -->  %s",
				realm, os.date( "%x %X", timeRanges[realm].oldestEntry), os.date( "%x %X", timeRanges[realm].newestEntry ) ) )
		for player, pdata in pairs( rdata ) do
			print( string.format( "% 32s: Date range: %s  -->  %s",
					player, os.date( "%x %X", timeRanges[realm][player].oldestEntry ), os.date( "%x %X", timeRanges[realm][player].newestEntry ) ) )
		end
	end
end
--[[
function INEED_OFFLINE.setMetaData()
	-- This
	local itemCount = 0
	local realmCount = 0
	local playerCount = 0
	local oldestUpdate = os.time()
	local oldestAdded = os.time()
	local realms = {}
	local realmNames = {}
	local names = {}
	local playerNames = {}
	local itemData = {}    -- sortable table of all the data
	for itemID, _ in pairs( INEED_data ) do
		itemCount = itemCount + 1
		for realm, _ in pairs( INEED_data[itemID] ) do
			realms[realm] = 1
			for name, data in pairs( INEED_data[itemID][realm] ) do
				table.insert( itemData, {	["itemID"] = itemID,
											["realm"] = realm,
											["name"] = name,
											["fullName"] = name.."-"..realm,
											["added"] = data.added or 1,
											["updated"] = data.updated or 1,
										})
				oldestUpdate = math.min( oldestUpdate, tonumber( data.updated or 1 ) )
				if not data.added then
					print( itemID.." does not have an added timestamp")
				end
				oldestAdded = math.min( oldestAdded, tonumber( data.added or 1 ) )
				names[name.."-"..realm] = 1
			end
		end
	end
	table.sort( itemData, function(a,b) return a.updated<b.updated end )

	for k, v in pairs( realms ) do
		realmCount = realmCount + 1
		table.insert(realmNames, k)
	end
	table.sort(realmNames)

	for k, v in pairs( names ) do
		playerCount = playerCount + 1
		table.insert(playerNames, k)
	end
	table.sort(playerNames)

	INEED_OFFLINE.metaData.itemData      = itemData
	INEED_OFFLINE.metaData.itemCount     = itemCount
	INEED_OFFLINE.metaData.realmCount    = realmCount
	INEED_OFFLINE.metaData.playerCount   = playerCount
	INEED_OFFLINE.metaData.oldestUpdated = oldestUpdate
	INEED_OFFLINE.metaData.oldestAdded   = oldestAdded
	INEED_OFFLINE.metaData.realmNames    = realmNames
	INEED_OFFLINE.metaData.playerNames   = playerNames
end
function INEED_OFFLINE.getStats( )
	-- return a string of stats
end
function INEED_OFFLINE.showStats()
	print( "Stats:" )
	print( "\titems   : "..INEED_OFFLINE.metaData.itemCount )
	print( "\trealms  : "..INEED_OFFLINE.metaData.realmCount )
	print( "\tplayers : "..INEED_OFFLINE.metaData.playerCount )
	print( "Oldest items ---")
	print( "\tadded   : "..os.date( "%x %X", INEED_OFFLINE.metaData.oldestAdded ) )
	print( "\tupdated : "..os.date( "%x %X", INEED_OFFLINE.metaData.oldestUpdate ) )
end
function INEED_OFFLINE.list( type )
	local showTable = {}
	if type == "realms" then
		showTable = INEED_OFFLINE.metaData.realmNames
	elseif type == "names" then
		showTable = INEED_OFFLINE.metaData.playerNames
	elseif type == "items" then
		-- @TODO: build and sort a showTable of the items

		for itemID, _ in pairs( INEED_data ) do
			totalHave, inMail, totalNeeded, playerCount = 0, 0, 0, 0
			for realm, _ in pairs(INEED_data[itemID]) do
				for name, playerInfo in pairs(INEED_data[itemID][realm]) do
					totalHave = totalHave + playerInfo.total
					inMail = inMail + (playerInfo.inMail or 0)
					totalNeeded = totalNeeded + playerInfo.needed
					playerCount = playerCount + 1
				end
			end
			table.insert( showTable, string.format("item:%06i    %i players have (%3i/%3i)  http://www.wowhead.com/item=%i",
				itemID, playerCount, totalHave+inMail, totalNeeded, itemID ) )
		end
		table.sort( showTable )
	end
	for i,item in pairs( showTable ) do
		print( string.format( " %3i: %25s", i, item ) )
	end
end
function INEED_OFFLINE.showInfo( type )
	for itemID, _ in pairs( INEED_data ) do

	end
end
function INEED_OFFLINE.printHelp()
	for cmd, info in pairs(INEED_OFFLINE.CommandList) do
		print(string.format("\t%s %s -> %s",
			cmd, info.help[1], info.help[2]));
	end
end
INEED_OFFLINE.CommandList = {
	['help'] = {
		["func"] = INEED_OFFLINE.printHelp,
		["help"] = {"", "Prints this help text" },
	},
	['q'] = {
		["func"] = function() INEED_OFFLINE.isRunning = false; end,
		["help"] = {"", "Quit" },
	},
	['stats'] = {
		["func"] = INEED_OFFLINE.showStats,
		["help"] = {"", "Show stats"},
	},
	['show'] = {
		["func"] = INEED_OFFLINE.showInfo,
		["help"] = {"<realm>|<name>", "Show specific info"},
	},
	['list'] = {
		["func"] = INEED_OFFLINE.list,
		["help"] = {"items|realms|names", "List items, realms, names"},
	},
}
function INEED_OFFLINE.parseCmd( line )
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
function INEED_OFFLINE.performPrompt()
	io.write( "INEED: ")
	cmd, param = INEED_OFFLINE.parseCmd( io.read("*l") ) -- read a line, parse it
	if cmd then
		cmdFunc = INEED_OFFLINE.CommandList[cmd]
		if cmdFunc then
			cmdFunc.func( param )
		else
			INEED_OFFLINE.printHelp()
		end
	else
		INEED_OFFLINE.isRunning = false
	end
end
]]
-------------------------------------------------

if GOLDRATE_OFFLINE.FileExists( GOLDRATE_OFFLINE.dataFile ) then
	GOLDRATE_OFFLINE.DoFile( GOLDRATE_OFFLINE.dataFile )
end
GOLDRATE_OFFLINE.ProcessData()
GOLDRATE_OFFLINE.ReportData()
--[[
while INEED_OFFLINE.isRunning do
	INEED_OFFLINE.performPrompt()
end
]]