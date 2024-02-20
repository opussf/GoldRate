# GoldRate

![Build Status](https://github.com/opussf/GoldRate/actions/workflows/normal_test.yml/badge.svg?branch=master)

## Idea
This addon is in response to the WoW Token release.

The token lets users buy a token for $20US from the store, then sell it on the AH for gold.
The buyer can then redeem it for 30 days of game time.
The suggested gold cost will fluctuate based on unknown parameters.

The idea of this addon is to track the price of the tokens over time, to track your amount of gold available on any single realm, and the rate of gain, with the goal of trying to generate enough gold every month to pay for playing.
It also includes

With the axium of "Buy low, sell high", those buying tokens for game time want to buy low.
Those selling tokens for gold want to sell high.
Those buying token for game time want to buy low.


I'm not going to even tackle the idea of price predictions, only the tracking of historic data.

## Some math
[Hotmath.com] describes how to use the Least Square Method to find the Line of Best Fist of a series of ordered pairs of values.

[OriginLab] gives an overview of Linear and Polynominal Fitting process. Though, much of the site seems to be broken.

[Wolfram] gives a concise explanation. Including error determination.

[Gaussian elimination]

## Display
Tracking data is only a viable idea and worth while if you can use that data to allow the user to make informed decisions.
To that end, the understanding of what decisions are to be made from the data, and how the data will be used in general is required to determine how to consume the data.



## Cautions
There are 3 types of lies: Lies, damn lies, and [statistics].

## Versions:
```
0.3     Initial Goal acceptance and rate calculations
0.2     Retooled data collection as a single set of data points.
0.1     Initial work
```

[Hotmath.com]:http://hotmath.com/hotmath_help/topics/line-of-best-fit.html
[OriginLab]:http://www.originlab.com/index.aspx?go=Products/Origin/DataAnalysis/CurveFitting/LinearAndPolynomialFitting
[Wolfram]:http://mathworld.wolfram.com/LeastSquaresFitting.html
[Gaussian elimination]:http://en.wikipedia.org/wiki/Gaussian_elimination
[statistics]:http://en.wikipedia.org/wiki/Misuse_of_statistics