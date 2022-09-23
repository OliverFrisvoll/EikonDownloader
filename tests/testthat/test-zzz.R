test_that("Testing default values", {
    ek_test <- list(
      base_url = 'http://127.0.0.1',
      port = 9000L,
      api_url = '/api/v1/data'
    )
    expect_equal(.pkgglobalenv$ek, ek_test)
})
