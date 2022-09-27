test_that("ek_set_APIKEY(), message check", {
    expect_error(ek_set_APIKEY(10L), "is not a string or NULL")
    expect_error(ek_set_APIKEY(15), "is not a string or NULL")
    expect_invisible(ek_set_APIKEY(NULL))
    expect_invisible(ek_set_APIKEY("sder342fsd2e"))
})

test_that("API_Key can be set and then fetched with ek_set_APIKEY()", {
    expect_equal(ek_set_APIKEY("sdsds"), ek_get_APIKEY())
    ek_set_APIKEY(NULL)
})

test_that("ek_get_APIKEY(), the function returns an error if there is no API_key set with ek_set_APIKEY()", {
    expect_error(ek_get_APIKEY(), "Missing API_KEY")
})


test_that("ek_get_url, url_builder test", {
    expect_equal(ek_get_url(), "http://127.0.0.1:9000/api/v1/data")

    .pkgglobalenv$ek$base_url <- 'http://129.0.0.1'
    .pkgglobalenv$ek$port <- 9001L
    .pkgglobalenv$ek$data_api <- '/api/v2/data'
    expect_equal(ek_get_url(), "http://129.0.0.1:9001/api/v2/data")


    .pkgglobalenv$ek$base_url <- 'http://127.0.0.1'
    .pkgglobalenv$ek$port <- 9000L
    .pkgglobalenv$ek$data_api <- '/api/v1/data'
    expect_equal(ek_get_url(), "http://127.0.0.1:9000/api/v1/data")
})
