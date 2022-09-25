test_that("check_if_date", {
    expect_equal(check_if_date("2010-10-01"), lubridate::ymd("2010-10-01"))
    expect_equal(check_if_date(lubridate::ymd("2010-10-01")), lubridate::ymd("2010-10-01"))
    expect_error(check_if_date("2010-1000-10"))
    # expect_equal(check_if_date())
})


test_that("date_to_JSON", {
    expect_equal(date_to_JSON(lubridate::ymd("2001-01-01")), "2001-01-01T00:00:00Z")
    expect_equal(date_to_JSON(lubridate::parse_date_time("2001-01-01 20:10:10", "Ymd HMS")), "2001-01-01T20:10:10Z")
})


test_that("seq_of_dates", {
    expect_error(seq_of_dates(lubridate::ymd("2001-01-01"), lubridate::ymd("2001-01-02"), "dailySdsd", 50))
    expect_equal(seq_of_dates(lubridate::ymd("2001-01-01"), lubridate::ymd("2005-01-01"), "daily", 1000), data.frame(
      start = c(lubridate::ymd("2001-01-01"), lubridate::ymd("2003-09-27")),
      end = c(lubridate::ymd("2003-09-28"), lubridate::ymd("2005-01-01"))
    ))
    expect_equal(seq_of_dates(lubridate::ymd("2004-01-01"), lubridate::ymd("2005-01-01"), "weekly", 100), data.frame(
      start = lubridate::ymd("2004-01-01"),
      end = lubridate::ymd("2005-01-01")
    ))
    expect_equal(seq_of_dates(lubridate::ymd("2020-01-01"), lubridate::ymd("2020-02-01"), "hour", 600), data.frame(
      start = c(lubridate::ymd("2020-01-01"), lubridate::ymd("2020-01-25")),
      end = c(lubridate::ymd("2020-01-26"), lubridate::ymd("2020-02-01"))
    ))
    expect_error(seq_of_dates(lubridate::ymd("2020-05-01"), lubridate::ymd("2020-02-01"), "hour", 100), "Date Error")
    expect_warning(seq_of_dates(lubridate::ymd("2020-01-01"), lubridate::ymd("2020-03-01"), "hour", 3001), "Too many rows")

})

# test_that("calculate_returns()", {
#     prices <- c(10, 12, 14, 16, 20)
#     simple_answer <- c(NA, 0.1823, 0.1542, 0.1335, 0.2231)
#     log_answer <- c(NA, 0.1823, 0.1542, 0.1335, 0.2231)
#     print(calculate_returns(prices, "log"))
#
# })
