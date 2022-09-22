
test_that("check_if_date", {
    expect_equal(check_if_date("2010-10-01"), ymd("2010-10-01"))
    expect_equal(check_if_date(ymd("2010-10-01")), ymd("2010-10-01"))
    expect_error(check_if_date("2010-1000-10"))
})


test_that("date_to_JSON", {
    expect_equal(date_to_JSON(ymd("2001-01-01")), "2001-01-01T00:00:00Z")
    expect_equal(date_to_JSON(parse_date_time("2001-01-01 20:10:10", "Ymd HMS")), "2001-01-01T20:10:10Z")
})


test_that("seq_of_dates", {
    expect_error(seq_of_dates(ymd("2001-01-01"), ymd("2001-01-02"), "dailySdsd", 50))
    expect_equal(seq_of_dates(ymd("2001-01-01"), ymd("2005-01-01"), "daily", 1000), data.frame(
      start = c(ymd("2001-01-01"), ymd("2003-09-27")),
      end = c(ymd("2003-09-28"), ymd("2005-01-01"))
    ))
    expect_equal(seq_of_dates(ymd("2004-01-01"), ymd("2005-01-01"), "weekly", 100), data.frame(
      start = ymd("2004-01-01"),
      end = ymd("2005-01-01")
    ))
    expect_equal(seq_of_dates(ymd("2020-01-01"), ymd("2020-02-01"), "hour", 600), data.frame(
      start = c(ymd("2020-01-01"), ymd("2020-01-25")),
      end = c(ymd("2020-01-26"), ymd("2020-02-01"))
    ))
    expect_error(seq_of_dates(ymd("2020-05-01"), ymd("2020-02-01"), "hour", 100))
    expect_warning(seq_of_dates(ymd("2020-01-01"), ymd("2020-03-01"), "hour", 3001))

})
