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
#' @param settings - List of bool settings, possibilities:
#'     raw : If the function should return the raw json (default false)
#'     field_name : if the function should return the field names (default false)
#'
#' @return dataframe of the information requested
#'
#' @export
get_datagrid <- function(instrument, fields, ..., settings = list(raw = FALSE)) {

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
          Frq = "D"
        )
    }


    api <- ek_get_APIKEY()
    ret <- rust_get_dg(
      instruments = c(instrument),
      fields = c(fields),
      param = kwargs,
      settings = settings,
      api = api,
      ek_get_port()
    )

    if (ret[1] == "Error") {
        cli::cli_warn(c(
          "Error",
          "x" = "{ret[2]}"
        ))
    } else if (length(names(ret)) > 0) {
        data.frame(ret)
    } else {
        ret
    }

}

