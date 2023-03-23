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

