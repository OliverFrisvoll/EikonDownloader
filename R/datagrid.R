#' Fetching information from the datagrid
#'
#' Tries to fetch information from the Eikon datagrid location. The direction that seems to work for this is
#' 'DataGrid_StandardAsync' even though I haven't implimented Async possibilities, could possibly do it with the
#' packages promises, but I doesn't seem necessary at the moment. If needed it should be implimented into a loop
#' for the send_json_request function.
#'
#' @param instrument - Vector of Char, can be CUSIP, rics
#' @param fields - Vector of Char, fields to request from the datagrid
#' @param ... - List of named parameters, could be 'SDate' = '2021-07-01', 'EDate' = '2021-09-28', 'Frq' = 'D' for
#' daily data (Frq) with a given start (SDate) and end date (EDate)
#'
#' @return dataframe of the information requested
#'
#' @export
get_datagrid <- function(instrument, fields, ...) {

    # The limit value is around 10,000 data points for version 1.0.2 and below.
    # No enforced limit for version 1.1.0 and above.
    # However, it still has a server timeout around 300 seconds.

    # Typecheck
    if (!is.character(instrument) && !is.character(fields)) {
        cli::cli_abort(c(
          "ValueError",
          "x" = "Neither instrument nor fields are of type char"
        ))
    } else if (!is.character(instrument)) {
        cli::cli_abort(c(
          "ValueError",
          "x" = "instrument is not of type char"
        ))
    } else if (!is.character(fields)) {
        cli::cli_abort(c(
          "ValueError",
          "x" = "fields is not of type char"
        ))
    }

    # Fetches the keyword arguments
    kwargs <- list(...)

    if (length(kwargs) == 0) {
        kwargs <- list(
          "Frq" = "D"
        )
    }

    api <- ek_get_APIKEY()

    rust_get_dg(
      instruments = instrument,
      fields = fields,
      param = kwargs,
      api = api,
      ip = ip,
      port = port
    ) |>
      data.frame()
}

