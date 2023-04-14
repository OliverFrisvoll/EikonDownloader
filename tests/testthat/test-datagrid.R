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

    # Resetting to load time va
    .onLoad()
})


test_that("get_datagrid(), returns values for when one Instrument is faulty and field is correct", {
    skip_on_cran()
    skip_on_ci()
    ek_set_APIKEY('f63dab2c283546a187cd6c59894749a2228ce486')

    RIC_TSLA <- data.frame(
      Instrument = c('88160R101', '5949182324104'),
      RIC.Code = c("TSLA.O", NA)
    )

    expect_equal(get_datagrid(c('88160R101', '5949182324104'), 'TR.RICCode'), RIC_TSLA)

    rm(RIC_TSLA)

    # Resetting to load time va
    .onLoad()
})


test_that("get_datagrid(), if supplied a faulty field, returns an error", {
    skip_on_cran()
    skip_on_ci()
    ek_set_APIKEY('f63dab2c283546a187cd6c59894749a2228ce486')

    expect_error(get_datagrid(c('88160R101', '594918104'), 'TR.sds'), "No Results")

    # Resetting to load time va
    .onLoad()
})


test_that("Testing edge case of field not existing in one RIC", {
    skip_on_cran()
    skip_on_ci()
    ek_set_APIKEY('f63dab2c283546a187cd6c59894749a2228ce486')

    expect_error(
      get_datagrid(
        instrument = '4297589374',
        fields = c('TR.CLOSE', 'TR.CLOSE.DATE'),
        SDate = "2020-01-01",
        EDate = "2023-01-01",
      ),
      "No Results"
    )


    # Resetting to load time va
    .onLoad()
})


test_that("get_datagrid(), returns multiple rows for multiple fields", {
    skip_on_cran()
    skip_on_ci()
    ek_set_APIKEY('f63dab2c283546a187cd6c59894749a2228ce486')

    LOT_IPO <- data.frame(
      Instrument = c("AAPL.O", "TSLA.O"),
      ISIN = c("US0378331005", "US88160R1014"),
      IPO.Date = c("1980-12-12", "2010-06-09")
    )

    expect_equal(get_datagrid(c('AAPL.O', 'TSLA.O'), c('TR.ISIN', 'TR.IPODate')), LOT_IPO)

    rm(LOT_IPO)

    # Resetting to load time va
    .onLoad()
})

test_that("get_datagrid(), accepts keyword arguments", {
    skip_on_cran()
    skip_on_ci()
    ek_set_APIKEY('f63dab2c283546a187cd6c59894749a2228ce486')

    test <- get_datagrid(
      instrument = c("MSFT.O", "IBM", "TSLA.O", "AAPL.O", "NFLX.O"),
      fields = "TR.TRESGScore",
      SDate = "2019-01-01",
      EDate = "2021-01-01"
    )

    expect_equal(nrow(test), 10)
    expect_equal(ncol(test), 2)
    expect_equal(names(test), c("Instrument", "ESG.Score"))

    rm(test)

    # Resetting to load time va
    .onLoad()
})


# test_that("get_datgrid(), check is empty results somewhere is accepted", {
#     skip_on_cran()
#     skip_on_ci()
#     ek_set_APIKEY('f63dab2c283546a187cd6c59894749a2228ce486')
#
#     testgd <<- get_datagrid(
#       instrument = c('USDSB3L1Y=', "USDSB3L2Y="),
#       fields = c('TR.BIDPRICE', 'TR.ASKPRICE', 'TR.CLOSEPRICE'),
#       SDate = "2010-01-01",
#       EDate = "2010-03-01",
#       Frq = "D"
#     )
#
#     expect_equal(ncol(df), 4)
#     expect_equal(nrow(df), 81)
#
#
#     # Resetting to load time va
#     .onLoad()
# })
