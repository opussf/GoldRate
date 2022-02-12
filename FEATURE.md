# Feature

## UIDisplay

Show the token price in the UI.
The UI from the Rested iLvl display can be revived to show this.
Rested iLvl showed the iLvl average just under the chat frame, and below the text input box.

For the token, show 24H Low ( min ), current value ( with change ) and closest range, and 24H High ( max ).

For gold value change, create another frame under the backpack frame?
Create the frame 2 bars high?

Want to change the structure of this addon.

Move some of the ADDON_LOADED stuff to VARIABLES_LOADED.

### Questions

Do I still want it to output to guild and chat?
Should this be a manual trigger?


## multiPrune
Prune / smooth for all realms.
Convert the process into a co-routine

Stats I may want to know:
* How many data points are there
* How many were pruned
* How many were smoothed
* Older than smooth age
* How many are left.
* Realm / faction

93823 data points. 0 expired (older than 285 days).
28763 data points are older than 30 days.
362 data points were pruned for smoothing.

Hyjal-Alliance : 93823 points
               :     0 expired (older than 274 days)
               : 28673         (older than 30 days)
               :   362 pruned for smoothing.
               : 93461 remain
Hyjal-Horde    : 93823 -0 (>274 days) 28673 (>30 days) -362 (smoothing) = 93461

Hyjal-Alliance : 93823 points. 10 expired (>274 days) 28673-362>30 days.
Hyjal-Alliance : Of 93823 points, 10 expired, 28673 (-362) smoothed.

93823 points.  10 expired, 29673 >30 days, 362 smoothed for Hyjal-Alliance

29673 / 93823 points >30 days, 10 expired, 362 smoothed for Hyjal-Alliance





## limitRange
Limit the range of data used to predict future values.

## dataPrune
After gathering data for a while, upwards of ~33k worth of data points on a single realm,  I find a requirement to control the amount of data kept.
The initial idea of pruning after a set number of data points, while it would work, seems to fall short in practice.

Keeping and exporting large data sets is expensive.
Overly large export data files (as of 23 Jan 2016, the CSV file is 3,069,318 bytes - 3.1M) take a long time (~36 seconds) to generate.
The large data sets also produce too heavy of a load while generating graphs (Google Graphs consumes too much CPU and browser memory).



The question comes down to how to this: For what reason should data be kept?
This question would also decide how to prune data.

Some answers:
* Calculate rates.
  * Highly fluxuating data mellows rates.
  * Shorter calc history gives better rates, but possibly more volitile in change
  * Only use session time frame to calculate rates?
    * In accurate for initial start, or because of high activity times.
  * Use a constant time chunk (2 weeks, 1 month, 1 day)
    * Faster to correct for lots of ups and downs.

Prune ideas:
1. Data compression preserving peaks and valleys.
  * Data points are kept when they represent a peak (before a purchase), or a valley (after a purchase)
  * Would tend to keep the general feel or activity of data flows.
  * Most probable purchase would be repairs
2. Rolling averages for ever increasing time slices.
  * Data older than 3 months could be averaged for each hour
  * Data older than 6 months could be averaged for each day
  * Data older than 12 months could be averaged for each week?
3. Data could be truncated to reflect a high and a low for each 24h period.

Because pruning the data will be destructive, probably the first place to do this would be when exporting the data.



valueDirection = (currentValue - previousValue) / math.abs(currentValue - previousValue)

previousValue = 0
currentValue = 1
valueDirection = (1 - 0) / abs(1 - 0)
					1 / 1 = 1

previousValue = 1
currentValue = 0
valueDirection = (0 - 1) / abs(0 - 1)
					-1 / 1  = -1

valueDirection = (currentValue < previousVal) and -1 or 1



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
}
