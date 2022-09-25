
<!-- README.md is generated from README.Rmd. Please edit that file -->

# EikonDownloader

<!-- badges: start -->

[![R-CMD-check](https://github.com/OliverFrisvoll/EikonDownloader/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/OliverFrisvoll/EikonDownloader/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

The goal of EikonDownloader is to allow the user to download timeseries
and datagrid data from the Eikon platform using purely the R programming
language.

## Installation

You can install the development version of EikonDownloader from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("OliverFrisvoll/EikonDownloader")
```

To be able to use the tool there are a couple of things that needs to be
in order

1.  Open the Refinitiv Workspace, this program has to be running during
    every request. It can be minimized and closed down, it will work as
    long as this program is running in the background while you
    download.
2.  You need to create an Api key to be able to use the tool. This is
    done by typing “Api Key Generator” in the address bar of the
    Refinitiv application. At the very top of that page you can Register
    an application. Type in a display name and check the “Eikon Data
    API” checkbox. When you click “Register New App” an entry should
    show up further down with the application name and an Api Key, this
    key is the Api key used in for the tool.

## Example

### Setting API Key

To set the Api key you simply have to load the library and run the set
api key function.

``` r
library(EikonDownloader)

# Setting the api_key, switch out this key with your own key from the Refinitiv Workspace
ek_set_APIKEY('f63dab2c283546a187cd6c59894749a2228ce486')
```

### get_datagrid()

Examples of how to fetch data from the datagrid using CUSIP id’s

``` r
CUSIPS <- c('88160R101', '594918104')

# Downloading the data
df <- get_datagrid(
  instrument = CUSIPS,
  fields = c('TR.RICCode', 'TR.Revenue', 'TR.IPODate')
)

head(df)
#>   Instrument RIC.Code    Revenue   IPO.Date
#> 1  88160R101   TSLA.O 5.3823e+10 2010-06-09
#> 2  594918104   MSFT.O 1.9827e+11 1986-03-13
```

Other fields can be found using the Refinitiv platform, there is usually
a question mark next to the field name that shows what it is called.

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
#>    TIMESTAMP    HIGH  CLOSE    LOW   OPEN   COUNT    VOLUME RIC.Code
#> 1 2021-03-01 127.930 127.79 122.79 123.75  924487 116307892   AAPL.O
#> 2 2021-03-02 128.720 125.12 125.01 128.41  831904 102260945   AAPL.O
#> 3 2021-03-03 125.710 122.06 121.84 124.81  992159 112966340   AAPL.O
#> 4 2021-03-04 123.600 120.13 118.62 121.75 1689128 178154975   AAPL.O
#> 5 2021-03-05 121.935 121.42 117.57 120.98 1472276 153766601   AAPL.O
#> 6 2021-03-08 121.000 116.36 116.21 120.93 1540729 154376610   AAPL.O
```

### fetch_timeseries()

This is a wrapper around get_timeseries that takes CUSIP as a parameter
instead of RIC

``` r
CUSIPS <- c('88160R101', '594918104')

df <- fetch_timeseries(
  CUSIP = CUSIPS,
  start_date = as.Date("2021-03-01"),
  end_date = as.Date("2021-03-10")
)

head(df)
#>    TIMESTAMP     HIGH    CLOSE      LOW     OPEN   COUNT    VOLUME RIC.Code
#> 1 2021-03-01 239.6664 239.4764 228.3498 230.0364  820202  81408798   TSLA.O
#> 2 2021-03-02 240.3698 228.8131 228.3331 239.4264  842209  71196545   TSLA.O
#> 3 2021-03-03 233.5664 217.7331 217.2348 229.3298 1046907  90623971   TSLA.O
#> 4 2021-03-04 222.8164 207.1465 199.9998 218.5998 2044214 197758428   TSLA.O
#> 5 2021-03-05 209.2804 199.3165 179.8298 208.6865 2557906 268189645   TSLA.O
#> 6 2021-03-08 206.7081 187.6665 186.2631 200.1831 1582492 155361029   TSLA.O
#>   Instrument
#> 1  88160R101
#> 2  88160R101
#> 3  88160R101
#> 4  88160R101
#> 5  88160R101
#> 6  88160R101
```
