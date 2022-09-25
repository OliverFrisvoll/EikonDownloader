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

# Makes sure the API_KEY is reset
ek_set_APIKEY(NULL)
