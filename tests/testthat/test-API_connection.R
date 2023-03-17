test_that("ek_set_APIKEY(), message check", {
    expect_error(ek_set_APIKEY(10L), "is not a string or NULL")
    expect_error(ek_set_APIKEY(15), "is not a string or NULL")
    expect_invisible(ek_set_APIKEY(NULL))
})


test_that("ek_get_APIKEY(), the function returns an error if there is no API_key set with ek_set_APIKEY()", {
    expect_error(ek_get_APIKEY(), "Missing API_KEY")
})


test_that("Tests if it's possible to set and fetch port, address, url and such", {
    expect_equal(ek_get_port(), 9000L)
    expect_equal(ek_get_address(), "http://127.0.0.1:9000/api/v1/data")

    ek_set_port(9001L)
    expect_equal(ek_get_port(), 9001L)
    expect_equal(ek_get_address(), "http://127.0.0.1:9001/api/v1/data")

    # Resetting to load time variables.
    .onLoad()
})

test_that("ek_fetch_port finds a numeric port, only works if Eikon is currently running", {
    expect_true(is.integer(ek_fetch_port()))
})
