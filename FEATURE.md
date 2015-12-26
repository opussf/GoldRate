# Feature

## 306090HighLow
Show the the High or Low for 30, 60 or 90 days back.

The High / Low for 30, 60 or 90 days back is much like the high / low for the last 24 hours.
Remove the parameter for the GetHighLow function and have it return:
24hHigh, 24hLow, 30dHigh, 30dLow, 60dHigh, 60dLow, 90dHigh, 90dLow

Continue to always show the 24h High and Low.
Find which of the 30, 60 or 90 days High / Low is closest to the current value.
Use a minimal diff, trying to display the oldest first.

### Testing
Always increasing values will show that the value is closest to the 30d High.
Always decreasing values will show that the value is closest to the 30d Low.



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






{
	"goldRate": {
		"graphAgeDays": "365",
		"realms": [
			{
				"realm": "Moon Guard",
				"factions": [
					{
						"faction": "Alliance",
						"goal": 2432423,
						"data": [
							{
								"ts": 2222,
								"val": 33420000
							}
						]
					}, {
						"faction": "Horde",
						"data": [
							{
								"ts": 2222,
								"val": 3234234
							},
							{
								"ts": 2223,
								"val": 3234255
							}
						]
					}
				]
			}
		]
	}
}