#!/usr/bin/env lua

dataFile = "/Applications/World of Warcraft/WTF/Account/OPUSSF/SavedVariables/GoldRate.lua"

function FileExists( name )
   local f = io.open( name, "r" )
   if f then io.close( f ) return true else return false end
end
function DoFile( filename )
	local f = assert( loadfile( filename ) )
	return f()
end
function PairsByKeys( t, f )  -- This is an awesome function I found
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

if FileExists( dataFile ) then
	DoFile( dataFile )

	print( "Realm,Faction,TimeStamp,TimeStamp,Gold" )

	for realm, rdata in pairs( GoldRate_data ) do
		maxInitialTS = 0
		for faction, fdata in pairs( rdata ) do
			strOut = ""
			for name, pdata in pairs( fdata.toons ) do
				maxInitialTS = math.max( maxInitialTS, pdata.firstTS)
			end
			for ts, val in PairsByKeys( GoldRate_data.Hyjal.Alliance.consolidated ) do
				if ts >= maxInitialTS then
					strOut = strOut .. string.format( '%s,%s,%s,%i,%i\n', realm, faction, os.date( "%x %X", ts ),ts, val )
				end
			end
			print(strOut)
		end
	end




end