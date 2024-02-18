GoldRate.UIlastUpdate = 0
GoldRate.UIdisplayTime = 1200

-- function GoldRate.UIOnUpdate( )
--	GoldRateUI.lastUpdate = time()
-- 	if( GoldRateUI.show and GoldRateUI.show + GoldRateUI.displayTime < time() ) then
-- 		GoldRate_Display:Hide()
-- 		GoldRateUI.show = nil
-- 	else
-- 		GoldRate_Display_Bar1:SetMinMaxValues( 0, GoldRateUI.displayTime )
-- 		GoldRate_Display_Bar1:SetValue( ( GoldRateUI.show + GoldRateUI.displayTime ) - time() )
-- 	end
-- 	--GoldRate_Display_String:SetText( (GoldRateUI.show + 300) -time() )
-- 	--GoldRate_Display_Bar1:SetMinMaxValues( 0, 300 )
-- 	--GoldRate_Display_Bar1:SetValue( (GoldRateUI.show + 300) - time() )
-- end
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
