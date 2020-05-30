GoldRateUI = {}
GoldRateUI.lastUpdate = 0
function GoldRateUI.OnUpdate()
	GoldRateUI.lastUpdate = time()
	if( GoldRateUI.show and GoldRateUI.show + 300 < time() ) then
		GoldRate_Display:Hide()
	end
end
function GoldRateUI.Show( min, value, max, textIn )
	--GoldRate_Bar1:SetMinMaxValues( 0, 150 )
	--GoldRate_Bar1:SetValue( 100 )
	--GoldRate_Bar1:SetFrameStrata( "HIGH" )
	--GoldRate_Bar1Text:SetText( textIn )
	GoldRate_Display:Show()
	GoldRate_Display_String:SetText( textIn )
	GoldRateUI.show = time()
	GoldRate.Print(GetMoney()..":"..(GoldRate_Display_Bar0:IsShown() and "IsShown" or "NotShown")..":"..
			(GoldRate_Display_Bar0:IsVisible() and "IsVisible" or "NotVisible"))
	GoldRate.Print( "Frame:"..(GoldRate_Display:IsShown() and "IsShown" or "NotShown" ) )
	GoldRate.Print( "IsUserPlaced:"..( GoldRate_Display:IsUserPlaced() and "True" or "False" ) )
end

--[[
RestediLvlFrame:Show()
		RestediLvl_PositiveSD:SetMinMaxValues( min, max )
		RestediLvl_Ave:SetMinMaxValues( min, max )
		RestediLvl_NegativeSD:SetMinMaxValues( min, max )

		RestediLvl_PositiveSD:SetValue( ave+sd )
		RestediLvl_Ave:SetValue( ave )
		RestediLvl_NegativeSD:SetValue( ave-sd )

		local strOut = format("iLvl: %s%i|r (%s%i|r / %i / %s%i|r / %s%0.2f%s) %i/%i/-%i (%s) %0.2f%%",
				currentColor, math.floor(currentVal),
				minColor,min,ave,
				maxColor,max,
				sdColor,sd,COLOR_END,
				--Rested.scanCount,
				currValCount,
				count, delcount,
				date("%H:%M", time()+(minTS-timeCutOff) ),
				(currValCount/count)*100 );
		RestediLvl_String:SetText( strOut )

]]



--[[
	XH_XPBarRested:SetMinMaxValues(0, 150);
	XH_XPBarRested:SetValue(150);

	-- InstanceTimer
	XH_InstanceTimerBack:SetMinMaxValues( 0, 1 );
	XH_InstanceTimerBack:SetValue( 1 );

	-- SkillBars
	XH_SkillBar:Hide()
	XH_SkillBarCD:Hide()


	if ( GoldRate_options.nextTokenScanTS and GoldRate_options.nextTokenScanTS <= time() ) then
		C_WowTokenPublic.UpdateMarketPrice()
		GoldRate.UpdateScanTime()
	end
]]