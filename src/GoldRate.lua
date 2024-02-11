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

-- GoldRate.days = {1, 30, 60, 90, 120, 150, 180, 270, 360 }
-- GoldRate.daysText = {"High", "Low", "30DH", "30DL", "60DH", "60DL",
-- 		"90DH", "90DL", "120DH", "120DL", "150DH", "150DL",
-- 		"180DH", "180DL", "270DH", "270DL", "360DH", "360DL" }

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
	if GoldRate.pruneThread and coroutine.status( GoldRate.pruneThread ) ~= "dead" then
		coroutine.resume( GoldRate.pruneThread )
	end
end
-- 	local changeColor = COLOR_END
-- 	if val then
-- 		local now = time()
-- 		local changePC, diff = 0, 0
-- 		if (not GoldRate.tokenLast) or (GoldRate.tokenLast and GoldRate.tokenLast ~= val) then
-- 			-- if no previous data, or the value has changed
-- 			if GoldRate.tokenLast then
-- 				diff = val - GoldRate.tokenLast
-- 				changePC = (diff / GoldRate.tokenLast) * 100
-- 				changeColor = (diff > 0) and COLOR_GREEN or COLOR_RED
-- 			end
-- 			GoldRate_tokenData[now] = val
-- 			GoldRate.tokenLast = val
-- 			GoldRate.tokenLastTS = now
-- 			GoldRate.UpdateScanTime()
-- 			limits = {GoldRate.GetHighLow()}

-- 			local minAbs
-- 			for k=3,(#GoldRate.days * 2) do  -- 3 -> #days * 2
-- 				local testAbs = abs(limits[k]-val)
-- 				minAbs = minAbs and min(testAbs,minAbs) or testAbs
-- 				if minAbs == testAbs then minIndex = k end
-- 			end

-- 			--print("Found min diff ("..minAbs..") at index: "..minIndex.." "..GoldRate.daysText[minIndex]..limits[minIndex]/10000)

-- 			GoldRate.tickerToken = string.format( "TOK %i{circle}%+i :: 24H%i 24L%i %s%i",
-- 					math.floor( val/10000 ), math.floor( (diff/10000)+0.5 ), math.floor( limits[1]/10000 ),
-- 					math.floor( limits[2]/10000 ), GoldRate.daysText[minIndex], math.floor( limits[minIndex]/10000 ) )

-- 			local uiDisplay = string.format( "TOK 24L%i / %i(%+i) %s%i / 24H%i ",
-- 					math.floor( limits[2]/10000 ),  -- 24H low
-- 					math.floor( val/10000 ), -- current
-- 					math.floor( ( diff/10000 ) + 0.5 ),  -- diff
-- 					GoldRate.daysText[minIndex],  -- closest range
-- 					math.floor( limits[minIndex]/10000 ), -- yaya
-- 					math.floor( limits[1]/10000 )  -- 24H high
-- 			)

-- 			UIErrorsFrame:AddMessage( GoldRate.tickerToken, 1.0, 1.0, 0.1, 1.0 )
-- 			GoldRate.Print(GoldRate.tickerToken, false)
-- 			GoldRate.GuildPrint(GoldRate.tickerToken)
-- 			GoldRateUI.Show( math.floor( limits[2]/10000 ), -- min
-- 					math.floor( val/10000 ),  -- value
-- 					math.floor( limits[1]/10000 ), --  max
-- 					uiDisplay  -- display for the UI
-- 			)
-- 		end
-- 	end
-- end


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
-- 	count = 0
-- 	local prevVal = 0
-- 	for ts, val in GoldRate.PairsByKeys( GoldRate_tokenData ) do
-- 		diff = val - prevVal
-- 		if (count > 0 and diff == 0) then
-- 			GoldRate_tokenData[ts] = nil
-- 		end
-- 		count = count + 1
-- 		prevVal = val
-- 	end
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
-- function GoldRate.GetHighLow()
-- 	-- return the high, low pairs for the number of days in cutoffTSs
-- 	local cutoffTSs = {}
-- 	for k in pairs( GoldRate.days ) do cutoffTSs[k] = time() - (GoldRate.days[k] * 86400) end
-- 	local limits = {}

-- 	for ts, val in pairs( GoldRate_tokenData ) do
-- 		for i, cutoffTS in pairs( cutoffTSs ) do
-- 			--print("i:"..i.." >i:"..(((i-1)*2)+1).." >i+1:"..(((i-1)*2)+2))
-- 			if ts >= cutoffTS then
-- 				local k = ((i-1)*2)+1  -- convert to a new index scheme.  1 based, odd is max, even is min
-- 				limits[k] = limits[k] and max(limits[k], val) or val
-- 				limits[k+1] = limits[k+1] and min(limits[k+1], val) or val
-- 			end
-- 		end
-- 	end
-- 	return unpack(limits)
-- end
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
-- function GoldRate.RateLastN( N )
-- 	-- returns rate/second, secnds till threshold
-- 	-- calculate the rate based on the last N samples
-- 	N = N or 100
-- 	fdata = GoldRate_data[GoldRate.realm][GoldRate.faction]
-- 	local sortedKeys = {}
-- 	for ts in pairs( fdata.consolidated ) do
-- 		table.insert( sortedKeys, ts )
-- 	end
-- 	table.sort( sortedKeys )
-- 	--print( "SortedSize: "..#sortedKeys )
-- 	N = math.min( N, #sortedKeys-1 )
-- 	--print( "N: "..N )
-- 	local lowTS = sortedKeys[ #sortedKeys - N ]
-- 	--print( "lowTS: "..lowTS )

-- 	local highTS = sortedKeys[ #sortedKeys ]
-- 	local startGold = fdata.consolidated[ lowTS ]
-- 	local endGold = fdata.consolidated[ highTS ]
-- 	local timeDiff = highTS - lowTS
-- 	local goldDiff = endGold - startGold
-- 	local rate = goldDiff / timeDiff
-- 	local targetTS = ( fdata.goal and
-- 			(time() + ((fdata.goal - endGold) / rate)) or 0)

-- 	--return 0, 0
-- 	return rate, targetTS

-- end
-- function GoldRate.RateSimple()
-- 	-- returns rate/second, seconds till threshold
-- 	-- this simply uses the first and last data elements to calculate a line for prediction (uber simple)
-- 	fdata = GoldRate_data[GoldRate.realm][GoldRate.faction]
-- 	GoldRate.maxInitialTS = 0
-- 	for name, pdata in pairs( fdata.toons ) do
-- 		GoldRate.maxInitialTS = math.min( GoldRate.maxInitialTS, pdata.firstTS )
-- 	end
-- 	local sortedKeys = {}
-- 	for ts in pairs( GoldRate_data[GoldRate.realm][GoldRate.faction].consolidated ) do
-- 		if ts >= GoldRate.maxInitialTS then -- filter data based on most recently added toon.
-- 			table.insert( sortedKeys, ts )
-- 		end
-- 	end
-- 	table.sort( sortedKeys )
-- 	local startGold = GoldRate_data[GoldRate.realm][GoldRate.faction].consolidated[sortedKeys[1]]
-- 	local newestTS = sortedKeys[#sortedKeys]
-- 	local endGold = GoldRate_data[GoldRate.realm][GoldRate.faction].consolidated[newestTS]
-- 	local timeDiff = newestTS - GoldRate.maxInitialTS

-- 	local goldDiff = endGold - startGold
-- 	local rate = goldDiff / timeDiff
-- 	--GoldRate.Print( "Gold Needed: "..GetCoinTextureString(xndGold or 0) ) )
-- 	local targetTS = (GoldRate_data[GoldRate.realm][GoldRate.faction].goal and
-- 			(time() + ((GoldRate_data[GoldRate.realm][GoldRate.faction].goal - endGold) / rate)) or 0)

-- 	return rate, targetTS
-- end
-- function GoldRate.Rate()
-- 	-- returns rate/second (slope), seconds till threshold
-- 	-- this uses the least squares method to define the following equation for the data set.
-- 	-- y = mx + b

-- 	-- Step 0 - find the maxInitialTS to filter data
-- 	GoldRate.maxInitialTS = 0
-- 	for name, pdata in pairs( GoldRate_data[GoldRate.realm][GoldRate.faction].toons ) do
-- 		GoldRate.maxInitialTS = math.min( GoldRate.maxInitialTS, pdata.firstTS )
-- 	end

-- 	-- Step 1 - Calculate the mean for both the x (timestamp) and y (gold) values
-- 	local count, tsSum, goldSum = 0, 0, 0
-- 	for ts, gold in pairs(GoldRate_data[GoldRate.realm][GoldRate.faction].consolidated) do
-- 		if ts >= GoldRate.maxInitialTS then  -- only compute if the data fits the TS range
-- 			--tsSum = tsSum + (ts - GoldRate.maxInitialTS)
-- 			tsSum = tsSum + ts
-- 			goldSum = goldSum + gold
-- 			count = count + 1
-- 		end
-- 	end
-- 	--GoldRate.Print(count.." data points.")
-- 	if count > 1 then
-- 		local tsAve = tsSum / count
-- 		local goldAve = goldSum / count

-- 		-- Step 2 -- m (slope) = sum( (Xi - Xave) * (Yi - Yave) )
-- 	    --                       --------------------------------
-- 	    --                       sum( (Xi - Xave)^2 )
-- 	    local xySum, x2Sum = 0, 0
-- 	    for ts, gold in pairs(GoldRate_data[GoldRate.realm][GoldRate.faction].consolidated) do -- yes, 2nd loop through data
-- 	    	if ts >= GoldRate.maxInitialTS then  -- only compute if the data fits the TS range
-- 				--xySum = xySum + ((ts - GoldRate.maxInitialTS) - tsAve) * (gold - goldAve)
-- 				--x2Sum = x2Sum + math.pow((ts - GoldRate.maxInitialTS) - tsAve, 2)
-- 				xySum = xySum + (ts - tsAve) * (gold - goldAve)
-- 				x2Sum = x2Sum + math.pow(ts - tsAve, 2)
-- 			end
-- 	    end
-- 	    local m = xySum / x2Sum

-- 	    -- Step 3 -- Calculate the y-intercept.  b = Yave - ( m * xAve )
-- 	    --local b = (tsAve + GoldRate.maxInitialTS) - ( m * goldAve )
-- 	    local b = goldAve  - ( m * tsAve )

-- 	    -- Final Step -- Use the data to solve for TS at Gold Value
-- 	    -- x = ( y - b ) / m
-- 	    local targetTS = GoldRate_data[GoldRate.realm][GoldRate.faction].goal and (( GoldRate_data[GoldRate.realm][GoldRate.faction].goal - b ) / m ) or 0

-- 	    --GoldRate.Print( "targetTS: "..date("%m/%d/%Y",targetTS) )

-- 		return m, targetTS
-- 	end
-- 	return 0, 0
-- end
-- function GoldRate.ShowRate()
-- 	-- show the ticker gold
-- 	local totalGoldNow = GoldRate.otherSummed + GetMoney()

-- 	GoldRate.tickerGold = string.format("GOL %s%s",
-- 			GetCoinTextureString( totalGoldNow ),
-- 			((GoldRate_data[GoldRate.realm][GoldRate.faction].goal and GoldRate_data[GoldRate.realm][GoldRate.faction].goal > totalGoldNow)
-- 				and " -> "..GetCoinTextureString( GoldRate_data[GoldRate.realm][GoldRate.faction].goal ) or "" )
-- 	)

-- 	GoldRate.Print( GoldRate.tickerGold )

-- 	-- figure out and display the rate and target time
-- 	if (GoldRate_data[GoldRate.realm][GoldRate.faction].goal and
-- 			GoldRate_data[GoldRate.realm][GoldRate.faction].goal > totalGoldNow) then

-- 		local methods = {
-- 				["last100"]   = { ["f"] = function() return GoldRate.RateLastN(100) end },
-- 				["last10"]    = { ["f"] = function() return GoldRate.RateLastN(10) end },
-- 				["last20"]    = { ["f"] = function() return GoldRate.RateLastN(20) end },
-- 				["firstLast"] = { ["f"] = GoldRate.RateSimple },
-- 				["squares"]   = { ["f"] = GoldRate.Rate },
-- 		}
-- 		local bestRate = {}
-- 		for k, a in pairs( methods ) do

-- 			local r, ts = a.f()
-- 			--print( ("%s r:%0.2f day: %s"):format( k, r, date( "%c", ts ) ) )
-- 			--[[
-- 			if( ts > time() ) then
-- 				print( ts.." is after now("..time()..")" )
-- 				if( bestRate.ts and ts < bestRate.ts ) then
-- 					print( ts.." is sooner than "..bestRate.ts )
-- 				end
-- 				if( not bestRate.ts ) then
-- 					print( "No data, store it." )
-- 				end
-- 			end
-- 			]]

-- 			if( ts > time() and   -- in the future
-- 					( ( bestRate.ts and ts < bestRate.ts ) or -- have a record, and ts is less than that record (closer in time)
-- 					( not bestRate.ts ) ) ) then  -- nothing stored
-- 				bestRate.ts = ts
-- 				bestRate.rate = r
-- 				bestRate.method = k
-- 				--print( "Storing "..k )
-- 			end
-- 		end
-- 		if( bestRate.ts ) then
-- 			GoldRate.Print( string.format( "Using %s: %s (%0.2f c/s)", bestRate.method, (date("%c", bestRate.ts) or "nil"), bestRate.rate ) )
-- 		else
-- 			GoldRate.Print( "No method returned a value in the future." )
-- 		end
-- 	end
-- 	--GoldRate.Print( GetCoinTextureString( gGained ).." gained since "..date("%x %X", GoldRate.maxInitialTS).." at a rate of "..r.." g/sec ")
-- end
-- function GoldRate.SetGoal( value )
-- 	if (value and GoldRate.tokenLast and value == 'token') then
-- 		value = GoldRate.tokenLast
-- 	end
-- 	GoldRate_data[GoldRate.realm][GoldRate.faction].goal = GoldRate.SumGoldValue( value, GoldRate_data[GoldRate.realm][GoldRate.faction].goal )

-- 	if GoldRate_data[GoldRate.realm][GoldRate.faction].goal and GoldRate_data[GoldRate.realm][GoldRate.faction].goal <= 0 then
-- 		GoldRate_data[GoldRate.realm][GoldRate.faction].goal = nil
-- 	end
-- 	GoldRate.Print( "Goal set to: "..
-- 			(GoldRate_data[GoldRate.realm][GoldRate.faction].goal
-- 				and GetCoinTextureString( GoldRate_data[GoldRate.realm][GoldRate.faction].goal )
-- 				or "0" )
-- 	)
-- 	GoldRate.PLAYER_MONEY()
-- end
-- function GoldRate.SumGoldValue( strIn, valueIn )
-- 	-- takes a string representing a gold (silver, copper) value, and an optional value, returns the value or sum of the 2.
-- 	-- strIn - string: string or interger value
-- 	-- valueIn - integer: optional integer to sum in
-- 	-- returns - interger: value in copper
-- 	local copperValue = 0
-- 	if strIn and strIn ~= "" then
-- 		sub = strfind( strIn, "^[-]" )
-- 		add = strfind( strIn, "^[+]" )
-- 		if tonumber(strIn) then
-- 			copperValue = tonumber(strIn)
-- 		else
-- 			local gold   = strmatch( strIn, "(%d+)g" )
-- 			local silver = strmatch( strIn, "(%d+)s" )
-- 			local copper = strmatch( strIn, "(%d+)c" )
-- 			copperValue = ((gold or 0) * 10000) + ((silver or 0) * 100) + (copper or 0)
-- 			if sub then copperValue = -copperValue end
-- 		end
-- 	else
-- 		return valueIn
-- 	end
-- 	return( valueIn and ((sub or add) and valueIn + copperValue) or tonumber(copperValue) )
-- end
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
