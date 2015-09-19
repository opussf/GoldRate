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
GoldRate_options = {['maxDataPoints'] = 1000, ['nextTokenScanTS'] = 0}
GoldRate_tokenData = {} -- [timestamp] = value
GoldRate_guildWhiteList = {}


function GoldRate.Print( msg, showName)
	-- print to the chat frame
	-- set showName to false to suppress the addon name printing
	if (showName == nil) or (showName) then
		msg = COLOR_PURPLE..GOLDRATE_MSG_ADDONNAME.."> "..COLOR_END..msg
	end
	DEFAULT_CHAT_FRAME:AddMessage( msg )
end

function GoldRate.GuildPrint( msg )
	if (IsInGuild()) then
		guildName, guildRankName, guildRankIndex = GetGuildInfo("player")

		GoldRate.Print(GoldRate.realm.."-"..guildName)
		SendChatMessage( msg, "GUILD" )
	end
	--if (IsInGuild() and RF_options.guild) then
	--	SendChatMessage( msg, "GUILD" );
--	else
--		RF.Print( COLOR_RED.."RF.GuildPrint: "..COLOR_END..msg, false );
	--end
end

function GoldRate.OnLoad()
	SLASH_GOLDRATE1 = "/GR"
	SLASH_GOLDRATE2 = "/GoldRate"
	SlashCmdList["GOLDRATE"] = function(msg) GoldRate.Command(msg); end

	GoldRate_Frame:RegisterEvent("ADDON_LOADED")
	GoldRate_Frame:RegisterEvent("PLAYER_ENTERING_WORLD")
	GoldRate_Frame:RegisterEvent("PLAYER_MONEY")
	GoldRate_Frame:RegisterEvent("PLAYER_LEAVING_WORLD")
	GoldRate_Frame:RegisterEvent("TOKEN_MARKET_PRICE_UPDATED")
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
	if GoldRate_tokenData then -- parse and store the last known value of the WoWToken
		maxTS = 0
		for ts, _ in pairs(GoldRate_tokenData) do
			maxTS = max(maxTS, ts)
		end
		GoldRate.tokenLast = GoldRate_tokenData[maxTS]
		GoldRate.tokenLastTS = maxTS
	end
	if (not GoldRate_options.nextTokenScanTS) then	-- set the nextTokenScanTime to +30 seconds if not set
		GoldRate_options.nextTokenScanTS = time() + 30
	end
	GoldRate.minScanPeriod = select(2, C_WowTokenPublic.GetCommerceSystemStatus() )
	GoldRate.Print( "v"..GOLDRATE_MSG_VERSION.." loaded." )
end
function GoldRate.PLAYER_MONEY()
	GoldRate_data[GoldRate.realm][GoldRate.faction].toons[GoldRate.name]["last"] = GetMoney()
	GoldRate_data[GoldRate.realm][GoldRate.faction].toons[GoldRate.name]["firstTS"] =
			GoldRate_data[GoldRate.realm][GoldRate.faction].toons[GoldRate.name]["firstTS"] or time()
	GoldRate_data[GoldRate.realm][GoldRate.faction].consolidated[time()] = GoldRate.otherSummed + GetMoney()

	GoldRate.ShowRate()
end
--GoldRate.PLAYER_ENTERING_WORLD = GoldRate.PLAYER_MONEY
function GoldRate.PLAYER_ENTERING_WORLD()
	if ( not GoldRate_data[GoldRate.realm][GoldRate.faction].toons[GoldRate.name]["last"] ) then
		GoldRate.PLAYER_MONEY()
	end
end
function GoldRate.PLAYER_LEAVING_WORLD()
	-- use this to filter out old data
	-- sort the keys
	local sortedKeys = {}
	local count = 0
	for ts in pairs( GoldRate_data[GoldRate.realm][GoldRate.faction].consolidated ) do
		table.insert( sortedKeys, ts )
		count = count + 1
	end
	table.sort( sortedKeys )
	GoldRate_data[GoldRate.realm][GoldRate.faction].numVals = count
	while count > GoldRate_options.maxDataPoints do
		key = table.remove( sortedKeys, 1 )
		GoldRate_data[GoldRate.realm][GoldRate.faction].consolidated[key] = nil
		count = count - 1
	end
end
function GoldRate.TOKEN_MARKET_PRICE_UPDATED()
	local val = C_WowTokenPublic.GetCurrentMarketPrice()
	local changeColor = COLOR_END
	if val then
		local now = time()
		local changePC, diff = 0, 0
		if (not GoldRate.tokenLast) or (GoldRate.tokenLast and GoldRate.tokenLast ~= val) then
			if GoldRate.tokenLast then
				diff = val - GoldRate.tokenLast
				changePC = (diff / GoldRate.tokenLast) * 100
				changeColor = (diff > 0) and COLOR_GREEN or COLOR_RED
			end
			GoldRate_tokenData[now] = val
			GoldRate.tokenLast = val
			GoldRate.tokenLastTS = now
			GoldRate.UpdateScanTime()

			GoldRate.tickerToken = string.format("TOK %i{circle}%+i(%+0.2f%%)",
					val/10000, diff/10000, changePC)

			UIErrorsFrame:AddMessage( GoldRate.tickerToken, 1.0, 1.0, 0.1, 1.0 )
			GoldRate.Print(GoldRate.tickerToken, false)
			GoldRate.GuildPrint(GoldRate.tickerToken)
		end
	end
end
function GoldRate.OnUpdate( arg1 )
	if ( GoldRate_options.nextTokenScanTS and GoldRate_options.nextTokenScanTS <= time() ) then
		C_WowTokenPublic.UpdateMarketPrice()
		GoldRate.UpdateScanTime()
	end
end
function GoldRate.UpdateScanTime()
	GoldRate_options.nextTokenScanTS = time() + 20*60  -- 20 minutes
end
--------------
-- Non Event functions
--------------
function GoldRate.PairsByKeys( t, f )  -- This is an awesome function I found
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
function GoldRate.GetDiffString( startVal, endVal )
	local diff = endVal - startVal
	local changePC = (diff / startVal) * 100
	local changeColor = (diff < 0) and COLOR_RED or COLOR_GREEN
	return string.format( "%s%+i (%0.2f%%)%s", changeColor, diff/10000, changePC, COLOR_END )
end
function GoldRate.TokenInfo( msg )
	print("TokenInfo: "..msg)
	if (msg and string.len(msg) > 0) then
	--	dayStart = date("*t")
	--	dayStart.hour, dayStart.min, dayStart.sec = 0, 0, 0
	--	dayStart = time(dayStart)
		local displayDay, startDay, startVal, endVal, minVal, maxVal = 0, 0, 0, 0, 0, 0
		local allMin, allMax = 0, 0
		local todayOut = {}
		local detailCutoffTS = time() - (12 * 3600) -- 12 hours ago
		for ts, val in GoldRate.PairsByKeys( GoldRate_tokenData ) do
			curDayTable = date("*t", ts)
			if displayDay ~= curDayTable.yday then  -- day changed
				if startDay > 0 then
					GoldRate.Print( string.format( "%s :: %s - %s %s",
									date("%x", startDay),
									GetCoinTextureString(minVal),
									GetCoinTextureString(maxVal),
									GoldRate.GetDiffString( startVal, endVal ) )
					)
				end
				startDay = ts
				startVal = val
				curDayTable = date("*t", ts)
				displayDay = curDayTable.yday
				minVal = val
				maxVal = val
			end
			minVal = min(minVal, val)
			maxVal = max(maxVal, val)
			if (ts > detailCutoffTS) then  -- only capture data within the detailCutoff time window
				tinsert( todayOut, string.format( "%s :: %s %s H%i L%i",
												date("%X", ts),
												GetCoinTextureString(val),
												GoldRate.GetDiffString( endVal, val ),
												maxVal/10000,
												minVal/10000 )
				)
			end
			endVal = val
		end
		for _,v in ipairs(todayOut) do
			GoldRate.Print(v, false)
		end
	end
	GoldRate.Print( string.format( "Token Price %s at %s", GetCoinTextureString( GoldRate.tokenLast ), date("%x %X", GoldRate.tokenLastTS) ) )
end
function GoldRate.RateSimple()
	-- returns rate/second, seconds till threshold
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
	local startGold = GoldRate_data[GoldRate.realm][GoldRate.faction].consolidated[sortedKeys[1]]
	local newestTS = sortedKeys[#sortedKeys]
	local endGold = GoldRate_data[GoldRate.realm][GoldRate.faction].consolidated[newestTS]
	local timeDiff = newestTS - GoldRate.maxInitialTS

	local goldDiff = endGold - startGold
	local rate = goldDiff / timeDiff
	--GoldRate.Print( "Gold Needed: "..GetCoinTextureString(xndGold or 0) ) )
	local targetTS = (GoldRate_data[GoldRate.realm][GoldRate.faction].goal and
			(time() + ((GoldRate_data[GoldRate.realm][GoldRate.faction].goal - endGold) / rate)) or 0)

	return rate, targetTS
end
function GoldRate.Rate()
	-- returns rate/second (slope), seconds till threshold
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
	--GoldRate.Print(count.." data points.")
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
			end
	    end
	    local m = xySum / x2Sum

	    -- Step 3 -- Calculate the y-intercept.  b = Yave - ( m * xAve )
	    --local b = (tsAve + GoldRate.maxInitialTS) - ( m * goldAve )
	    local b = goldAve  - ( m * tsAve )

	    -- Final Step -- Use the data to solve for TS at Gold Value
	    -- x = ( y - b ) / m
	    local targetTS = GoldRate_data[GoldRate.realm][GoldRate.faction].goal and (( GoldRate_data[GoldRate.realm][GoldRate.faction].goal - b ) / m ) or 0

	    --GoldRate.Print( "targetTS: "..date("%m/%d/%Y",targetTS) )

		return m, targetTS
	end
	return 0, 0
end
function GoldRate.ShowRate()
	local r, targetTS = GoldRate.Rate()
	local rs, targetTSs = GoldRate.RateSimple()
	local totalGoldNow = GoldRate.otherSummed + GetMoney()

	GoldRate.tickerGold = string.format("GOL %s%s",
			GetCoinTextureString( totalGoldNow ),
			((GoldRate_data[GoldRate.realm][GoldRate.faction].goal and GoldRate_data[GoldRate.realm][GoldRate.faction].goal > totalGoldNow)
				and " -> "..GetCoinTextureString( GoldRate_data[GoldRate.realm][GoldRate.faction].goal ) or "" )
	)

	GoldRate.Print( GoldRate.tickerGold )

	if (GoldRate_data[GoldRate.realm][GoldRate.faction].goal and
			GoldRate_data[GoldRate.realm][GoldRate.faction].goal > totalGoldNow) then
		GoldRate.Print( string.format( "%s (%0.2f) // %s (%0.2f)",
				(date("%c", targetTSs) or "nil"), rs, (date("%c", targetTS) or "nil"), r ), false )
	end

	--GoldRate.Print( GetCoinTextureString( gGained ).." gained since "..date("%x %X", GoldRate.maxInitialTS).." at a rate of "..r.." g/sec ")
end
function GoldRate.SetGoal( value )
	if (value and GoldRate.tokenLast and value == 'token') then
		value = GoldRate.tokenLast
	end
	GoldRate_data[GoldRate.realm][GoldRate.faction].goal = GoldRate.SumGoldValue( value, GoldRate_data[GoldRate.realm][GoldRate.faction].goal )

	if GoldRate_data[GoldRate.realm][GoldRate.faction].goal and GoldRate_data[GoldRate.realm][GoldRate.faction].goal <= 0 then
		GoldRate_data[GoldRate.realm][GoldRate.faction].goal = nil
	end
	GoldRate.Print( "Goal set to: "..
			(GoldRate_data[GoldRate.realm][GoldRate.faction].goal
				and GetCoinTextureString( GoldRate_data[GoldRate.realm][GoldRate.faction].goal )
				or "0" )
	)
	GoldRate.PLAYER_MONEY()
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
		["help"] = {"<amount | 'token'>","Set the goal, or the amount of the token."}
	},
	["token"] = {
		["func"] = GoldRate.TokenInfo,
		["help"] = {"<history>","Display info on the wowToken, or optionally the history."}
	},
}
