#' A function to search through Eikon !!WIP!!
#' TODO: Write documentation
#'
#'
#' parameters: Query, Filter, View, OrderBy, Boost, Select, Top, Skip, GroupBy, GroupCount
#'
#' @export
search_view <- function(..., API = "/", debug = FALSE) {
    ek_set_APIKEY('f63dab2c283546a187cd6c59894749a2228ce486')

    kwargs <- list(...)

    # if (names(kwargs) %notin% .pkgglobalenv$rd$searchViewParams) {
    #     cli::cli_abort(c(
    #       "ParamError",
    #       "x" = "One or more of your params are not available"
    #     ))
    # }

    payload <- kwargs

    POST_searchView(payload, service = API, debug = debug)
}
