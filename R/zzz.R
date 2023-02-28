# Hidden package environment
.pkgglobalenv <- new.env(parent = emptyenv())

.onLoad <- function(libname, pkgname) {
    .pkgglobalenv$ek <- list(
      ip = "127.0.0.1",
      port = 9000L,
      data_api = '/api/v1/data',
      api_key = NULL
    )
}