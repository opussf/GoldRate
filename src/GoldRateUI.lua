GoldRateUI = {}
GoldRateUI.lastUpdate = 0
function GoldRateUI.OnUpdate()
	if GoldRateUI.lastUpdate + 1 < time() then  -- do an update
		GoldRateUI.lastUpdate = time()
		GoldRate_Bar1:SetMinMaxValues(0, 150)
		GoldRate_Bar1:SetValue( 100 )
		GoldRate_Bar1:SetFrameStrata("LOW")
		GoldRate_Bar1:SetStatusBarColor()
		GoldRate_Bar1:Show()
		GoldRate.Print(GetMoney())
		--GoldRate_Display:Hide()
	end
end


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