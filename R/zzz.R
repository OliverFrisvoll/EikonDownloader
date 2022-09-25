# Hidden package environment
.pkgglobalenv <- new.env(parent = emptyenv())

.onLoad <- function(libname, pkgname) {
    # TODO: Check tests for this again
    .pkgglobalenv$ek <- list(
      base_url = 'http://127.0.0.1',
      port = 9000L,
      api_url = '/api/v1/data',
      api_key = NULL
    )
}