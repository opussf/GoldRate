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
function GoldRate.Rate()
	-- returns rate/second, seconds till threshold, totalgained
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
function GoldRate.ShowRate()
	local r, targetTS, gGained = GoldRate.Rate()
	GoldRate.Print( "Total: "..GetCoinTextureString( GoldRate.otherSummed + GetMoney() ) ..
			(GoldRate_data[GoldRate.realm][GoldRate.faction].goal
				and " -> "..GetCoinTextureString( GoldRate_data[GoldRate.realm][GoldRate.faction].goal ).." @ "..(targetTS and date("%x %X", targetTS) or "unknown")
				or "")
	)
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
