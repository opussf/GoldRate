#!/usr/bin/env lua

require "wowTest"
test.outFileName = "testOut.xml"
--test.coberturaFileName = "coverage.xml"

-- -- Figure out how to parse the XML here, until then....
-- GoldRate_Frame = CreateFrame()
-- GoldRate_Display = CreateFrame()
-- ChatFrame1 = CreateFrame()
-- GoldRate_Display_Bar0 = CreateStatusBar()
-- GoldRate_Display_Bar1 = CreateStatusBar()
-- GoldRate_Display_String = CreateFontString()
-- --SendMailNameEditBox = CreateFontString("SendMailNameEditBox")

ParseTOC( "../src/GoldRate.toc" )

-- addon setup
function test.before()
	GoldRate_data = {}
	GoldRate_tokenData = {}
	GoldRate.tokenLastTS = nil
	GoldRate.tokenLast = nil
	GoldRate.needToRebuildTicker = nil
	GoldRate.inCombat = nil
	chatLog = {}
	GoldRate.OnLoad()
	GoldRate.ADDON_LOADED()
	GoldRate.VARIABLES_LOADED()
	myCopper = 150000
	tokenPrice = 123456
end
function test.after()
	chatLog = {}
end
function fillTokenHistory()
	now = time()
	GoldRate_tokenData = {}
	StartTS = now-(126*86400)

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
function fillTokenHistory_Asc()
	now = time()
	GoldRate_tokenData = {}
	StartTS = now-(120*86400)
	goldValInc = 1
	goldVal = 0
	for ts = StartTS, now, 20*60 do -- 20 min increments
		goldVal = goldVal + goldValInc
		GoldRate_tokenData[ts] = goldVal
	end
	GoldRate.ADDON_LOADED()
end
function fillTokenHistory_Desc()
	now = time()
	GoldRate_tokenData = {}
	StartTS = now-(120*86400)
	goldValInc = -1
	goldVal = 200000
	for ts = StartTS, now, 20*60 do -- 20 min increments
		goldVal = goldVal + goldValInc
		GoldRate_tokenData[ts] = goldVal
	end
	GoldRate.ADDON_LOADED()
end
function test.test_ADDON_LOADED_sets_realm()
	assertEquals( "testRealm", GoldRate.realm )
end
function test.test_ADDON_LOADED_sets_faction()
	assertEquals( "Alliance", GoldRate.faction )
end
function test.test_ADDON_LOADED_sets_name()
	assertEquals( "testPlayer", GoldRate.name )
end
function test.test_ADDON_LOADED_prints_version()
	assertEquals( "|cff700090GoldRate> |rv@VERSION@ loaded.", chatLog[1].msg )
end
function test.test_ADDON_LOADED_event_notregistered()
	assertIsNil( GoldRate_Frame.Events.ADDON_LOADED )
end
function test.test_VARIABLES_LOADED_setsOtherSummed_newToon()
	GoldRate_data.testRealm.Alliance.toons.otherPlayer = {["last"] = 70000, ["firstTS"] = 100} -- give the other player 7 gold
	GoldRate_data.testRealm.Alliance.consolidated = {[100]= 70000}
	GoldRate.ADDON_LOADED() -- force this again
	GoldRate.VARIABLES_LOADED()
	assertEquals( 70000, GoldRate.otherSummed )
end
function test.test_VARIABLES_LOADED_setsOtherSummed_revisit()
	GoldRate_data.testRealm.Alliance.toons.testPlayer = {["last"] = 80000 }  -- give me 8 gold
	GoldRate_data.testRealm.Alliance.toons.otherPlayer = {["last"] = 70000 } -- give the other player 7 gold
	GoldRate.ADDON_LOADED() -- force this again
	GoldRate.VARIABLES_LOADED()
	assertEquals( 70000, GoldRate.otherSummed )
end
function test.test_VARIABLES_LOADED_sets_minScanPeriod()
	assertEquals( 300, GoldRate.minScanPeriod )
end
function test.test_VARIABLES_LOADED_sets_tokenTSs_with_data()
	fillTokenHistory()
	GoldRate.ADDON_LOADED()
	GoldRate.VARIABLES_LOADED()
	assertTrue( GoldRate.tokenTSs )
end
function test.test_VARIABLES_LOADED_sets_tokenTSs_no_data()
	GoldRate.ADDON_LOADED()
	GoldRate.VARIABLES_LOADED()
	assertTrue( GoldRate.tokenTSs )
end
function test.test_VARIABLES_LOADED_sets_myGold()
	GoldRate.ADDON_LOADED()
	GoldRate.VARIABLES_LOADED()
	assertTrue( GoldRate.myGold )
end
function test.test_VARIABLES_LOADED_sets_Options_nextTokenScanTS()
	GoldRate_options.nextTokenScanTS = nil
	GoldRate.ADDON_LOADED()
	GoldRate.VARIABLES_LOADED()
	assertEquals( time() + 30, GoldRate_options.nextTokenScanTS )
end
function test.test_PLAYER_MONEY_sets_player_last()
	GoldRate.PLAYER_MONEY()
	assertEquals( 150000, GoldRate_data.testRealm.Alliance.toons.testPlayer.last )
end
function test.test_PLAYER_MONEY_sets_firstTS()
	GoldRate.PLAYER_MONEY()
	assertEquals( time(), GoldRate_data.testRealm.Alliance.toons.testPlayer.firstTS )
end
function test.test_PLAYER_MONEY_preserves_firstTS()
	GoldRate_data.testRealm.Alliance.toons.testPlayer = {["firstTS"] = 200, ["last"] = 10000 }
	GoldRate_data.testRealm.Alliance.consolidated = { [200] = 10000 }
	GoldRate.PLAYER_MONEY()
	assertEquals( 200, GoldRate_data.testRealm.Alliance.toons.testPlayer["firstTS"] )
end
function test.test_PLAYER_MONEY_sets_value_in_consolidated_single_player()
	GoldRate.PLAYER_MONEY()
	assertEquals( 150000, GoldRate_data.testRealm.Alliance.consolidated[time()] )
end
function test.test_PLAYER_MONEY_sets_value_in_consolidated_multiple_players()
	-- means that GoldRate.otherSummed should be set.
	GoldRate.otherSummed = 850000
	GoldRate.PLAYER_MONEY()
	assertEquals( 1000000, GoldRate_data.testRealm.Alliance.consolidated[time()] )
end
function test.test_PLAYER_ENTERTING_WORLD_sets_value_in_consolidated()
	GoldRate.PLAYER_ENTERING_WORLD()
	assertEquals( 150000, GoldRate_data.testRealm.Alliance.consolidated[time()] )
end
function test.test_PLAYER_ENTERING_WORLD_sets_player_last_withData()
	GoldRate_data.testRealm.Alliance.toons.testPlayer = {["firstTS"] = 3276534, ["last"] = 149999}  -- Has previous data
	GoldRate.VARIABLES_LOADED() -- this needs to be done again to reset GoldRate.myGold
	GoldRate.PLAYER_ENTERING_WORLD()  -- Capture the amount
	assertEquals( 150000, GoldRate_data.testRealm.Alliance.toons.testPlayer.last )
end

---------------
function test.test_TOKEN_MARKET_PRICE_UPDATED_inArray_no_previous_data()
	local now = time()
	GoldRate.ADDON_LOADED()
	GoldRate.TOKEN_MARKET_PRICE_UPDATED()
	assertEquals( 123456, GoldRate_tokenData[now] )
	assertEquals( 123456, GoldRate_tokenData[GoldRate.tokenTSs[#GoldRate.tokenTSs]])
end
function test.test_TOKEN_MARKET_PRICE_UPDATED_does_not_save_if_same_value_as_previous()
	local now = time()
	GoldRate_tokenData[now - 120] = 123456
	GoldRate.VARIABLES_LOADED()
	GoldRate.TOKEN_MARKET_PRICE_UPDATED()

	local dataCount = 0
	for k, v in pairs( GoldRate_tokenData ) do
		dataCount = dataCount + 1
	end
	assertEquals( 1, dataCount )
end
function test.test_TOKEN_MARKET_PRICE_UPDATED_saves_if_different_values()
	local now = time()
	GoldRate_tokenData[now - 120] = 120456
	GoldRate.VARIABLES_LOADED()
	GoldRate.TOKEN_MARKET_PRICE_UPDATED()

	local dataCount = 0
	for k, v in pairs( GoldRate_tokenData ) do
		dataCount = dataCount + 1
	end
	assertEquals( 2, dataCount )
end
function test.test_TOKEN_MARKET_PRICE_UPDATED_sets_flag_no_previous_data()
	GoldRate.ADDON_LOADED()
	GoldRate.TOKEN_MARKET_PRICE_UPDATED()
	assertTrue( GoldRate.needToRebuildTicker )
end
function test.test_TOKEN_MARKET_PRICE_UPDATED_sets_flag_if_different_values()
	local now = time()
	GoldRate_tokenData[now - 120] = 121456
	GoldRate.VARIABLES_LOADED()
	GoldRate.TOKEN_MARKET_PRICE_UPDATED()
	assertTrue( GoldRate.needToRebuildTicker )
end
function test.test_TOKEN_MARKET_PRICE_UPDATED_sets_simple_tickerToken_no_previous_data()
	GoldRate.ADDON_LOADED()
	GoldRate.TOKEN_MARKET_PRICE_UPDATED()
	assertEquals( "TOK 12{circle}", GoldRate.tickerToken )
end
function test.test_TOKEN_MARKET_PRICE_UPDATED_sets_simple_tickerToken_previous_data_positive()
	local now = time()
	GoldRate_tokenData[now - 120] = 122456
	GoldRate.ADDON_LOADED()
	GoldRate.TOKEN_MARKET_PRICE_UPDATED()
	assertEquals( "TOK 12{circle}", GoldRate.tickerToken )
end
function test.test_TOKEN_MARKET_PRICE_UPDATED_prints_to_UIErrorsFrame()
	GoldRate.ADDON_LOADED()
	GoldRate.TOKEN_MARKET_PRICE_UPDATED()
	for i in pairs( chatLog ) do
		if chatLog[i].chatType == "UIErrorsFrame" then
			assertEquals( "TOK 12{circle}", chatLog[i].msg )
			return
		end
	end
	fail( "Did not print to UIErrorsFrame." )
end
function test.test_OnUpdate_continues_prune_coroutine()
	GoldRate.pruneThread = nil
	GoldRate.PLAYER_ENTERING_WORLD()
	GoldRate.OnUpdate()
	GoldRate.OnUpdate()
	GoldRate.OnUpdate()
	assertEquals( "dead", coroutine.status( GoldRate.pruneThread ) )
end
function test.test_OnUpdate_Updates_ScanTime()
	GoldRate_options.nextTokenScanTS = 45
	GoldRate.OnUpdate()
	assertEquals( time() + 20*60, GoldRate_options.nextTokenScanTS )
end

-- function test.testToken_TokenInfo()
-- 	-- just make sure the command works
-- 	fillTokenHistory()
-- 	GoldRate.Command( "token" )
-- end
-- function test.testToken_TokenList()
-- 	-- just make sure the command works
-- 	fillTokenHistory()
-- 	GoldRate.Command( "token list" )
-- end

-- function test.testGetDiffString_startLessthanEnd()
-- 	--- startVal < endVal (wowGold values)
-- 	expected = "|cff00ff00+5 (100.00%)|r"
-- 	actual = GoldRate.GetDiffString( 50000, 100000 )
-- 	assertEquals( expected, actual )
-- end
-- function test.testGetDiffString_startEqualsEnd()
-- 	-- startVal = endVal
-- 	expected = "|cff00ff00+0 (0.00%)|r"
-- 	actual = GoldRate.GetDiffString( 50000, 50000 )
-- 	assertEquals( expected, actual )
-- end
-- function test.testGetDiffString_startGreaterthanEnd()
-- 	-- startVal > endVal
-- 	expected = "|cffff0000-5 (-50.00%)|r"
-- 	actual = GoldRate.GetDiffString( 100000, 50000 )
-- 	assertEquals( expected, actual )
-- end
function test.testGetHighLow_1high()
	fillTokenHistory_Asc()
	high, low = GoldRate.GetHighLow()
	assertTrue( high >= 8640 )
	assertTrue( high <= 8642 )
end
function test.testGetHighLow_1low()
	fillTokenHistory_Asc()
	high, low = GoldRate.GetHighLow()
	assertTrue( low >= 8568 )
	assertTrue( low <= 8570 )
end
----
function test.testGetHighLow_30High_Asc()
	fillTokenHistory_Asc()
	_, _, high30 = GoldRate.GetHighLow()
	assertTrue( high30 >= 8640 )
	assertTrue( high30 <= 8642 )
end
function test.testGetHighLow_30Low_Asc()
	fillTokenHistory_Asc()
	_, _, _, low30 = GoldRate.GetHighLow()
	assertTrue( low30 >= 6480 )
	assertTrue( low30 <= 6482 )
end
function test.testGetHighLow_60High_Asc()
	fillTokenHistory_Asc()
	_, _, _, _, high60 = GoldRate.GetHighLow()
	assertTrue( high60 >= 8640 )
	assertTrue( high60 <= 8642 )
end
function test.testGetHighLow_60Low_Asc()
	fillTokenHistory_Asc()
	_, _, _, _, _, low60 = GoldRate.GetHighLow()
	assertTrue( low60 >= 4320 )
	assertTrue( low60 <= 4322 )
end
function test.testGetHighLow_90High_Asc()
	fillTokenHistory_Asc()
	_, _, _, _, _, _, high90 = GoldRate.GetHighLow()
	assertTrue( high90 >= 8640 )
	assertTrue( high90 <= 8642 )
end
function test.testGetHighLow_90Low_Asc()
	fillTokenHistory_Asc()
	_, _, _, _, _, _, _, low90 = GoldRate.GetHighLow()
	assertTrue( low90 >= 2160 )
	assertTrue( low90 <= 2162 )
end
function test.testGetHighLow_30High_Desc()
	fillTokenHistory_Desc()
	_, _, high30 = GoldRate.GetHighLow()
	assertTrue( high30 >= 193518 )
	assertTrue( high30 <= 193520 )
end
function test.testGetHighLow_30Low_Desc()
	fillTokenHistory_Desc()
	_, _, _, low30 = GoldRate.GetHighLow()
	assertTrue( low30 >= 191358 )
	assertTrue( low30 <= 191360)
end
function test.testGetHighLow_60High_Desc()
	fillTokenHistory_Desc()
	_, _, _, _, high60 = GoldRate.GetHighLow()
	assertTrue( high60 >= 195678 )
	assertTrue( high60 <= 195680 )
end
function test.testGetHighLow_60Low_Desc()
	fillTokenHistory_Desc()
	_, _, _, _, _, low60 = GoldRate.GetHighLow()
	assertTrue( low60 >= 191358 )
	assertTrue( low60 <= 191360 )
end
function test.testGetHighLow_90High_Desc()
	fillTokenHistory_Desc()
	_, _, _, _, _, _, high90 = GoldRate.GetHighLow()
	assertTrue( high90 >= 197838 )
	assertTrue( high90 <= 197840 )
end
function test.testGetHighLow_90Low_Desc()
	fillTokenHistory_Desc()
	_, _, _, _, _, _, _, low90 = GoldRate.GetHighLow()
	assertTrue( low90 >= 191358 )
	assertTrue( low90 <= 191360 )
end
function test.testHighLow()
	now = time()
	GoldRate_tokenData = {}
	GoldRate_tokenData[now-(100*86400)] = 200000000 -- 100 days ago, 20k
	GoldRate_tokenData[now-( 85*86400)] = 230000000 --  85 days ago, 23k -- max90
	GoldRate_tokenData[now-( 75*86400)] = 170000000 --  75 days ago, 17k -- min90
	GoldRate_tokenData[now-( 55*86400)] = 220000000 --  55 days ago, 22k -- max60
	GoldRate_tokenData[now-( 40*86400)] = 180000000 --  40 days ago, 18k -- min60
	GoldRate_tokenData[now-( 25*86400)] = 210000000 --  25 days ago, 21k -- max30
	GoldRate_tokenData[now-( 10*86400)] = 190000000 --  10 days ago, 19k -- min30
	GoldRate_tokenData[now-(  5*86400)] = 200000000 --   5 days ago, 20k
	GoldRate_tokenData[now-(0.5*86400)] = 205000000 -- 12 hours ago, 20.5k

	TokenPrice = 204000000  -- now, 1dLow
	GoldRate.ADDON_LOADED()
	GoldRate.TOKEN_MARKET_PRICE_UPDATED()
	assertEquals( "TOK 20400{circle}", GoldRate.tickerToken )
	TokenPrice = 123456 -- return to norm
end
---------------
-- Tests for DataPrune
---------------
function test.makeOldData_linearIncrease( spend )
	-- pass a value to spend that much once you have that much.
	-- (Makes a sawblade with a max of spend)
	now = time()
	GoldRate.PLAYER_MONEY()

	val = 10
	for ts = now-(150*86400),now,1000 do
		if spend and (val > spend) then val = 0 end
		GoldRate_data.testRealm.Alliance.consolidated[ts]=val
		val = val + 10
	end
	--print(val)
	-- should place 2592 data points older than 120 days (the current cut off)
end
function test.runPruneData()
	GoldRate.pruneThread = nil
	GoldRate.PLAYER_ENTERING_WORLD()
	repeat
		coroutine.resume( GoldRate.pruneThread )
	until (coroutine.status( GoldRate.pruneThread ) == "dead" )
end
function test.testSmoothOldData_linearIncrease()
	-- in this test, the first data point should be kept
	-- with all subsequent data points up to 30 days ago removed
	cutOff = time()-(30*86400)
	test.makeOldData_linearIncrease()
	GoldRate.VARIABLES_LOADED()
	GoldRate.TOKEN_MARKET_PRICE_UPDATED()
	test.runPruneData()
	valCount = 0
	for k,v in GoldRate.PairsByKeys( GoldRate_data.testRealm.Alliance.consolidated ) do
		--print(k..":"..v)
		if k<cutOff then
			valCount = valCount + 1
		end
	end
	assertTrue( valCount > 0 )
	assertTrue( valCount < 4 )
end
function test.testSmoothOldData_sawblade()
	cutOff = time()-(30*86400)
	test.makeOldData_linearIncrease( 10000 ) -- one gold
	GoldRate.VARIABLES_LOADED()
	test.runPruneData()
	valCount = 0
	for k,v in GoldRate.PairsByKeys( GoldRate_data.testRealm.Alliance.consolidated ) do
		--print(k..":"..v)
		if k<cutOff then
			valCount = valCount + 1
		end
	end
	assertTrue( valCount >= 21 )
	assertTrue( valCount <= 22 )
end
function test.testPruneOldData()
	cutOff = time()-(90*86400)
	test.makeOldData_linearIncrease( 10000 )
	GoldRate.VARIABLES_LOADED()
	test.runPruneData()
	valCount = 0
	for k,v in GoldRate.PairsByKeys( GoldRate_data.testRealm.Alliance.consolidated ) do
		if k<cutOff then
			valCount = valCount + 1
		end
	end
	assertEquals( 11, valCount )
end
------------------
-- Tests for multiPrune
------------------
function test.makeData_multiPrune( spend )
	now = time()
	GoldRate.PLAYER_MONEY()
	GoldRate_data.testRealm.Horde = {}
	GoldRate_data.testRealm.Horde.consolidated = {}
	GoldRate_data['otherRealm'] = {}
	GoldRate_data['otherRealm'].Alliance = {}
	GoldRate_data['otherRealm'].Alliance.consolidated = {}

	val = 10
	for ts = now-(180*86400),now,1000 do
		if spend and (val > spend) then val = 0 end
		GoldRate_data.testRealm.Alliance.consolidated[ts] = val
		GoldRate_data.testRealm.Horde.consolidated[ts] = val / 2
		GoldRate_data['otherRealm'].Alliance.consolidated[ts] = val
		val = val + 10
	end
end
function test.testMultiPrune_01()
	test.makeData_multiPrune( 10000 )
	test.runPruneData()

	valCount = 0
	for k,v in GoldRate.PairsByKeys( GoldRate_data.testRealm.Alliance.consolidated ) do
		valCount = valCount + 1
	end
	for k,v in GoldRate.PairsByKeys( GoldRate_data.testRealm.Horde.consolidated ) do
		valCount = valCount + 1
	end
	for k,v in GoldRate.PairsByKeys( GoldRate_data['otherRealm'].Alliance.consolidated ) do
		valCount = valCount + 1
	end
	--assertEquals( 7857, valCount )
	assertTrue( valCount < 7860 ) -- +- 2 values to account for times
	assertTrue( valCount > 7854 )
end
function test.test_Prune_Token_values()
	-- Token prune only removes duplicate values
	GoldRate_tokenData = {
		[5] = 10000,
		[10] = 10000,
		[15] = 20000,
	}
	test.runPruneData()
	assertIsNil( GoldRate_tokenData[10] )
end
----------------
-- Tests for UI
----------------
function test.test_sets_inCombat()
	GoldRate.inCombat = nil
	GoldRate.PLAYER_REGEN_DISABLED()
	assertTrue( GoldRate.inCombat )
end
function test.test_clears_inCombat()
	GoldRate.inCombat = true
	GoldRate.PLAYER_REGEN_ENABLED()
	assertIsNil( GoldRate.inCombat )
end
function test.testUI_PLAYER_ENTERING_WORLD_shows_ui()
	GoldRate.PLAYER_ENTERING_WORLD()
	assertTrue( GoldRate_Display:IsVisible() )
end
function test.test_UI_one_token()
	GoldRate.inCombat = nil
	GoldRate.TOKEN_MARKET_PRICE_UPDATED()
	GoldRate.OnUpdate()
	assertEquals( "TOK 24L12 / 12(+0) 360DL12 / 24H12", GoldRate.tokenText )
end
function test.test_UI_two_token()
	GoldRate.inCombat = nil
	now = time()
	GoldRate_tokenData[now-( 25*86400)] = 130000 --  25 days ago, 21k -- max30
	GoldRate.VARIABLES_LOADED()
	GoldRate.TOKEN_MARKET_PRICE_UPDATED()
	GoldRate.OnUpdate()
	assertEquals( "TOK 24L12 / 12(-1) 360DL12 / 24H12", GoldRate.tokenText )
end
function test.test_UI_more_tokens()
	GoldRate.inCombat = nil
	GoldRate_tokenData[time()-3600] = 500000
	GoldRate.VARIABLES_LOADED()
	GoldRate.TOKEN_MARKET_PRICE_UPDATED()
	GoldRate.OnUpdate()
	assertEquals( "TOK 24L12 / 12(-38) 360DL12 / 24H50", GoldRate.tokenText )
end
function test.test_UIShow_Shows_the_UI()
	GoldRate_Display:Hide()
	GoldRate.UIShow( 1, 2, 3, "Hello" )
	assertTrue( GoldRate_Display:IsVisible() )
end
function test.test_UIShow_Bar0_minmax()
	GoldRate_Display_Bar0.min = 0
	GoldRate_Display_Bar0.max = 0
	GoldRate.UIShow( 1, 2, 3, "Hello" )
	assertEquals( 1, GoldRate_Display_Bar0.min )
	assertEquals( 3, GoldRate_Display_Bar0.max )
end
function test.test_UIShow_Bar1_minmax()
	GoldRate_Display_Bar1.min = 0
	GoldRate_Display_Bar1.max = 0
	GoldRate.UIShow( 1, 2, 3, "Hello" )
	assertEquals( 1, GoldRate_Display_Bar1.min )
	assertEquals( 3, GoldRate_Display_Bar1.max )
end
function test.test_UIShow_Bars_setValue()
	GoldRate_Display_Bar0.value = 0
	GoldRate_Display_Bar1.value = 0
	GoldRate.UIShow( 10, 20, 30, "Hello" )
	assertEquals( 20, GoldRate_Display_Bar0.value, "Bar0 should have value." )
	assertEquals( 30, GoldRate_Display_Bar1.value, "Bar1 should have value." )
end
function test.test_UIShow_Bars_setText()
	GoldRate_Display_String.textValue = ""
	GoldRate.UIShow( 20, 30, 40, "TOK testvalue" )
	assertEquals( "TOK testvalue", GoldRate_Display_String.textValue )
end
function test.test_UIOnUpdate_sets_UILastUpdate()
	GoldRate.TOKEN_MARKET_PRICE_UPDATED()
	GoldRate.UIOnUpdate()
	assertTrue( GoldRate.UILastUpdate > 0 )
end
function test.test_UIOnUpdate_Bar1_minmax()
	GoldRate.TOKEN_MARKET_PRICE_UPDATED()
	GoldRate_Display_Bar1.min = 10
	GoldRate_Display_Bar1.max = 10
	GoldRate.UIOnUpdate()
	assertEquals( 0, GoldRate_Display_Bar1.min )
	assertEquals( GoldRate.UIdisplayTime, GoldRate_Display_Bar1.max )
end
function test.test_UIOnUpdate_Bar1_value_NewTokenValue()
	GoldRate.VARIABLES_LOADED()
	GoldRate.TOKEN_MARKET_PRICE_UPDATED()
	GoldRate.OnUpdate()
	GoldRate.UIOnUpdate()
	assertEquals( GoldRate.UIdisplayTime, GoldRate_Display_Bar1.value )
end
function test.test_UIOnUpdate_Bar1_value_OldTokenValue()
	GoldRate.tokenTSs = { time() - 180 } -- 3 minutes ago
	GoldRate.UIOnUpdate()
	assertEquals( GoldRate.UIdisplayTime - 180 , GoldRate_Display_Bar1.value )
end
test.run()
