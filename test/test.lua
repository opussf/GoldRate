#!/usr/bin/env lua

addonData = { ["Version"] = "1.0",
}

require "wowTest"

test.outFileName = "testOut.xml"

-- Figure out how to parse the XML here, until then....
GoldRate_Frame = CreateFrame()
--SendMailNameEditBox = CreateFontString("SendMailNameEditBox")

-- require the file to test
package.path = "../src/?.lua;'" .. package.path
require "GoldRate"
--require "GoldRate_Offline"

-- addon setup
function test.before()
	GoldRate_data = {}
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
function test.testADDON_LOADED_setsOtherSummed_newToon()
	GoldRate_data.testRealm.Alliance.toons.otherPlayer = {["last"] = 70000} -- give the other player 7 gole
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
	GoldRate_data.testRealm.Alliance.toons.testPlayer["firstTS"] = 200
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
	GoldRate_data.testRealm.Alliance.toons.otherPlayer = {["last"] = 70000} -- give the other player 7 gold
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
function test.testCapture_GoldAmount_EnteringWorld_Last()
	-- Assert that PLAYER_MONEY event takes a snapshot of the current toon's money amount
	GoldRate.PLAYER_ENTERING_WORLD()  -- Capture the amount
	assertEquals( 150000, GoldRate_data.testRealm.Alliance.toons.testPlayer["last"] )
end
function test.testCapture_GoldAmount_EnteringWorld_TimeStamp()
	-- Assert that PLAYER_MONEY event takes a snapshot of the current toon's money amount
	local now = time()
	GoldRate.PLAYER_ENTERING_WORLD()  -- Capture the amount
	assertEquals( 150000, GoldRate_data.testRealm.Alliance.consolidated[now] )
end
-- GoldRateOffline tests
--[[
function test.beforeGoldRateOffline()
	GoldRate_data = {}
	dataStructure = {}
	timeRanges = {}
end
function test.testGoldRateOffline_maxDate_all()
	test.beforeGoldRateOffline()
	GoldRate_data = { ["testRealm"] = { ["Alliance"] = { ["testPlayer1"] = { [10] = 100 } } } }
	GoldRate_data.testRealm.Alliance.testPlayer2 = { [20] = 200 }
	GoldRate_data.testRealm.Alliance.testPlayer3 = { [30] = 400 }
	GOLDRATE_OFFLINE.ProcessData()
	assertEquals( 30, timeRanges.all.newestEntry )
	assertEquals( 30, timeRanges.testRealm.newestEntry )
	assertEquals( 30, timeRanges.testRealm.Alliance.newestEntry )
	assertEquals( 10, timeRanges.testRealm.Alliance.testPlayer1.newestEntry )
	assertEquals( 20, timeRanges.testRealm.Alliance.testPlayer2.newestEntry )
	assertEquals( 30, timeRanges.testRealm.Alliance.testPlayer3.newestEntry )
end
function test.testGoldRateOffline_minDate_all()
	test.beforeGoldRateOffline()
	GoldRate_data = { ["testRealm"] = { ["Alliance"] = { ["testPlayer1"] = { [10] = 100 } } } }
	GoldRate_data.testRealm.Alliance.testPlayer2 = { [20] = 200 }
	GoldRate_data.testRealm.Alliance.testPlayer3 = { [30] = 400 }
	GOLDRATE_OFFLINE.ProcessData()
	assertEquals( 10, timeRanges.all.oldestEntry )
	assertEquals( 10, timeRanges.testRealm.oldestEntry )
	assertEquals( 10, timeRanges.testRealm.Alliance.oldestEntry )
	assertEquals( 10, timeRanges.testRealm.Alliance.testPlayer1.oldestEntry )
	assertEquals( 20, timeRanges.testRealm.Alliance.testPlayer2.oldestEntry )
	assertEquals( 30, timeRanges.testRealm.Alliance.testPlayer3.oldestEntry )
end
function test.testGoldRateOffline_AdditiveMerge_1Item()
	test.beforeGoldRateOffline()
	GoldRate_data = { ["testRealm"] = { ["Alliance"] = { ["testPlayer1"] = { [10] = 100 } } } }
	GOLDRATE_OFFLINE.ProcessData()
	assertEquals( 100, combinedData.testRealm.Alliance[10] )
end
function test.testGoldRateOffline_AdditiveMerge_2Items()
	test.beforeGoldRateOffline()
	GoldRate_data = { ["testRealm"] = { ["Alliance"] = { ["testPlayer1"] = { [10] = 100 } } } }
	GoldRate_data.testRealm.Alliance.testPlayer2 = { [20] = 200 }
	GOLDRATE_OFFLINE.ProcessData()
	assertEquals( 300, combinedData.testRealm.Alliance[20] )
end
function test.testGoldRateOffline_AdditiveMerge_3Items()
	test.beforeGoldRateOffline()
	GoldRate_data = { ["testRealm"] = { ["Alliance"] = { ["testPlayer1"] = { [10] = 100 } } } }
	GoldRate_data.testRealm.Alliance.testPlayer2 = { [20] = 200 }
	GoldRate_data.testRealm.Alliance.testPlayer3 = { [30] = 400 }
	GOLDRATE_OFFLINE.ProcessData()
	--GOLDRATE_OFFLINE.ReportData()
	assertEquals( 700, combinedData.testRealm.Alliance[30] )
end
function test.testGoldRateOffline_AdditvieMerge_3Toons_4Data()
	test.beforeGoldRateOffline()
	GoldRate_data = { ["testRealm"] = { ["Alliance"] = { ["testPlayer1"] = { [10] = 100, [40] = 800 } } } }
	GoldRate_data.testRealm.Alliance.testPlayer2 = { [20] = 200 }
	GoldRate_data.testRealm.Alliance.testPlayer3 = { [30] = 400 }
	GOLDRATE_OFFLINE.ProcessData()
	--GOLDRATE_OFFLINE.ReportData()
	assertEquals( 1500, combinedData.testRealm.Alliance[40] )
end
function test.testGoldRateOffline_AdditeMerge_diffAlliance()
	test.beforeGoldRateOffline()
	GoldRate_data = { ["testRealm"] = { ["Alliance"] = { ["testPlayer1"] = { [10] = 100 } } } }
	GoldRate_data.testRealm.Horde = { ["testPlayer2"] = { [20] = 200 } }
	GOLDRATE_OFFLINE.ProcessData()
	GOLDRATE_OFFLINE.ReportData()
	assertEquals( 100, combinedData.testRealm.Alliance[10] )
	assertEquals( 200, combinedData.testRealm.Horde[20] )
end
function test.testGoldRateOffline_AdditeMerge_diffRealms()
	test.beforeGoldRateOffline()
	GoldRate_data = { ["testRealm"] = { ["Alliance"] = { ["testPlayer1"] = { [10] = 100 } } } }
	GoldRate_data.testRealm2 = { ["Alliance"] = { ["testPlayer2"] = { [20] = 200 } } }
	GOLDRATE_OFFLINE.ProcessData()
	GOLDRATE_OFFLINE.ReportData()
	assertEquals( 100, combinedData.testRealm.Alliance[10] )
	assertEquals( 200, combinedData.testRealm2.Alliance[20] )
end
]]
test.run()
