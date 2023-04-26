#' Get timeseries data from Eikon using RIC as identifier
#'
#' Returns a timeseries of data for the given rics for the given timeperiod and interval.
#' The fields can be specified, by default it returns all the fields
#'
#' @param rics - Char vector of rics for the information requested
#' @param fields - Fields to return, can be found on Refinitiv Workspace
#' @param startdate - Date, start date of the query
#' @param enddate - Date, end date of the query
#' @param interval - char, interval of data: (minute / hour / daily / weekly / monthly / quarterly / yearly)
#'
#' @return A dataframe with the data requested
#'
#' @export
#'
get_timeseries <- function(rics, fields = '*', startdate, enddate = NULL, interval = 'daily') {

    # Type checks
    if (!is.character(rics)) {
        cli::cli_abort(c(
          "ValueError",
          "x" = "rics is not of type char"
        ))
    }
    if (!is.character(fields)) {
        cli::cli_abort(c(
          "ValueError",
          "x" = "fields is not of type char"
        ))
    }
    if (!lubridate::is.Date(startdate)) {
        cli::cli_abort(c(
          "ValueError",
          "x" = "startdate is not of type Date"
        ))
    }
    if (!is.null(enddate) && !lubridate::is.Date(enddate)) {
        cli::cli_abort(c(
          "ValueError",
          "x" = "enddate is not of type Date"
        ))
    }


    if (!is.character(interval)) {
        cli::cli_abort(c(
          "ValueError",
          "x" = "interval is not of type char"
        ))
    }

    # Changing interval to lowercase
    interval <- tolower(interval)

    # 2020-01-01T00:00:00
    # Convert startdate to iso8601
    startdate <- paste0(lubridate::format_ISO8601(startdate), "T00:00:00")
    if (is.null(enddate)) {
        enddate <- Sys.Date()
    }
    enddate <- paste0(lubridate::format_ISO8601(enddate), "T00:00:00")

    api <- ek_get_APIKEY()

    ret <- rust_get_ts(
      c(rics),
      c(fields),
      interval,
      startdate,
      enddate,
      api,
      ek_get_port()
    )

    if (ret[1] == "Error") {
        cli::cli_warn(c(
          "Error",
          "x" = "{ret[2]}"
        ))
    } else if (length(names(ret)) > 0) {
        # Would be better with a non dplyr solution, but here we are
        dplyr::mutate(data.frame(ret), dplyr::across(where(is.character), ~dplyr::na_if(., "null")))
    } else {
        ret
    }

}
