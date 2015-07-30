# Feature

## TokenAPI

Automaticly record the CurrentMarketPrice of the WoWToken.

The process seems to be to get SystemInfo via:
C_WowTokenPublic.GetCommerceSystemStatus()

Then to call:
C_WowTokenPublic.UpdateMarketPrice()

That fires TOKEN_MARKET_PRICE_UPDATED
TokenChart_Events:RegisterEvent("TOKEN_MARKET_PRICE_UPDATED")

Retrieve the current market price with:
C_WowTokenPublic.GetCurrentMarketPrice()

At this point, be very passive, and only record the values when the event is fired.


