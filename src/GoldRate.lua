GOLDRATE_MSG_ADDONNAME = "GoldRate";
GOLDRATE_MSG_VERSION   = GetAddOnMetadata(GOLDRATE_MSG_ADDONNAME,"Version");
GOLDRATE_MSG_AUTHOR    = "opussf";

-- Colours
COLOR_RED = "|cffff0000";
COLOR_GREEN = "|cff00ff00";
COLOR_BLUE = "|cff0000ff";
COLOR_PURPLE = "|cff700090";
COLOR_YELLOW = "|cffffff00";
COLOR_ORANGE = "|cffff6d00";
COLOR_GREY = "|cff808080";
COLOR_GOLD = "|cffcfb52b";
COLOR_NEON_BLUE = "|cff4d4dff";
COLOR_END = "|r";

GoldRate = {}
GoldRate_data = {}

function GoldRate.Print( msg, showName)
	-- print to the chat frame
	-- set showName to false to suppress the addon name printing
	if (showName == nil) or (showName) then
		msg = COLOR_PURPLE..GOLDRATE_MSG_ADDONNAME.."> "..COLOR_END..msg
	end
	DEFAULT_CHAT_FRAME:AddMessage( msg )
end
function GoldRate.OnLoad()
	SLASH_GOLDRATE1 = "/GR"
	SLASH_GOLDRATE2 = "/GoldRate"
	SlashCmdList["GOLDRATE"] = function(msg) GoldRate.Command(msg); end

	GoldRate_Frame:RegisterEvent("ADDON_LOADED")
	GoldRate_Frame:RegisterEvent("PLAYER_ENTERING_WORLD")
	GoldRate_Frame:RegisterEvent("PLAYER_MONEY")
end
--------------
-- Event Functions
--------------
function GoldRate.ADDON_LOADED()
	-- Unregister the event for this method.
	GoldRate_Frame:UnregisterEvent("ADDON_LOADED")

	-- Setup needed variables
	GoldRate.realm   = GetRealmName()
	GoldRate.faction = UnitFactionGroup("player")
	GoldRate.name    = UnitName("player")

	GoldRate_data[GoldRate.realm] = GoldRate_data[GoldRate.realm] or {}
	GoldRate_data[GoldRate.realm][GoldRate.faction] = GoldRate_data[GoldRate.realm][GoldRate.faction] or {}
	GoldRate_data[GoldRate.realm][GoldRate.faction].consolidated = GoldRate_data[GoldRate.realm][GoldRate.faction].consolidated or {}
	GoldRate_data[GoldRate.realm][GoldRate.faction].toons = GoldRate_data[GoldRate.realm][GoldRate.faction].toons or {}
	GoldRate_data[GoldRate.realm][GoldRate.faction].toons[GoldRate.name] = GoldRate_data[GoldRate.realm][GoldRate.faction].toons[GoldRate.name] or {}
	GoldRate.otherSummed = 0
	for toonName, toonData in pairs( GoldRate_data[GoldRate.realm][GoldRate.faction].toons ) do
		GoldRate.otherSummed = GoldRate.otherSummed + (toonName == GoldRate.name and 0 or toonData.last)
	end
end
function GoldRate.PLAYER_MONEY()
	GoldRate_data[GoldRate.realm][GoldRate.faction].toons[GoldRate.name]["last"] = GetMoney()
	GoldRate_data[GoldRate.realm][GoldRate.faction].toons[GoldRate.name]["firstTS"] =
			GoldRate_data[GoldRate.realm][GoldRate.faction].toons[GoldRate.name]["firstTS"] or time()
	GoldRate_data[GoldRate.realm][GoldRate.faction].consolidated[time()] = GoldRate.otherSummed + GetMoney()

	GoldRate.ShowRate()
end
GoldRate.PLAYER_ENTERING_WORLD = GoldRate.PLAYER_MONEY
--------------
-- Non Event functions
--------------
function GoldRate.RateSimple()
	-- returns rate/second, seconds till threshold, totalgained
	-- this simply uses the first and last data elements to calculate a line for prediction (uber simple)
	fdata = GoldRate_data[GoldRate.realm][GoldRate.faction]
	GoldRate.maxInitialTS = 0
	for name, pdata in pairs( fdata.toons ) do
		GoldRate.maxInitialTS = math.max( GoldRate.maxInitialTS, pdata.firstTS )
	end
	local sortedKeys = {}
	for ts in pairs( GoldRate_data[GoldRate.realm][GoldRate.faction].consolidated ) do
		if ts >= GoldRate.maxInitialTS then table.insert( sortedKeys, ts ) end
	end
	table.sort( sortedKeys )
	local startGold = GoldRate_data[GoldRate.realm][GoldRate.faction].consolidated[GoldRate.maxInitialTS]
	local newestTS = sortedKeys[#sortedKeys]
	local endGold = GoldRate_data[GoldRate.realm][GoldRate.faction].consolidated[newestTS]
	local timeDiff = newestTS - GoldRate.maxInitialTS

	local goldDiff = endGold - startGold
	local rate = goldDiff / timeDiff
	--GoldRate.Print( "Gold Needed: "..GetCoinTextureString(
	--		(GoldRate_data[GoldRate.realm][GoldRate.faction].goal and GoldRate_data[GoldRate.realm][GoldRate.faction].goal - endGold or 0) ) )
	local targetTS = (GoldRate_data[GoldRate.realm][GoldRate.faction].goal and
			(time() + ((GoldRate_data[GoldRate.realm][GoldRate.faction].goal - endGold) / rate)) or 0)

	return rate, targetTS, goldDiff
end
function GoldRate.Rate()
	-- returns rate/second (slope), seconds till threshold, and totalgained
	-- this uses the least squares method to define the following equation for the data set.
	-- y = mx + b

	-- Step 0 - find the maxInitialTS to filter data
	GoldRate.maxInitialTS = 0
	for name, pdata in pairs( GoldRate_data[GoldRate.realm][GoldRate.faction].toons ) do
		GoldRate.maxInitialTS = math.max( GoldRate.maxInitialTS, pdata.firstTS )
	end

	-- Step 1 - Calculate the mean for both the x (timestamp) and y (gold) values
	local count, tsSum, goldSum = 0, 0, 0
	for ts, gold in pairs(GoldRate_data[GoldRate.realm][GoldRate.faction].consolidated) do
		if ts >= GoldRate.maxInitialTS then  -- only compute if the data fits the TS range
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
	    for ts, gold in pairs(GoldRate_data[GoldRate.realm][GoldRate.faction].consolidated) do -- yes, 2nd loop through data
	    	if ts >= GoldRate.maxInitialTS then  -- only compute if the data fits the TS range
				--xySum = xySum + ((ts - GoldRate.maxInitialTS) - tsAve) * (gold - goldAve)
				--x2Sum = x2Sum + math.pow((ts - GoldRate.maxInitialTS) - tsAve, 2)
				xySum = xySum + (ts - tsAve) * (gold - goldAve)
				x2Sum = x2Sum + math.pow(ts - tsAve, 2)
				if xySum < 0 or x2Sum < 0 then
					GoldRate.Print("------UH")
					GoldRate.overFlow = true
				end
				if GoldRate.overFlow then
					GoldRate.Print( xySum.." : "..x2Sum )
				end
			end
	    end
	    local m = xySum / x2Sum

	    -- Step 3 -- Calculate the y-intercept.  b = Yave - ( m * xAve )
	    --local b = (tsAve + GoldRate.maxInitialTS) - ( m * goldAve )
	    local b = goldAve  - ( m * tsAve )

--	    GoldRate.Print( string.format( "tsAve(X): %s goldAve(Y): %s m: %0.2f",
--	    								date("%x %X", tsAve), GetCoinTextureString( goldAve ), m ) )
--	    GoldRate.Print( "b = tsAve - ( m * goldAve )" )
	    --GoldRate.Print( string.format("func = %0.2fx + %0f", m, b ) )
--	    GoldRate.Print( "b = "..date("%x %X", tonumber(b) ) )

	    -- Final Step -- Use the data to solve for TS at Gold Value
	    -- x = ( y - b ) / m
	    local targetTS = GoldRate_data[GoldRate.realm][GoldRate.faction].goal and (( GoldRate_data[GoldRate.realm][GoldRate.faction].goal - b ) / m ) or 0

	    --GoldRate.Print( "targetTS: "..date("%m/%d/%Y",targetTS) )

		return m, targetTS, 300
	end
	return 0, 0, 0
end
function GoldRate.ShowRate()
	local r, targetTS, gGained = GoldRate.Rate()
	local rs, targetTSs, _ = GoldRate.RateSimple()

	GoldRate.Print( "Total: ".. GetCoinTextureString( GoldRate.otherSummed + GetMoney() ) ..
			(GoldRate_data[GoldRate.realm][GoldRate.faction].goal
				and " -> "..GetCoinTextureString( GoldRate_data[GoldRate.realm][GoldRate.faction].goal ) or "" ) )

	if targetTS then
		GoldRate.Print( string.format( "@ Simple: %s (%0.2f) Squares: %s (%0.2f)",
			date("%c", targetTSs), rs, date("%c", targetTS), r ) )
	end

	--GoldRate.Print( GetCoinTextureString( gGained ).." gained since "..date("%x %X", GoldRate.maxInitialTS).." at a rate of "..r.." g/sec ")
end
function GoldRate.SetGoal( value )
	GoldRate_data[GoldRate.realm][GoldRate.faction].goal = GoldRate.SumGoldValue( value, GoldRate_data[GoldRate.realm][GoldRate.faction].goal )

	if GoldRate_data[GoldRate.realm][GoldRate.faction].goal and GoldRate_data[GoldRate.realm][GoldRate.faction].goal <= 0 then
		GoldRate_data[GoldRate.realm][GoldRate.faction].goal = nil
	end
	GoldRate.Print( "Goal set to: "..
			(GoldRate_data[GoldRate.realm][GoldRate.faction].goal
				and GetCoinTextureString( GoldRate_data[GoldRate.realm][GoldRate.faction].goal)
				or "0" )
	)
end
function GoldRate.SumGoldValue( strIn, valueIn )
	-- takes a string representing a gold (silver, copper) value, and an optional value, returns the value or sum of the 2.
	-- strIn - string: string or interger value
	-- valueIn - integer: optional integer to sum in
	-- returns - interger: value in copper
	local copperValue = 0
	if strIn and strIn ~= "" then
		sub = strfind( strIn, "^[-]" )
		add = strfind( strIn, "^[+]" )
		if tonumber(strIn) then
			copperValue = tonumber(strIn)
		else
			local gold   = strmatch( strIn, "(%d+)g" )
			local silver = strmatch( strIn, "(%d+)s" )
			local copper = strmatch( strIn, "(%d+)c" )
			copperValue = ((gold or 0) * 10000) + ((silver or 0) * 100) + (copper or 0)
			if sub then copperValue = -copperValue end
		end
	else
		return valueIn
	end
	return( valueIn and ((sub or add) and valueIn + copperValue) or tonumber(copperValue) )
end
function GoldRate.ParseCmd(msg)
	if msg then
		local i,c = strmatch(msg, "^(|c.*|r)%s*(%d*)$")
		if i then  -- i is an item, c is a count or nil
			return i, c
		else  -- Not a valid item link
			msg = string.lower(msg)
			local a,b,c = strfind(msg, "(%S+)")  --contiguous string of non-space characters
			if a then
				-- c is the matched string, strsub is everything after that, skipping the space
				return c, strsub(msg, b+2)
			else
				return ""
			end
		end
	end
end
function GoldRate.Command(msg)
	local cmd, param = GoldRate.ParseCmd(msg);
	if GoldRate.CommandList[cmd] and GoldRate.CommandList[cmd].alias then
		cmd = GoldRate.CommandList[cmd].alias
	end
	local cmdFunc = GoldRate.CommandList[cmd];
	if cmdFunc then
		cmdFunc.func(param);
	else
		GoldRate.PrintHelp()
	end
end
function GoldRate.PrintHelp()
	GoldRate.Print( string.format( "%s (%s) by %s", GOLDRATE_MSG_ADDONNAME, GOLDRATE_MSG_VERSION, GOLDRATE_MSG_AUTHOR ) )
	for cmd, info in pairs(GoldRate.CommandList) do
		if info.help then
			local cmdStr = cmd
			for c2, i2 in pairs(GoldRate.CommandList) do
				if i2.alias and i2.alias == cmd then
					cmdStr = string.format( "%s / %s", cmdStr, c2 )
				end
			end
			GoldRate.Print(string.format("%s %s %s -> %s",
				SLASH_GOLDRATE1, cmdStr, info.help[1], info.help[2]));
		end
	end
end
-- this needs to be at the end because it is referencing functions
GoldRate.CommandList = {
	["help"] = {
		["func"] = GoldRate.PrintHelp,
		["help"] = {"","Print this help."},
	},
	["goal"] = {
		["func"] = GoldRate.SetGoal,
		["help"] = {"<amount>","Set the target goal."}
	},
}
