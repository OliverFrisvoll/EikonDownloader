test_that("ek_set_APIKEY(), message check", {
    expect_error(ek_set_APIKEY(10L), "is not a string or NULL")
    expect_error(ek_set_APIKEY(15), "is not a string or NULL")
    expect_invisible(ek_set_APIKEY(NULL))
})


test_that("ek_get_APIKEY(), the function returns an error if there is no API_key set with ek_set_APIKEY()", {
    expect_error(ek_get_APIKEY(), "Missing API_KEY")
})

