test_that("get_datagrid(), does not accept non char values", {
    expect_error(get_datagrid(10, 10), "instrument nor fields")
    expect_error(get_datagrid("10", 10), "fields")
    expect_error(get_datagrid(10, "10"), "instrument")
})


test_that("get_datagrid(), returns values for a correct Instrument and field", {
    skip_on_cran()
    skip_on_ci()

    load("test_data/app_key.RData")
    ek_set_APIKEY(app_key)

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
    load("test_data/app_key.RData")
    ek_set_APIKEY(app_key)

    RIC_TSLA <- data.frame(
      Instrument = c('88160R101', '5949182324104'),
      RIC.Code = c("TSLA.O", NA)
    )

    expect_equal(get_datagrid(c('88160R101', '5949182324104'), 'TR.RICCode'), RIC_TSLA)

    rm(RIC_TSLA)

    # Resetting to load time va
    .onLoad()
})


test_that("get_datagrid(), returns multiple rows for multiple fields", {
    skip_on_cran()
    skip_on_ci()
    load("test_data/app_key.RData")
    ek_set_APIKEY(app_key)

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
    load("test_data/app_key.RData")
    ek_set_APIKEY(app_key)

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


# test_that("get_datgrid(), invalid APP_KEY", {
#     # Could run on cran, but wouldn't be able to test the error
#     skip_on_cran()
#     skip_on_ci()
#     # load("test_data/app_key.RData")
#     # ek_set_APIKEY(app_key)
#     ek_set_APIKEY("INVALID_KEY")
#     expect_error(get_datagrid("MSFT.O", "TR.TRESGScore"), "Error")
#
#     # Resetting to load time va
#     .onLoad()
# })


test_that("get_datgrid(), passing date object", {
    skip_on_cran()
    skip_on_ci()
    load("test_data/app_key.RData")
    ek_set_APIKEY(app_key)

    test <- get_datagrid(
      instrument = c("MSFT.O", "IBM"),
      fields = "TR.TRESGScore",
      SDate = as.Date("2019-01-01"),
      EDate = as.Date("2021-01-01")
    )

    expect_true(is.data.frame(test))

    # Resetting to load time va
    .onLoad()
})


test_that("get_datgrid(), something that is not a list to settings", {
    load("test_data/app_key.RData")
    ek_set_APIKEY(app_key)

    expect_error(
      get_datagrid(
        instrument = "MSFT.O",
        fields = "TR.TRESGScore",
        SDate = as.Date("2019-01-01"),
        EDate = as.Date("2021-01-01"),
        settings = "something"
      ),
      "ValueError"
    )

    # Resetting to load time va
    .onLoad()
})


test_that("get_datgrid(), tests if raw setting work", {
    skip_on_cran()
    skip_on_ci()
    load("test_data/app_key.RData")
    ek_set_APIKEY(app_key)

    test <- get_datagrid(
      instrument = c("MSFT.O", "IBM"),
      fields = "TR.TRESGScore",
      SDate = as.Date("2019-01-01"),
      EDate = as.Date("2021-01-01"),
      settings = list(raw = TRUE)
    )

    expect_true(!is.data.frame(test))

    # Resetting to load time va
    .onLoad()
})


test_that("get_datgrid(), tests if field_name setting work", {
    skip_on_cran()
    skip_on_ci()
    load("test_data/app_key.RData")
    ek_set_APIKEY(app_key)

    test <- get_datagrid(
      instrument = c("MSFT.O", "IBM"),
      fields = "TR.CLOSE",
      settings = list(field_name = TRUE)
    )

    test <- names(test)[2]
    expect_equal(test, "TR.CLOSE")

    # Resetting to load time va
    .onLoad()
})
