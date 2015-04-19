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
	GoldRate.realm = GetRealmName()
	GoldRate.faction = UnitFactionGroup("player")
	GoldRate.name = UnitName("player")

	GoldRate_data[GoldRate.realm] = GoldRate_data[GoldRate.realm] or {}
	GoldRate_data[GoldRate.realm][GoldRate.faction] = GoldRate_data[GoldRate.realm][GoldRate.faction] or {}
	GoldRate_data[GoldRate.realm][GoldRate.faction].toons = GoldRate_data[GoldRate.realm][GoldRate.faction].toons or {}
	GoldRate_data[GoldRate.realm][GoldRate.faction].consolidated = GoldRate_data[GoldRate.realm][GoldRate.faction].consolidated or {}
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
end
GoldRate.PLAYER_ENTERING_WORLD = GoldRate.PLAYER_MONEY
--------------
-- Non Event functions
--------------
function GoldRate.parseCmd(msg)
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
	local cmd, param = GoldRate.parseCmd(msg);
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
}
