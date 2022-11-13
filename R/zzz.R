# Hidden package environment
.pkgglobalenv <- new.env(parent = emptyenv())

.onLoad <- function(libname, pkgname) {
    .pkgglobalenv$ek <- list(
      base_url = 'http://127.0.0.1',
      port = 9000L,
      data_api = '/api/v1/data',
      search_api = '/api/rdp/discovery/searchlight/v1',
      api_key = NULL
    )
    .pkgglobalenv$rd <- list(
      searchViewParams = c(
        "Query",
        "Filter",
        "View",
        "OrderBy",
        "Boost",
        "Select",
        "Top",
        "Skip",
        "GroupBy",
        "GroupCount"
      )
    )
}