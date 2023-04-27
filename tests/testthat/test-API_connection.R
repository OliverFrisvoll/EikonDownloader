test_that("ek_set_APIKEY(), message check", {
    expect_error(ek_set_APIKEY(10L), "is not a string or NULL")
    expect_error(ek_set_APIKEY(15), "is not a string or NULL")
    expect_invisible(ek_set_APIKEY(NULL))
})


test_that("ek_get_APIKEY(), the function returns an error if there is no API_key set with ek_set_APIKEY()", {
    expect_error(ek_get_APIKEY(), "Missing API_KEY")
})


test_that("ek_fetch_port finds a numeric port, only works if Eikon is currently running", {
    skip_on_ci()
    skip_on_cran()
    expect_true(is.integer(ek_fetch_port()))
})

test_that("ek_get_APIKEY() finds port and sets API_KEY", {
    skip_on_ci()
    skip_on_cran()
    expect_equal(ek_set_APIKEY("APIKEY"), .pkgglobalenv$ek$port)
    expect_equal("APIKEY", .pkgglobalenv$ek$api_key)

    # Resetting to load time variables.
    .onLoad()
})


