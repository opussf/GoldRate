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
require "GoldRate_Offline"

-- addon setup
function test.before()
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
function test.testCapture_SetsRealm()
	GoldRate.PLAYER_MONEY()
	assertTrue( GoldRate_data.testRealm )
end
function test.testCapture_SetsFaction()
	GoldRate.PLAYER_MONEY()
	assertTrue( GoldRate_data.testRealm.Alliance )
end
function test.testCapture_SetsName()
	GoldRate.PLAYER_MONEY()
	assertTrue( GoldRate_data.testRealm.Alliance.testPlayer )
end
function test.testCapture_GoldAmount_PlayerMoney_Last()
	-- Assert that PLAYER_MONEY event takes a snapshot of the current toon's money amount
	local now = time()
	GoldRate.PLAYER_MONEY()  -- Capture the amount
	assertEquals( 150000, GoldRate_data.testRealm.Alliance.testPlayer["last"] )
end
function test.testCapture_GoldAmount_PlayerMoney_TimeStamp()
	-- Assert that PLAYER_MONEY event takes a snapshot of the current toon's money amount
	local now = time()
	GoldRate.PLAYER_MONEY()  -- Capture the amount
	assertEquals( 150000, GoldRate_data.testRealm.Alliance.testPlayer[now] )
end
function test.testCapture_GoldAmount_EnteringWorld_Last()
	-- Assert that PLAYER_MONEY event takes a snapshot of the current toon's money amount
	local now = time()
	GoldRate.PLAYER_ENTERING_WORLD()  -- Capture the amount
	assertEquals( 150000, GoldRate_data.testRealm.Alliance.testPlayer["last"] )
end
function test.testCapture_GoldAmount_EnteringWorld_TimeStamp()
	-- Assert that PLAYER_MONEY event takes a snapshot of the current toon's money amount
	local now = time()
	GoldRate.PLAYER_ENTERING_WORLD()  -- Capture the amount
	assertEquals( 150000, GoldRate_data.testRealm.Alliance.testPlayer[now] )
end
-- GoldRateOffline tests
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
end
function test.testGoldRateOffline_AdditiveMerge_2Items()
	test.beforeGoldRateOffline()
	GoldRate_data = { ["testRealm"] = { ["Alliance"] = { ["testPlayer1"] = { [10] = 100 } } } }
	GoldRate_data.testRealm.Alliance.testPlayer2 = { [20] = 200 }
	GOLDRATE_OFFLINE.ProcessData()
end
function test.testGoldRateOffline_AdditiveMerge_3Items()
	test.beforeGoldRateOffline()
	GoldRate_data = { ["testRealm"] = { ["Alliance"] = { ["testPlayer1"] = { [10] = 100 } } } }
	GoldRate_data.testRealm.Alliance.testPlayer2 = { [20] = 200 }
	GoldRate_data.testRealm.Alliance.testPlayer3 = { [30] = 400 }
	GOLDRATE_OFFLINE.ProcessData()
	--GOLDRATE_OFFLINE.ReportData()
end
test.run()
