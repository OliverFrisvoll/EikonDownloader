#' Fetch datagrid information from the Eikon API
#'
#' Before this function works you need to run the function ek_set_APIKEY() with a working app_key from the
#' Eikon/Refinitiv desktop.
#'
#' This package downloads information from the Eikon datagrid. The function is a wrapper around the Rust
#' function that does the actual work. To use this function you simply need to have an Eikon APP key, which you
#' get from the Eikon desktop app or the newer Refinitiv terminal. The function will then fetch the information
#' from the Eikon datagrid and return it as a dataframe. The desktop app needs to be running for this to work.
#'
#' @param instrument - Vector of Char, can be CUSIP, PERMID, rics any identifer that the Eikon can handle
#' @param fields - Vector of Char, fields to request from the datagrid
#' @param ... - List of named parameters, could be 'SDate' = '2021-07-01', 'EDate' = '2021-09-28', 'Frq' = 'D' for
#' daily data (Frq) with a given start (SDate) and end date (EDate). If no EDate is supplied, the function will
#' use todays date. You can pass other arguments like for instance curn = 'USD' to get the data in USD, change out USD
#' to any other currency to get the fields in that currency.
#' @param settings - List of bool settings, possibilities list(raw = false, field_name = false):
#'     raw : If the function should return the raw json (default false)
#'     field_name : if the function should return the field names (default false)
#'
#' @return dataframe or a list of raw data. At the moment i do not parse any column to a specific type, so all
#' columns are of type character. This is something I might change in the future, but only if i find a robust way
#' of doing this.
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

    if (!is.list(settings)) {
        cli::cli_abort(c(
          "ValueError",
          "x" = "settings is not of type list"
        ))
    }

    fields <- unique(fields)

    # Fetches the keyword arguments
    kwargs <- list(...)

    if ("SDate" %in% names(kwargs)) {
        if (inherits(kwargs$SDate, "Date")) {
            kwargs$SDate <- format(kwargs$SDate, "%Y-%m-%d")
        }
    }

    if ("EDate" %in% names(kwargs)) {
        if (inherits(kwargs$EDate, "Date")) {
            kwargs$EDate <- format(kwargs$EDate, "%Y-%m-%d")
        }
    }

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
      port = as.integer(ek_get_port())
    )

    if (identical(ret[[1]], "Error")) {
        cli::cli_warn(c(
          "Error",
          "x" = "{ret[[2]]}"
        ))
    } else if (length(names(ret)) > 0) {
        df <- as.data.frame(ret, stringsAsFactors = FALSE)
        # Convert "null" strings to NA
        df[] <- lapply(df, function(x) {
            if (is.character(x)) replace(x, x == "null", NA_character_) else x
        })
        df
    } else {
        ret
    }

}
