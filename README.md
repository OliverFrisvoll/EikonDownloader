
<!-- README.md is generated from README.Rmd. Please edit that file -->

# EikonDownloader

<!-- badges: start -->

[![R-CMD-check](https://github.com/OliverFrisvoll/EikonDownloader/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/OliverFrisvoll/EikonDownloader/actions/workflows/R-CMD-check.yaml)
[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

The goal of EikonDownloader is to allow the user to download timeseries
and datagrid data from the Eikon platform using the R programming
language.

## Installation

You can install the development version of EikonDownloader from
[GitHub](https://github.com/) with: Currently the only compiled version
of the package is for Windows, but the source code can be downloaded and
compiled for other operating systems.

``` r

install.packages(
  "https://github.com/OliverFrisvoll/EikonDownloader/releases/latest/download/EikonDownloader.zip",
  repos = NULL
)
```

To be able to use the tool there are a couple of things that needs to be
in order

1.  Open the Refinitiv Workspace, this program has to be running during
    every request. It can be minimized and closed down, it will work as
    long as this program is running in the background while you
    download.
2.  You need to create an Api key to be able to use the tool. This is
    done by typing “APPKEY” in the address bar of the Refinitiv
    application. At the very top of that page you can Register an
    application. Type in a display name and check the “Eikon Data API”
    checkbox. When you click “Register New App” an entry should show up
    further down with the application name and an Api Key, this key is
    the Api key used in for the tool.

## Example

### Setting API Key

To set the Api key you simply have to load the library and run the set
api key function.

``` r
library(EikonDownloader)

# Setting the api_key, switch out this key with your own key from the Refinitiv Workspace
ek_set_APIKEY(api_key)
```

### get_datagrid()

Examples of how to fetch data from the datagrid

``` r

CUSIPS <- c('88160R101', '594918104')

# Creating a df from downloaded data.
df <- get_datagrid(
  instrument = CUSIPS,
  fields = c('TR.RICCode', 'TR.Revenue', 'TR.IPODate')
)

head(df)
#>   Instrument RIC.Code      Revenue   IPO.Date
#> 1  88160R101   TSLA.O  81462000000 2010-06-09
#> 2  594918104   MSFT.O 198270000000 1986-03-13

# Time data from get_datagrid
df <- get_datagrid(
  instrument = c("AAPL.O", "TSLA.O"),
  fields = c('TR.CLOSE', 'TR.ASKPRICE', 'TR.BIDPRICE', 'TR.CLOSE.DATE'),
  SDate = "2022-01-03",
  EDate = "2022-01-05"
)
head(df)
#>   Instrument  Price.Close  Ask.Price  Bid.Price                 Date
#> 1     AAPL.O       182.01     182.01        182 2022-01-03T00:00:00Z
#> 2     AAPL.O        179.7     179.71     179.66 2022-01-04T00:00:00Z
#> 3     AAPL.O       174.92      174.9     174.78 2022-01-05T00:00:00Z
#> 4     TSLA.O 399.92626674 399.882933 399.836267 2022-01-03T00:00:00Z
#> 5     TSLA.O 383.19628347 383.196283  383.13295 2022-01-04T00:00:00Z
#> 6     TSLA.O 362.70630396 362.662971 362.539637 2022-01-05T00:00:00Z

# Time data from get_datagrid with currency conversion
df <- get_datagrid(
  instrument = c("AAPL.O", "TSLA.O"),
  fields = c('TR.CLOSE', 'TR.ASKPRICE', 'TR.BIDPRICE', 'TR.CLOSE.DATE'),
  SDate = "2022-01-03",
  EDate = "2022-01-05",
  curn = "JPY"
)
head(df)
#>   Instrument      Price.Close      Ask.Price      Bid.Price
#> 1     AAPL.O       20989.3932     20989.3932       20988.24
#> 2     AAPL.O        20870.358     20871.5194     20865.7124
#> 3     AAPL.O        20308.212       20305.89      20291.958
#> 4     TSLA.O 46119.4970804568 46114.49983356 46109.11831044
#> 5     TSLA.O 44504.4163622058 44504.41630762   44497.060813
#> 6     TSLA.O  42110.201889756  42105.1709331  42090.8518557
#>                   Date
#> 1 2022-01-03T00:00:00Z
#> 2 2022-01-04T00:00:00Z
#> 3 2022-01-05T00:00:00Z
#> 4 2022-01-03T00:00:00Z
#> 5 2022-01-04T00:00:00Z
#> 6 2022-01-05T00:00:00Z

# Can pass dates as Date objects
df <- get_datagrid(
  instrument = c("AAPL.O", "TSLA.O"),
  fields = c('TR.CLOSE', 'TR.CLOSE.DATE'),
  SDate = as.Date("2022-01-03"),
  EDate = as.Date("2022-01-05")
)
head(df)
#>   Instrument  Price.Close                 Date
#> 1     AAPL.O       182.01 2022-01-03T00:00:00Z
#> 2     AAPL.O        179.7 2022-01-04T00:00:00Z
#> 3     AAPL.O       174.92 2022-01-05T00:00:00Z
#> 4     TSLA.O 399.92626674 2022-01-03T00:00:00Z
#> 5     TSLA.O 383.19628347 2022-01-04T00:00:00Z
#> 6     TSLA.O 362.70630396 2022-01-05T00:00:00Z
```

Other fields can be found using the data item browser (DIB) application.
This application can be found in the Refinitiv Workspace.

### get_timeseries()

This is a function that can be used to fetch timeseries data using RIC
id’s

``` r

RICS <- c("AAPL.O", "TSLA.O")

df <- get_timeseries(
  rics = RICS,
  startdate = as.Date("2021-03-01"),
  enddate = as.Date("2021-03-10")
)
head(df)
#>              TIMESTAMP    HIGH  CLOSE    LOW   OPEN   COUNT    VOLUME    RIC
#> 1 2021-03-01T00:00:00Z  127.93 127.79 122.79 123.75  924487 116307892 AAPL.O
#> 2 2021-03-02T00:00:00Z  128.72 125.12 125.01 128.41  831904 102260945 AAPL.O
#> 3 2021-03-03T00:00:00Z  125.71 122.06 121.84 124.81  992159 112966340 AAPL.O
#> 4 2021-03-04T00:00:00Z   123.6 120.13 118.62 121.75 1689128 178154975 AAPL.O
#> 5 2021-03-05T00:00:00Z 121.935 121.42 117.57 120.98 1472276 153766601 AAPL.O
#> 6 2021-03-08T00:00:00Z     121 116.36 116.21 120.93 1540729 154376610 AAPL.O

# Minutely data
df <- get_timeseries(
  rics = RICS,
  startdate = as.Date("2022-08-03"),
  enddate = as.Date("2022-08-05"),
  interval = "minute"
)
head(df)
#>              TIMESTAMP   HIGH    LOW   OPEN  CLOSE COUNT VOLUME    RIC
#> 1 2022-08-03T00:00:00Z 160.03    160 160.03 160.01    26   7940 AAPL.O
#> 2 2022-08-03T08:01:00Z 160.34 159.45 159.45 160.06    77   2589 AAPL.O
#> 3 2022-08-03T08:02:00Z  160.2 160.01 160.09 160.18    64   2616 AAPL.O
#> 4 2022-08-03T08:03:00Z 160.21 160.02 160.15 160.14    42   1955 AAPL.O
#> 5 2022-08-03T08:04:00Z  160.2 160.12 160.18 160.14    38    887 AAPL.O
#> 6 2022-08-03T08:05:00Z 160.19 160.13 160.19 160.14    19    557 AAPL.O

# EndDate is optional
df <- get_timeseries(
  rics = RICS,
  startdate = as.Date("2023-03-03")
)
head(df)
#>              TIMESTAMP     HIGH  CLOSE      LOW    OPEN  COUNT   VOLUME    RIC
#> 1 2023-03-03T00:00:00Z   151.11 151.03   147.33 148.045 558707 70732297 AAPL.O
#> 2 2023-03-06T00:00:00Z    156.3 153.83   153.46 153.785 691990 87558028 AAPL.O
#> 3 2023-03-07T00:00:00Z 154.0299  151.6   151.13   153.7 496632 56182028 AAPL.O
#> 4 2023-03-08T00:00:00Z   153.47 152.87   151.83  152.81 405203 47204791 AAPL.O
#> 5 2023-03-09T00:00:00Z  154.535 150.59  150.225 153.559 480910 53833582 AAPL.O
#> 6 2023-03-10T00:00:00Z   150.94  148.5 147.6096  150.21 611458 68572400 AAPL.O
```
