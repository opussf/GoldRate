GoldRate.UIlastUpdate = 0
GoldRate.UIdisplayTime = 1200  -- 20 minutes should be the normal update interval

function GoldRate.UIOnUpdate( )
	GoldRate.UILastUpdate = time()
	GoldRate_Display_Bar1:SetMinMaxValues( 0, GoldRate.UIdisplayTime )
	GoldRate_Display_Bar1:SetValue( GoldRate.tokenTSs[#GoldRate.tokenTSs] + GoldRate.UIdisplayTime - GoldRate.UILastUpdate )
	-- @TODO: Do bar swapping based on values
end
function GoldRate.UIShow( min, value, max, textIn )
	chatFrameWidth = ChatFrame1:GetWidth()
	GoldRate_Display:SetWidth( chatFrameWidth )
	GoldRate_Display_Bar0:SetWidth( chatFrameWidth )
	GoldRate_Display_Bar1:SetWidth( chatFrameWidth )
	GoldRate_Display_String:SetWidth( chatFrameWidth )

	GoldRate_Display:Show()
	GoldRate.UIshow = time()
	--print( "Show( "..min..", "..value..", "..max..", "..textIn.." ) " )

	GoldRate_Display_Bar1:SetMinMaxValues( min, max )
	GoldRate_Display_Bar1:SetValue( max )
	--GoldRate.Print( "Set bar1 to: "..max )
	GoldRate_Display_Bar0:SetMinMaxValues( min, max )
	GoldRate_Display_Bar0:SetValue( value )
	--GoldRate.Print( "Set bar0 to: "..value )

	GoldRate_Display_String:SetText( textIn )

	--GoldRate.Print(GetMoney()..":"..(GoldRate_Display_Bar0:IsShown() and "IsShown" or "NotShown")..":"..
	--		(GoldRate_Display_Bar0:IsVisible() and "IsVisible" or "NotVisible"))
	--GoldRate.Print( "Frame:"..(GoldRate_Display:IsShown() and "IsShown" or "NotShown" ) )
	--GoldRate.Print( "IsUserPlaced:"..( GoldRate_Display:IsUserPlaced() and "True" or "False" ) )
end
