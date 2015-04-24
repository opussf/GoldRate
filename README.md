# GoldRate

[![Build Status](https://travis-ci.org/opussf/GoldRate.svg?branch=master)](https://travis-ci.org/opussf/GoldRate)

## Idea
This addon is in response to the WoW Token release.

The token lets users buy a token for $20US from the store, then sell it on the AH.  The buyer can then redeem it for 30 days of game time.

The suggested gold cost will fluctuate based on unknown parameters, but should be available from the Auction House.

The idea of this addon is to track the price of the tokens over time, to track the amount of gold available on any single realm, and the rate of gain, with the goal of trying to generate enough gold every month to pay for playing.

## Some math
[Hotmath.com] describes how to use the Least Square Method to find the Line of Best Fist of a series of ordered pairs of values.

[OriginLab] gives an overview of Linear and Polynominal Fitting process. Though, much of the site seems to be broken.

[Wolfram] gives a concise explanation. Including error determination.

## Versions:
```
0.3     Initial Goal acceptance and rate calculations
0.2     Retooled data collection as a single set of data points.
0.1     Initial work
```

[Hotmath.com]:http://hotmath.com/hotmath_help/topics/line-of-best-fit.html
[OriginLab]:http://www.originlab.com/index.aspx?go=Products/Origin/DataAnalysis/CurveFitting/LinearAndPolynomialFitting
[Wolfram]:http://mathworld.wolfram.com/LeastSquaresFitting.html