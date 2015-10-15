#!/usr/bin/env lua

addonData = { ["Version"] = "1.0",
}

require "wowTest"

test.outFileName = "testOut.xml"

-- Figure out how to parse the XML here, until then....
GoldRate_Frame = CreateFrame()
GoldRate_Display = CreateFrame()
--SendMailNameEditBox = CreateFontString("SendMailNameEditBox")

-- require the file to test
package.path = "../src/?.lua;'" .. package.path
require "GoldRate"
require "GoldRateUI"
--require "GoldRate_Offline"

-- addon setup
function test.before()
	GoldRate_data = {}
	GoldRate_tokenData = {}
	GoldRate.OnLoad()
	GoldRate.ADDON_LOADED()
	myCopper = 150000
end
function test.after()
end
function test.testCommand_Blank()
	-- These are here basicly to assure that the command does not error
	GoldRate.Command( "" )
end
function test.testCommand_Help()
	-- These are here basicly to assure that the command does not error
	GoldRate.Command( "help" )
end
function test.testCommand_Goal()
	-- These are here basicly to assure that the command does not error
	GoldRate.Command( "goal" )
end
function test.testCommand_MinGold()
	GoldRate.Command( "min" )
end
function test.testGoalInfo_NoParameter_WithNoValue()
	GoldRate.Command( "goal" )
	assertIsNil( GoldRate_data.testRealm.Alliance.goal )
end
function test.testGoalInfo_NoParameter_WithValue()
	GoldRate_data.testRealm.Alliance.goal = 100000
	GoldRate.Command( "goal" )
	assertEquals( 100000, GoldRate_data.testRealm.Alliance.goal )
end
function test.testGoalInfo_SetToZero()
	GoldRate_data.testRealm.Alliance.goal = 100000
	GoldRate.Command( "goal 0" )
	assertIsNil( GoldRate_data.testRealm.Alliance.goal )
end
function test.testGoalInfo_SetCopperValue()
	GoldRate.SetGoal( 100000 ) -- sets 10 gold
	assertEquals( 100000, GoldRate_data.testRealm.Alliance.goal )
end
function test.testGoalInfo_SetCopperValue_Reset()
	GoldRate.SetGoal( 100000 ) -- sets 10 gold
	GoldRate.SetGoal( 10000 )  -- sets 1 gold
	assertEquals( 10000, GoldRate_data.testRealm.Alliance.goal )
end
function test.testGoalInfo_SetStringValue_Gold()
	GoldRate.Command( "goal 20G" )
	assertEquals( 200000, GoldRate_data.testRealm.Alliance.goal )
end
function test.testGoalInfo_SetStringValue_Silver()
	GoldRate.Command( "goal 20S" )
	assertEquals( 2000, GoldRate_data.testRealm.Alliance.goal )
end
function test.testGoalInfo_SetStringValue_Copper()
	GoldRate.Command( "goal 20C" )
	assertEquals( 20, GoldRate_data.testRealm.Alliance.goal )
end
function test.testGoalInfo_SetStringValue_MixedValues01()
	GoldRate.Command( "goal 20G 20C" )
	assertEquals( 200020, GoldRate_data.testRealm.Alliance.goal )
end
function test.testGoalInfo_SetStringValue_MixedValues02()
	GoldRate.Command( "goal 20G20C" )
	assertEquals( 200020, GoldRate_data.testRealm.Alliance.goal )
end
function test.testGoalInfo_SetStringValue_MixedValues03()
	GoldRate.Command( "goal 20G20C15S" )
	assertEquals( 201520, GoldRate_data.testRealm.Alliance.goal )
end
function test.testGoalInfo_SetStringValue_MixedValues_UnexpectedRage()
	GoldRate.Command( "goal 20G20C100S" )
	assertEquals( 210020, GoldRate_data.testRealm.Alliance.goal )
end
function test.testGoalInfo_SetStringValue_MixedValues_inAllLower()
	GoldRate.Command( "goal 20g99s43c" )
	assertEquals( 209943, GoldRate_data.testRealm.Alliance.goal )
end
function test.testGoalInfo_AdditiveValue_Copper()
	GoldRate_data.testRealm.Alliance.goal = 10
	GoldRate.Command( "goal +20" )
	assertEquals( 30, GoldRate_data.testRealm.Alliance.goal )
end
function test.testGoalInfo_AdditiveString_Copper()
	GoldRate_data.testRealm.Alliance.goal = 10
	GoldRate.Command( "goal +20c" )
	assertEquals( 30, GoldRate_data.testRealm.Alliance.goal )
end
function test.testGoalInfo_AdditiveString_Silver()
	GoldRate_data.testRealm.Alliance.goal = 10
	GoldRate.Command( "goal +20s" )
	assertEquals( 2010, GoldRate_data.testRealm.Alliance.goal )
end
function test.testGoalInfo_AdditiveString_Gold()
	GoldRate_data.testRealm.Alliance.goal = 10
	GoldRate.Command( "goal +20g" )
	assertEquals( 200010, GoldRate_data.testRealm.Alliance.goal )
end
function test.testGoalInfo_AdditiveString_MixedValues01()
	GoldRate_data.testRealm.Alliance.goal = 10
	GoldRate.Command( "goal +15s16C20g" )
	assertEquals( 201526, GoldRate_data.testRealm.Alliance.goal )
end
function test.testGoalInfo_SubtractValue_Copper_01()
	GoldRate_data.testRealm.Alliance.goal = 30
	GoldRate.Command( "goal -20" )
	assertEquals( 10, GoldRate_data.testRealm.Alliance.goal )
end
function test.testGoalInfo_SubtractValue_Copper_02()
	GoldRate_data.testRealm.Alliance.goal = 30
	GoldRate.Command( "goal -20c" )
	assertEquals( 10, GoldRate_data.testRealm.Alliance.goal )
end
function test.testGoalInfo_SubtractValue_Copper_SubZero()
	GoldRate_data.testRealm.Alliance.goal = 30
	GoldRate.Command( "goal -90" )
	assertIsNil( GoldRate_data.testRealm.Alliance.goal )
end
function test.testMin_SetMin_NoParameter_WithNoValue()
	GoldRate.Command( "min" )
	assertIsNil( GoldRate_data.testRealm.Alliance.goal )
end

function test.testADDON_LOADED_setsOtherSummed_newToon()
	GoldRate_data.testRealm.Alliance.toons.otherPlayer = {["last"] = 70000, ["firstTS"] = 100} -- give the other player 7 gold
	GoldRate_data.testRealm.Alliance.consolidated = {[100]= 70000}
	GoldRate.ADDON_LOADED() -- force this again
	assertEquals( 70000, GoldRate.otherSummed )
end
function test.testADDON_LOADED_setsOtherSummed_revisit()
	GoldRate_data.testRealm.Alliance.toons.testPlayer = {["last"] = 80000 }  -- give me 8 gold
	GoldRate_data.testRealm.Alliance.toons.otherPlayer = {["last"] = 70000 } -- give the other player 7 gold
	GoldRate.ADDON_LOADED() -- force this again
	assertEquals( 70000, GoldRate.otherSummed )
end
function test.testCapture_SetsRealm()
	GoldRate.PLAYER_MONEY()
	assertTrue( GoldRate_data.testRealm )
end
function test.testCapture_SetsFaction()
	GoldRate.PLAYER_MONEY()
	assertTrue( GoldRate_data.testRealm.Alliance )
end
function test.testCapture_SetsToonsSection()
	GoldRate.PLAYER_MONEY()
	assertTrue( GoldRate_data.testRealm.Alliance.toons )
end
function test.testCapture_SetsName()
	GoldRate.PLAYER_MONEY()
	assertTrue( GoldRate_data.testRealm.Alliance.toons.testPlayer )
end
function test.testCapture_SetsConsolidatedDataSection()
	GoldRate.PLAYER_MONEY()
	assertTrue( GoldRate_data.testRealm.Alliance.consolidated )
end
function test.testCapture_SetsPlayersFirstCaptureTS_FirstSeen()
	local now = time()
	GoldRate.PLAYER_MONEY()
	assertEquals( now, GoldRate_data.testRealm.Alliance.toons.testPlayer["firstTS"] )
end
function test.testCapture_SetsPlayersFirstCaptureTS_notFirstSeen()
	local now = time()
	GoldRate_data.testRealm.Alliance.toons.testPlayer = {["firstTS"] = 200, ["last"] = 10000 }
	GoldRate_data.testRealm.Alliance.consolidated = { [200] = 10000 }
	GoldRate.PLAYER_MONEY()
	assertEquals( 200, GoldRate_data.testRealm.Alliance.toons.testPlayer["firstTS"] )
end
function test.testCapture_GoldAmount_PlayerMoney_Last()
	-- Assert that PLAYER_MONEY event takes a snapshot of the current toon's money amount
	GoldRate.PLAYER_MONEY()  -- Capture the amount
	assertEquals( 150000, GoldRate_data.testRealm.Alliance.toons.testPlayer["last"] )
end
function test.testCapture_GoldAmount_PlayerMoney_MultiToon()
	local now = time()
	assertTrue( GoldRate_data.testRealm.Alliance.toons )
	GoldRate_data.testRealm.Alliance.toons.otherPlayer = {["firstTS"] = 3276534, ["last"] = 70000} -- give the other player 7 gold
	GoldRate.ADDON_LOADED()
	GoldRate.PLAYER_MONEY()
	assertEquals( 220000, GoldRate_data.testRealm.Alliance.consolidated[now] )
end
function test.testCapture_GoldAmount_PlayerMoney_TimeStamp()
	-- Assert that PLAYER_MONEY event takes a snapshot of the current toon's money amount
	local now = time()
	GoldRate.PLAYER_MONEY()  -- Capture the amount
	assertEquals( 150000, GoldRate_data.testRealm.Alliance.consolidated[now] )
end
function test.testCapture_GoldAmount_PlayerMoney_SetsTicker_negative()
	local now = time()
	GoldRate.PLAYER_MONEY()  -- Capture the amount
	myCopper = 140000
	GoldRate.PLAYER_MONEY()  -- Capture the amount
	assertEquals( "GOL 14G 0S 0C", GoldRate.tickerGold )
end
function test.testCapture_GoldAmount_PlayerMoney_SetsTicker_noChange()
	local now = time()
	GoldRate.PLAYER_MONEY()  -- Capture the amount
	assertEquals( "GOL 15G 0S 0C", GoldRate.tickerGold )
end
function test.testCapture_GoldAmount_PlayerMoney_SetsTicker_positive()
	local now = time()
	GoldRate.PLAYER_MONEY()  -- Capture the amount
	myCopper = 160000
	GoldRate.PLAYER_MONEY()  -- Capture the amount
	assertEquals( "GOL 16G 0S 0C", GoldRate.tickerGold )
end

function test.testCapture_GoldAmount_EnteringWorld_Last_noData()
	-- Assert that PLAYER_MONEY event takes a snapshot of the current toon's money amount
	GoldRate.PLAYER_ENTERING_WORLD()  -- Capture the amount
	assertEquals( 150000, GoldRate_data.testRealm.Alliance.toons.testPlayer["last"] )
end
function test.testCapture_GoldAmount_EnteringWorld_TimeStamp_noData()
	-- Assert that PLAYER_MONEY event takes a snapshot of the current toon's money amount
	local now = time()
	GoldRate.PLAYER_ENTERING_WORLD()  -- Capture the amount
	assertEquals( 150000, GoldRate_data.testRealm.Alliance.consolidated[now] )
end
function test.testCapture_GoldAmount_EnteringWorld_Last_withData()
	-- Assert that PLAYER_MONEY event takes a snapshot of the current toon's money amount, unless previous data exists (no 0 entries becuase of startup)
	GoldRate_data.testRealm.Alliance.toons.testPlayer = {["firstTS"] = 3276534, ["last"] = 149999}  -- Has previous data
	GoldRate_data.testRealm.Alliance.consolidated[3276534] = 149999
	GoldRate.PLAYER_ENTERING_WORLD()  -- Capture the amount
	assertEquals( 149999, GoldRate_data.testRealm.Alliance.toons.testPlayer["last"] )
end
function test.testCapture_GoldAmount_EnteringWorld_TimeStamp_withData()
	-- Assert that PLAYER_MONEY event takes a snapshot of the current toon's money amount, unless previous data exists (no 0 entries because of startup)
	GoldRate_data.testRealm.Alliance.toons.testPlayer = {["firstTS"] = 3276534, ["last"] = 149999}  -- Has previous data
	GoldRate_data.testRealm.Alliance.consolidated[3276534] = 149999
	local now = time()
	GoldRate.PLAYER_ENTERING_WORLD()  -- Capture the amount
	assertIsNil( GoldRate_data.testRealm.Alliance.consolidated[now] )
end

function test.rateSetup()
	GoldRate_data = nil
	GoldRate_data = { ["testRealm"] = { ["Alliance"] = { ["toons"] = { ["testPlayer"] = { ["firstTS"] = 10, ["last"] = 400 } } } } }
	GoldRate_data.testRealm.Alliance.consolidated = { [10] = 100, [20] = 200, [30] = 300, [40] = 400 }
	GoldRate_data.testRealm.Alliance.goal = 1000
	-- Data given should represent a gain of 10/s, reaching the goal at 100, total gained of 900
	--GoldRate.ADDON_LOADED()
end
function test.testRate_ratePerSecond()
	test.rateSetup()
	rate = GoldRate.Rate()
	assertEquals( 10, rate )
end
function test.testRate_goalValue()
	test.rateSetup()
	goal = select(2, GoldRate.Rate() )
	assertEquals( 100, goal )
end
function test.PLW_Setup()
	-- PLW = Player Leaving World
	GoldRate_data = { ["testRealm"] = { ["Alliance"] = { ["toons"] = { ["testPlayer"] = { ["firstTS"] = 10, ["last"] = 400 } } } } }
	GoldRate_data.testRealm.Alliance.consolidated = {}
	for i = 1, 1500 do
		GoldRate_data.testRealm.Alliance.consolidated[i] = i*i
	end
end
function test.testPLW_PruneOptionSet()
	test.PLW_Setup()
	assertEquals( 1000, GoldRate_options.maxDataPoints )
end
function test.testPLW_PrunesOldData()
	-- test that some data is removed
	test.PLW_Setup()
	GoldRate.PLAYER_LEAVING_WORLD()
	for i = 1, 500 do
		assertIsNil( GoldRate_data.testRealm.Alliance.consolidated[i] )
	end
end
function test.testPLW_KeepsSomeData()
	-- test that not all data is removed.
	test.PLW_Setup()
	GoldRate.PLAYER_LEAVING_WORLD()
	for i = 501, 1000 do
		assertEquals( i*i, GoldRate_data.testRealm.Alliance.consolidated[i] )
	end
end
---------------
function fillTokenHistory()
	now = time()
	GoldRate_tokenData = {}
	StartTS = now-(4*86400)

	goldValStart = 350000000
	goldValPeriod = 86400
	goldValAmplitude = 100000000 -- 10k G
	goldVal = goldValStart
	rateMod = 2*math.pi / goldValPeriod
	for ts=StartTS, now, 20*60 do  -- 20 minute increments
		x = ts - StartTS -- offset
		goldVal = goldVal + (math.floor((math.sin(x * rateMod) * goldValAmplitude)/10000)*10000)
		GoldRate_tokenData[ts] = goldVal
		-- goldVal = goldVal + 10000
	end
	GoldRate.ADDON_LOADED()
end
function test.testToken_TOKEN_MARKET_PRICE_UPDATED_inArray()
	local now = time()
	GoldRate.TOKEN_MARKET_PRICE_UPDATED()
	assertEquals( 123456, GoldRate_tokenData[now] )
end
function test.testToken_TOKEN_MARKET_PRICE_UPDATED_tickerStringSet_positive()
	local now = time()
	GoldRate_tokenData[now-100000] = 73456 -- one day is 86400
	GoldRate.ADDON_LOADED()
	GoldRate.TOKEN_MARKET_PRICE_UPDATED()
	assertEquals( "TOK 12{circle}+5(+68.07%) 24H12 24L12" , GoldRate.tickerToken )
end
function test.testToken_TOKEN_MARKET_PRICE_UPDATED_tickerStringSet_zero()
	local now = time()
	GoldRate_tokenData[now-100000] = 123456 -- one day is 86400
	GoldRate.ADDON_LOADED()
	GoldRate.TOKEN_MARKET_PRICE_UPDATED()
	assertEquals( "TOK 12{circle}+0(+0.00%) 24H263918 24L12" , GoldRate.tickerToken )
end
function test.testToken_TOKEN_MARKET_PRICE_UPDATED_tickerStringSet_negitive()
	local now = time()
	GoldRate_tokenData[now-100000] = 173461 -- one day is 86400
	GoldRate.ADDON_LOADED()
	GoldRate.TOKEN_MARKET_PRICE_UPDATED()
	assertEquals( "TOK 12{circle}-5(-28.83%) 24H12 24L12" , GoldRate.tickerToken )
end
function test.testToken_tokenGoal()
	local now = time()
	GoldRate.TOKEN_MARKET_PRICE_UPDATED()
	GoldRate.Command( "goal token" )
	assertEquals( 123456, GoldRate_data.testRealm.Alliance.goal )
end
function test.testToken_TokenInfo()
	-- just make sure the command works
	fillTokenHistory()
	GoldRate.Command( "token" )
end
function test.testToken_TokenList()
	-- just make sure the command works
	fillTokenHistory()
	GoldRate.Command( "token list" )
end

function test.testGetDiffString_startLessthanEnd()
	--- startVal < endVal (wowGold values)
	expected = "|cff00ff00+5 (100.00%)|r"
	actual = GoldRate.GetDiffString( 50000, 100000 )
	assertEquals( expected, actual )
end
function test.testGetDiffString_startEqualsEnd()
	-- startVal = endVal
	expected = "|cff00ff00+0 (0.00%)|r"
	actual = GoldRate.GetDiffString( 50000, 50000 )
	assertEquals( expected, actual )
end
function test.testGetDiffString_startGreaterthanEnd()
	-- startVal > endVal
	expected = "|cffff0000-5 (-50.00%)|r"
	actual = GoldRate.GetDiffString( 100000, 50000 )
	assertEquals( expected, actual )
end
function test.testGetHighLow_high()
	fillTokenHistory()
	high, low = GoldRate.GetHighLow( 86400 )
	assertEquals( 2639180000, high )
end
function test.testGetHighLow_low()
	fillTokenHistory()
	high, low = GoldRate.GetHighLow( 86400 )
	assertEquals( 123456, low )
end

test.run()
