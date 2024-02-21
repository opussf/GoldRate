GOLDRATE_SLUG, GoldRate = ...
GOLDRATE_MSG_ADDONNAME  = GetAddOnMetadata( GOLDRATE_SLUG, "Title" )
GOLDRATE_MSG_VERSION    = GetAddOnMetadata( GOLDRATE_SLUG, "Version" )
GOLDRATE_MSG_AUTHOR     = GetAddOnMetadata( GOLDRATE_SLUG, "Author" )

-- Colours
COLOR_RED = "|cffff0000"
COLOR_GREEN = "|cff00ff00"
COLOR_BLUE = "|cff0000ff"
COLOR_PURPLE = "|cff700090"
COLOR_YELLOW = "|cffffff00"
COLOR_ORANGE = "|cffff6d00"
COLOR_GREY = "|cff808080"
COLOR_GOLD = "|cffcfb52b"
COLOR_NEON_BLUE = "|cff4d4dff"
COLOR_END = "|r"

GoldRate_data = {}
GoldRate_options = {
		['maxDataPoints'] = 1000,
		['nextTokenScanTS'] = 0,
		['ratePeriod'] = {['days']=30,},
		['smoothAgeDays'] = 30,
		['pruneAgeDays'] = 180,
}
GoldRate_tokenData = {} -- [timestamp] = value

GoldRate.days = {1, 30, 60, 90, 120, 150, 180, 270, 360 }
GoldRate.daysText = {"High", "Low", "30DH", "30DL", "60DH", "60DL",
		"90DH", "90DL", "120DH", "120DL", "150DH", "150DL",
		"180DH", "180DL", "270DH", "270DL", "360DH", "360DL" }

function GoldRate.Print( msg, showName)
	-- print to the chat frame
	-- set showName to false to suppress the addon name printing
	if (showName == nil) or (showName) then
		msg = COLOR_PURPLE..GOLDRATE_MSG_ADDONNAME.."> "..COLOR_END..msg
	end
	DEFAULT_CHAT_FRAME:AddMessage( msg )
end
-- function GoldRate.GuildPrint( msg )
-- 	if (IsInGuild()) then
-- 		guildName, guildRankName, guildRankIndex = GetGuildInfo("player")
-- 		local guildTest = GoldRate.realm.."-"..guildName
-- 		--GoldRate.Print( guildTest..": "..( GoldRate_options.guildBlackList[guildTest] and "True" or "nil" ) )
-- 		if not GoldRate_options.guildBlackList or not GoldRate_options.guildBlackList[guildTest] then
-- 			SendChatMessage( msg, "GUILD" )
-- 			return true
-- 		end
-- 	end
-- end
function GoldRate.OnLoad()
	SLASH_GOLDRATE1 = "/GR"
	SLASH_GOLDRATE2 = "/GoldRate"
	SlashCmdList["GOLDRATE"] = function(msg) GoldRate.Command(msg); end

	GoldRate_Frame:RegisterEvent("ADDON_LOADED")
	GoldRate_Frame:RegisterEvent("VARIABLES_LOADED")
	GoldRate_Frame:RegisterEvent("PLAYER_ENTERING_WORLD")
	GoldRate_Frame:RegisterEvent("PLAYER_MONEY")
	GoldRate_Frame:RegisterEvent("TOKEN_MARKET_PRICE_UPDATED")
	GoldRate_Frame:RegisterEvent("PLAYER_REGEN_DISABLED")
	GoldRate_Frame:RegisterEvent("PLAYER_REGEN_ENABLED")
end
--------------
-- Event Functions
--------------
function GoldRate.ADDON_LOADED()
	GoldRate_Frame:UnregisterEvent( "ADDON_LOADED" )

	-- Setup needed variables
	GoldRate.realm   = GetRealmName()
	GoldRate.faction = UnitFactionGroup( "player" )
	GoldRate.name    = UnitName( "player" )
	GoldRate.Print( "v"..GOLDRATE_MSG_VERSION.." loaded." )
end
function GoldRate.VARIABLES_LOADED( arg1, arg2 )
	GoldRate_Frame:UnregisterEvent( "VARIABLES_LOADED" )
	GoldRate_data[GoldRate.realm] = GoldRate_data[GoldRate.realm] or {}
	GoldRate_data[GoldRate.realm][GoldRate.faction] = GoldRate_data[GoldRate.realm][GoldRate.faction] or {}
	GoldRate_data[GoldRate.realm][GoldRate.faction].consolidated = GoldRate_data[GoldRate.realm][GoldRate.faction].consolidated or {}
	GoldRate_data[GoldRate.realm][GoldRate.faction].toons = GoldRate_data[GoldRate.realm][GoldRate.faction].toons or {}
	GoldRate_data[GoldRate.realm][GoldRate.faction].toons[GoldRate.name] = GoldRate_data[GoldRate.realm][GoldRate.faction].toons[GoldRate.name] or {}
	GoldRate.myGold = GoldRate_data[GoldRate.realm][GoldRate.faction].toons[GoldRate.name]
	GoldRate.otherSummed = 0
	for toonName, toonData in pairs( GoldRate_data[GoldRate.realm][GoldRate.faction].toons ) do
		GoldRate.otherSummed = GoldRate.otherSummed + (toonName == GoldRate.name and 0 or toonData.last)
	end
	GoldRate.SetTokenTSs()
	if (not GoldRate_options.nextTokenScanTS) then	-- set the nextTokenScanTime to +30 seconds if not set
		GoldRate_options.nextTokenScanTS = time() + 30
	end
	GoldRate.minScanPeriod = select(2, C_WowTokenPublic.GetCommerceSystemStatus() )
end
function GoldRate.PLAYER_MONEY()
	GoldRate.myGold.last = GetMoney()
	GoldRate.myGold.firstTS = GoldRate.myGold.firstTS or time()
	GoldRate_data[GoldRate.realm][GoldRate.faction].consolidated[time()] = GoldRate.otherSummed + GetMoney()
end
function GoldRate.PLAYER_ENTERING_WORLD()
	GoldRate.PLAYER_MONEY()
	GoldRate.pruneThread = coroutine.create( GoldRate.PruneData )
	GoldRate.SetTokenTSs()
	if not GoldRate.tokenText and #GoldRate.tokenTSs > 0 then
		GoldRate.makeTokenText()
	end

-- 	if not GoldRate.goldShown then
-- 		local totalGoldNow = GoldRate.otherSummed + GetMoney()
-- 		GoldRateUI.Show( 0, totalGoldNow/10000, GoldRate.tokenLast/10000, "Total Gold: "..math.floor(totalGoldNow/10000).." Token: "..GoldRate.tokenLast/10000 )
-- 		GoldRate.goldShown = true
--	end
end
function GoldRate.TOKEN_MARKET_PRICE_UPDATED()
	local val = C_WowTokenPublic.GetCurrentMarketPrice()
	if val then
		local now = time()
		if val ~= GoldRate_tokenData[GoldRate.tokenTSs[#GoldRate.tokenTSs]] then
			GoldRate_tokenData[now] = val
			table.insert( GoldRate.tokenTSs, now )
			GoldRate.UpdateScanTime()
			GoldRate.needToRebuildTicker = true
			GoldRate.tickerToken = string.format( "TOK %i{circle}", math.floor(val/10000) )
			UIErrorsFrame:AddMessage( GoldRate.tickerToken, 1.0, 1.0, 0.1, 1.0 )
		end
	end
end
function GoldRate.PLAYER_REGEN_DISABLED()
	GoldRate.inCombat = true
end
function GoldRate.PLAYER_REGEN_ENABLED()
	GoldRate.inCombat = nil
end
function GoldRate.OnUpdate( arg1 )
	if ( GoldRate_options.nextTokenScanTS and GoldRate_options.nextTokenScanTS <= time() ) then
		C_WowTokenPublic.UpdateMarketPrice()
		GoldRate.UpdateScanTime()
	end
	if ( not GoldRate.inCombat and GoldRate.needToRebuildTicker ) then
		GoldRate.makeTokenText()
	end
	if GoldRate.pruneThread and coroutine.status( GoldRate.pruneThread ) ~= "dead" then
		coroutine.resume( GoldRate.pruneThread )
	end
end
function GoldRate.makeTokenText()
	local currentValue = GoldRate_tokenData[GoldRate.tokenTSs[#GoldRate.tokenTSs]]
	local diff = ( #GoldRate.tokenTSs > 1 ) and currentValue - GoldRate_tokenData[GoldRate.tokenTSs[#GoldRate.tokenTSs-1]] or 0
	limits = {GoldRate.GetHighLow()}

	local minAbs, minIndex
	for k=3,(#GoldRate.days * 2) do   -- 3 -> #days * 2
		local testAbs = abs(limits[k]-currentValue)
		minAbs = minAbs and min(testAbs,minAbs) or testAbs
		if minAbs == testAbs then minIndex = k end
	end

	GoldRate.tokenText = string.format( "TOK 24L%i / %i(%+i) %s%i / 24H%i",
			math.floor( limits[2]/10000 ),         -- 24H low
			math.floor( currentValue/10000 ),
			math.floor( ( diff/10000 ) + 0.5 ),    -- diff
			GoldRate.daysText[minIndex],           -- closest range
			math.floor( limits[minIndex]/10000 ),  -- the value of the closest
			math.floor( limits[1]/10000 )          -- 24H high
	)

-- 			GoldRate.Print(GoldRate.tickerToken, false)
-- 			GoldRate.GuildPrint(GoldRate.tickerToken)

	GoldRate.UIShow( math.floor( limits[2]/10000 ), -- min
			math.floor( currentValue/10000 ),  -- value
			math.floor( limits[1]/10000 ), --  max
			GoldRate.tokenText  -- display for the UI
	)
end

------------
-- Support
------------
function GoldRate.UpdateScanTime()
	GoldRate_options.nextTokenScanTS = time() + 20*60  -- 20 minutes
end
function GoldRate.SetTokenTSs()
	GoldRate.tokenTSs = {}
	for ts in pairs( GoldRate_tokenData ) do table.insert( GoldRate.tokenTSs, ts ) end
	table.sort( GoldRate.tokenTSs )
end
function GoldRate.PruneData()
	GoldRate.Print("PruneData")
--
	local smoothAgeDays = GoldRate_options.smoothAgeDays or 30
	local pruneAgeDays = GoldRate_options.pruneAgeDays or 180
	smoothCutoff = time() - (86400 * smoothAgeDays)
	pruneCutoff = time() - (86400 * pruneAgeDays)

	for pruneRealm, realmStruct in pairs( GoldRate_data ) do
		for pruneFaction, factionStruct in pairs( realmStruct ) do
			-- print( "STARTING: "..pruneRealm.."-"..pruneFaction )
			-- sort the keys into sortedKeys and count data points older than GoldRate_options.pruneAgeDays
			local sortedKeys = {}
			local count, smoothCount, pruneCount = 0, 0, 0  -- count is total size, smoothCount is > smoothAgeDays, pruneCount is > pruneAgeDays

			-- count all data points, prune old data.
			for ts in pairs( GoldRate_data[pruneRealm][pruneFaction].consolidated ) do
				table.insert( sortedKeys, ts )
				count = count + 1
				if ts < smoothCutoff then
					if ts < pruneCutoff then
						pruneCount = pruneCount + 1
						GoldRate_data[pruneRealm][pruneFaction].consolidated[ts] = nil
					else
						smoothCount = smoothCount + 1
					end
				end
			end
			-- yield here
			coroutine.yield()

			-- GoldRate.Print(count.." data points. "..pruneCount.." expired (older than "..pruneAgeDays.." days).")
			-- GoldRate.Print(smoothCount.." data points are older than "..smoothAgeDays.." days.")
			table.sort( sortedKeys )
			GoldRate_data[pruneRealm][pruneFaction].numVals = count  -- This is going to be wrong.  meh

			local smoothDelCount = 0
			local previousVal = nil -- set this to the previous val
			local previousTS = nil
			local valueDirection = nil -- set this to +1, or -1 based on the direction of data
			for _,ts in pairs( sortedKeys ) do
				if ts < smoothCutoff then
					local currentValue = GoldRate_data[pruneRealm][pruneFaction].consolidated[ts]
					if previousVal then -- knew about a previous data point
						if ((valueDirection == 1) and (currentValue > previousVal)) or
						   ((valueDirection == -1) and (currentValue < previousVal)) then -- contiune in the previous direction
							--print("Removing "..currentValue.." at "..ts)
							GoldRate_data[pruneRealm][pruneFaction].consolidated[previousTS] = nil
							--GoldRate_data[GoldRate.realm][GoldRate.faction].consolidated[ts] = nil
							smoothDelCount = smoothDelCount + 1
						end
						valueDirection = (currentValue < previousVal) and -1 or 1  -- default to 1 sort of thing
					end
					previousVal = currentValue
					previousTS = ts
				end
			end

			colorStart = ((pruneRealm == GoldRate.realm and pruneFaction == GoldRate.faction ) and COLOR_GREEN or nil )
			colorEnd = (colorStart and COLOR_END or nil )
			if (colorEnd or pruneCount > 0 or smoothDelCount > 0) then
				GoldRate.Print( string.format( "%d / %d points >%d days, %d expired, %d smoothed for %s%s-%s%s",
						smoothCount, count, smoothAgeDays, pruneCount, smoothDelCount,
						(colorStart or ""),	pruneRealm, pruneFaction, (colorEnd or "") ) )
			end
			coroutine.yield()
		end
	end

	-- TokenData
	-- Only remove token values where they have not changed
	-- Probably from duplicate values being imported
	-- @TODO: Since I only look at the last year of data, does older data need to be expired?
	count = 0
	local prevVal = 0
	for ts, val in GoldRate.PairsByKeys( GoldRate_tokenData ) do
		diff = val - prevVal
		if (count > 0 and diff == 0) then
			GoldRate_tokenData[ts] = nil
		end
		count = count + 1
		prevVal = val
	end
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
function GoldRate.GetHighLow()
	-- return the high, low pairs for the number of days in cutoffTSs
	local cutoffTSs = {}
	for k in pairs( GoldRate.days ) do cutoffTSs[k] = time() - (GoldRate.days[k] * 86400) end
	local limits = {}

	for ts, val in pairs( GoldRate_tokenData ) do
		for i, cutoffTS in pairs( cutoffTSs ) do
			-- print("i:"..i.." >i:"..(((i-1)*2)+1).." >i+1:"..(((i-1)*2)+2))
			if ts >= cutoffTS then
				local k = ((i-1)*2)+1  -- convert to a new index scheme.  1 based, odd is max, even is min
				limits[k] = limits[k] and max(limits[k], val) or val
				limits[k+1] = limits[k+1] and min(limits[k+1], val) or val
			end
		end
	end
	return unpack(limits)
end
-- function GoldRate.GetDiffString( startVal, endVal )
-- 	local diff = endVal - startVal
-- 	local changePC = (diff / startVal) * 100
-- 	local changeColor = (diff < 0) and COLOR_RED or COLOR_GREEN
-- 	return string.format( "%s%+i (%0.2f%%)%s", changeColor, diff/10000, changePC, COLOR_END )
-- end
-- function GoldRate.TokenInfo( msg )
-- 	print("TokenInfo: "..msg)
-- 	if (msg and string.len(msg) > 0) then
-- 	--	dayStart = date("*t")
-- 	--	dayStart.hour, dayStart.min, dayStart.sec = 0, 0, 0
-- 	--	dayStart = time(dayStart)
-- 		local displayDay, startDay, startVal, endVal, minVal, maxVal = 0, 0, 0, 0, 0, 0
-- 		local allMin, allMax = 0, 0
-- 		local todayOut = {}
-- 		local detailCutoffTS = time() - (12 * 3600) -- 12 hours ago
-- 		for ts, val in GoldRate.PairsByKeys( GoldRate_tokenData ) do
-- 			curDayTable = date("*t", ts)
-- 			if displayDay ~= curDayTable.yday then  -- day changed
-- 				if startDay > 0 then
-- 					GoldRate.Print( string.format( "%s :: %s - %s %s",
-- 									date("%x", startDay),
-- 									GetCoinTextureString(minVal),
-- 									GetCoinTextureString(maxVal),
-- 									GoldRate.GetDiffString( startVal, endVal ) ),
-- 							false
-- 					)
-- 				end
-- 				startDay = ts
-- 				startVal = val
-- 				curDayTable = date("*t", ts)
-- 				displayDay = curDayTable.yday
-- 				minVal = val
-- 				maxVal = val
-- 			end
-- 			minVal = min(minVal, val)
-- 			maxVal = max(maxVal, val)
-- 			if (ts > detailCutoffTS) then  -- only capture data within the detailCutoff time window
-- 				tinsert( todayOut, string.format( "%s :: %s %s H%i L%i",
-- 												date("%X", ts),
-- 												GetCoinTextureString(val),
-- 												GoldRate.GetDiffString( endVal, val ),
-- 												maxVal/10000,
-- 												minVal/10000 )
-- 				)
-- 			end
-- 			endVal = val
-- 		end
-- 		for _,v in ipairs(todayOut) do
-- 			GoldRate.Print(v, false)
-- 		end
-- 	end
-- 	GoldRate.Print( string.format( "Token Price %s at %s", GetCoinTextureString( GoldRate.tokenLast ), date("%x %X", GoldRate.tokenLastTS) ) )
-- end
-- function GoldRate.Ra-- end
-- function GoldRate.GuildToggle()
-- 	if not GoldRate_options.guildBlackList then
-- 		--print("No guildBlackList. setting as empty.")
-- 		GoldRate_options.guildBlackList = {}
-- 	end
-- 	if (IsInGuild()) then
-- 		guildName = GetGuildInfo("player")
-- 		local guildTest = GoldRate.realm.."-"..guildName
-- 		if GoldRate_options.guildBlackList[guildTest] then
-- 			GoldRate_options.guildBlackList[guildTest] = nil
-- 			GoldRate.Print( "Will now post to "..guildTest )
-- 		else
-- 			GoldRate_options.guildBlackList[guildTest] = true
-- 			GoldRate.Print( guildTest.." is now excluded." )
-- 		end
-- 	else
-- 		GoldRate.Print( "No guild to toggle.")
-- 	end
-- end
-- function GoldRate.ParseCmd(msg)
-- 	if msg then
-- 		local i,c = strmatch(msg, "^(|c.*|r)%s*(%d*)$")
-- 		if i then  -- i is an item, c is a count or nil
-- 			return i, c
-- 		else  -- Not a valid item link
-- 			msg = string.lower(msg)
-- 			local a,b,c = strfind(msg, "(%S+)")  --contiguous string of non-space characters
-- 			if a then
-- 				-- c is the matched string, strsub is everything after that, skipping the space
-- 				return c, strsub(msg, b+2)
-- 			else
-- 				return ""
-- 			end
-- 		end
-- 	end
-- end
function GoldRate.Command(msg)
-- 	local cmd, param = GoldRate.ParseCmd(msg);
-- 	if GoldRate.CommandList[cmd] and GoldRate.CommandList[cmd].alias then
-- 		cmd = GoldRate.CommandList[cmd].alias
-- 	end
-- 	local cmdFunc = GoldRate.CommandList[cmd];
-- 	if cmdFunc then
-- 		cmdFunc.func(param);
-- 	else
-- 		GoldRate.PrintHelp()
-- 	end
end
-- function GoldRate.PrintHelp()
-- 	GoldRate.Print( string.format( "%s (%s) by %s", GOLDRATE_MSG_ADDONNAME, GOLDRATE_MSG_VERSION, GOLDRATE_MSG_AUTHOR ) )
-- 	for cmd, info in pairs(GoldRate.CommandList) do
-- 		if info.help then
-- 			local cmdStr = cmd
-- 			for c2, i2 in pairs(GoldRate.CommandList) do
-- 				if i2.alias and i2.alias == cmd then
-- 					cmdStr = string.format( "%s / %s", cmdStr, c2 )
-- 				end
-- 			end
-- 			GoldRate.Print(string.format("%s %s %s -> %s",
-- 				SLASH_GOLDRATE1, cmdStr, info.help[1], info.help[2]));
-- 		end
-- 	end
-- end
-- -- this needs to be at the end because it is referencing functions
-- GoldRate.CommandList = {
-- 	["help"] = {
-- 		["func"] = GoldRate.PrintHelp,
-- 		["help"] = {"","Print this help."},
-- 	},
-- 	-- ["goal"] = {
-- 	-- 	["func"] = GoldRate.SetGoal,
-- 	-- 	["help"] = {"<amount | 'token'>","Set the goal, or the amount of the token."}
-- 	-- },
-- 	["token"] = {
-- 		["func"] = GoldRate.TokenInfo,
-- 		["help"] = {"<history>","Display info on the wowToken, or optionally the history."}
-- 	},
-- 	["guild"] = {
-- 		["func"] = GoldRate.GuildToggle,
-- 		["help"] = {"","Toggle reporting to the current guild."}
-- 	},
-- }
