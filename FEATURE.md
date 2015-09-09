# Feature

## TokenAPI


### Create a scrolling ticker display.

#### Options to show:
Token price
Realm-faction total gold
Time to scroll
Change in amount or percent

#### Data to show:
TOK price <direction icon> <change from previous day close>
GOL amount <direction icon> <change from previous day close> -> <Goal>

How to find the 'previous day close' when there is:
	- no data
	- no data for the last 24 hours

TOK 23452\/5
TOK 23452^^6

TOK 23452<green>5</green>
TOK 23452<red>6</red>

{cross} is red X
{triangle} is green /_\

- Need to capture:
Realm-faction total at end of last day known
	(should be able to be obtained from current data)

### Report Token ticker to guild.

Provide an option to send this info to guild chat.
	-- Control via black listing guild-realm
	-- Only report token price



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
^^^  Schedule the events for every 20 minutes.

Color the difference and %diff

Show for each day:
<date> :: <dailyMin> <dailyMax> +-<dayChange> <dayChange percent>%

For today:
