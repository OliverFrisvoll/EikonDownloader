## ---- include = FALSE---------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)
library(lemon)
knit_print.data.frame <- lemon_print
devtools::load_all()

## ----install, eval = FALSE----------------------------------------------------
#  install.packages("EikonDownloader", repos = "https://oliverfrisvoll.r-universe.dev")

## ----Devtools, eval = FALSE---------------------------------------------------
#  devtools::install_github("oliverfrisvoll/EikonDownloader")

## ----setup--------------------------------------------------------------------
library(EikonDownloader)
ek_set_APIKEY("ff375f19768843bdb56dd3c7c3387ee5e98b1d88")

## ----get_datagrid, render=lemon_print-----------------------------------------
# The RIC code for Apple Inc is AAPL.O
instruments <- "APPL.O"

# The fields we want to download, in this case ISIN and IPO date. These can be found using the
# Data Item Browser (DIB) app on the Eikon Terminal or Refinitiv Workspace. (Just type in DIB in
# the search bar)
fields <- c("TR.ISIN", "TR.IPODate")

df <- get_datagrid("AAPL.O", c("TR.ISIN", "TR.IPODate"))
head(df)

## ----get_datagrid_isin, render=lemon_print------------------------------------
isin <- "US0378331005"
df <- get_datagrid(isin, c("TR.RIC", "TR.IPODate"))
head(df)

## ----datagrid_multiple, render=lemon_print------------------------------------
instruments <- c("AAPL.O", "MSFT.O", "GOOGL.O", "XOM")
fields <- c("TR.PE", "TR.EVMean", "TR.CLOSE", "TR.ASKPRICE", "TR.BIDPRICE")

df <- get_datagrid(instruments, fields)
head(df)

## ----datagridclean, render=lemon_print----------------------------------------
df <- get_datagrid(instruments, fields, settings = list(field_name = TRUE))
head(df)

## ----addDate, render=lemon_print----------------------------------------------
# Adding a field to the field character vector
fields <- c(fields, "TR.CLOSE.DATE")
df <- get_datagrid(instruments, fields, settings = list(field_name = TRUE))
head(df)
# Parsing the ISO8601 date to a date object
df$TR.CLOSE.DATE <- df$TR.CLOSE.DATE |>
  lubridate::ymd_hms() |>
  as.Date()

head(df)

## ----dgtimeseries, render=lemon_print-----------------------------------------
df <- get_datagrid(instruments, fields, SDate = "2017-05-01", EDate = "2017-05-05", settings = list(field_name = TRUE))
df$TR.CLOSE.DATE <- df$TR.CLOSE.DATE |>
  lubridate::ymd_hms() |>
  as.Date()
head(df)

## ----dgtimeseries_curn, render=lemon_print------------------------------------

df <- get_datagrid(
  instruments,
  fields,
  SDate = "2017-05-01",
  EDate = "2017-05-05",
  curn = "EUR",
  settings = list(field_name = TRUE)
)

df$TR.CLOSE.DATE <- df$TR.CLOSE.DATE |>
  lubridate::ymd_hms() |>
  as.Date()
head(df)


## ----dgtimeseries_frq, render=lemon_print-------------------------------------

df <- get_datagrid(
  instruments,
  fields,
  SDate = "2017-01-01",
  EDate = "2017-05-05",
  curn = "EUR",
  Frq = "W",
  settings = list(field_name = TRUE)
)

df$TR.CLOSE.DATE <- df$TR.CLOSE.DATE |>
  lubridate::ymd_hms() |>
  as.Date()
head(df)


## ----get_timeseries, render=lemon_print---------------------------------------
df <- get_timeseries(
  instruments,
  startdate = Sys.Date() - 1,
  enddate = Sys.Date(),
  interval = "minute" # if not supplied, default is daily
)

df$TIMESTAMP <- df$TIMESTAMP |>
  lubridate::ymd_hms()

head(df, 10)

