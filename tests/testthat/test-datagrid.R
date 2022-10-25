test_that("get_datagrid(), does not accept non char values", {
    expect_error(get_datagrid(10, 10), "instrument nor fields")
    expect_error(get_datagrid("10", 10), "fields")
    expect_error(get_datagrid(10, "10"), "instrument")
})


test_that("get_datagrid(), returns values for a correct Instrument and field", {
    skip_on_cran()
    skip_on_ci()
    ek_set_APIKEY('f63dab2c283546a187cd6c59894749a2228ce486')

    RIC_TSLA_MSFT <- data.frame(
      Instrument = c("88160R101", "594918104"),
      RIC.Code = c("TSLA.O", "MSFT.O")
    )

    expect_equal(get_datagrid(c('88160R101', '594918104'), 'TR.RICCode'), RIC_TSLA_MSFT)

    rm(RIC_TSLA_MSFT)
    ek_set_APIKEY(NULL)
})


test_that("get_datagrid(), returns values for when one Instrument is faulty and field is correct", {
    skip_on_cran()
    skip_on_ci()
    ek_set_APIKEY('f63dab2c283546a187cd6c59894749a2228ce486')

    RIC_TSLA <- data.frame(
      Instrument = "88160R101",
      RIC.Code = "TSLA.O"
    )

    expect_equal(get_datagrid(c('88160R101', '5949182324104'), 'TR.RICCode'), RIC_TSLA)

    rm(RIC_TSLA)
    ek_set_APIKEY(NULL)
})


test_that("get_datagrid(), if supplied a faulty field, returns an error", {
    skip_on_cran()
    skip_on_ci()
    ek_set_APIKEY('f63dab2c283546a187cd6c59894749a2228ce486')

    expect_error(get_datagrid(c('88160R101', '594918104'), 'TR.sds'), "No Results")
    ek_set_APIKEY(NULL)
})

test_that("get_datagrid(), returns multiple rows for multiple fields", {
    skip_on_cran()
    skip_on_ci()
    ek_set_APIKEY('f63dab2c283546a187cd6c59894749a2228ce486')

    LOT_IPO <- data.frame(
      Instrument = c("AAPL.O", "TSLA.O"),
      CF_LOTSIZE = c(100, 100),
      IPO.Date = c("1980-12-12", "2010-06-09")
    )

    expect_equal(get_datagrid(c('AAPL.O', 'TSLA.O'), c('CF_LOTSIZE', 'TR.IPODate')), LOT_IPO)

    rm(LOT_IPO)
    ek_set_APIKEY(NULL)
})

test_that("get_datagrid(), accepts keyword arguments", {
    skip_on_cran()
    skip_on_ci()
    ek_set_APIKEY('f63dab2c283546a187cd6c59894749a2228ce486')

    ESG <- data.frame(
      Instrument = c("MSFT.O", "IBM", "TSLA.O", "AAPL.O", "NFLX.O"),
      ESG.Score = c(92, 72, 63, 77, 29)
    )

    expect_equal(get_datagrid(c("MSFT.O", "IBM", "TSLA.O", "AAPL.O", "NFLX.O"), "TR.TRESGScore", SDate =
      "2021-07-07"), ESG, tolerance = 0.5)

    rm(ESG)
    ek_set_APIKEY(NULL)
})

test_that("get_datgrid(), check is empty results somewhere is accepted", {
    skip_on_cran()
    skip_on_ci()
    ek_set_APIKEY('f63dab2c283546a187cd6c59894749a2228ce486')

    df <- get_datagrid(
      instrument = c('USDSB3L1Y=', "USDSB3L2Y="),
      fields = c('TR.BIDPRICE', 'TR.ASKPRICE'),
      SDate = "2010-01-01",
      EDate = "2010-03-01",
      Frq = "D"
    )
    expect_true(ncol(df) == 3)
    expect_true(nrow(df) == 81)

    ek_set_APIKEY(NULL)
})


# Makes sure the API_KEY is reset
ek_set_APIKEY(NULL)
