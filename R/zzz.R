# Hidden package environment
.pkgglobalenv <- new.env(parent = emptyenv())

.onLoad <- function(libname, pkgname) {
    .pkgglobalenv$ek <- list(
      api_key = NULL
    )
}