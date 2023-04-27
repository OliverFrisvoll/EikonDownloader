test_that("get_timeseries(), returns error on faulty types", {
    expect_error(get_timeseries(
      rics = "2324",
      fields = 2424,
      startdate = as.Date("2001-01-10"),
      enddate = as.Date("2001-01-10"),
      interval = "daily"
    ), "fields")

    expect_error(get_timeseries(
      rics = 2324,
      fields = "2424",
      startdate = as.Date("2001-01-10"),
      enddate = as.Date("2001-01-10"),
      interval = "daily"
    ), "rics")

    expect_error(get_timeseries(
      rics = "2324",
      fields = "2424",
      startdate = "2001-01-10",
      enddate = as.Date("2001-01-10"),
      interval = "daily"
    ), "Date")

    expect_error(get_timeseries(
      rics = "2324",
      fields = "2424",
      startdate = as.Date("2001-01-10"),
      enddate = "2001-01-10",
      interval = "daily"
    ), "Date")

    expect_error(get_timeseries(
      rics = "2324",
      fields = "2424",
      startdate = as.Date("2001-01-10"),
      enddate = as.Date("2001-01-10"),
      interval = 2323
    ), "interval")

})

test_that("get_timeseries(), accepts only getting startdate", {
    skip_on_cran()
    skip_on_ci()
    load("test_data/app_key.RData")
    ek_set_APIKEY(app_key)
    df <- get_timeseries(
      rics = "AAPL.O",
      fields = "CLOSE",
      startdate = Sys.Date() - 5,
      interval = "daily"
    )
    expect_true(is.data.frame(df))
    .onLoad()
})
