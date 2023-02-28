#' Get timeseries data from Eikon using RIC as identifier
#'
#' Returns a timeseries of data for the given rics for the given timeperiod and interval.
#' The fields can be specified, by default it returns all the fields
#'
#' @param rics - Char vector of rics for the information requested
#' @param fields - Fields to return, can be found on the Refinitiv Workspace
#' @param startdate - Date, start date of the query
#' @param enddate - Date, end date of the query
#' @param interval - char, interval of data: (minute / hour / daily / weekly / monthly / quarterly / yearly)
#'
#' @return A dataframe with the data requested
#'
#' @export
get_timeseries <- function(rics, fields = '*', startdate, enddate, interval = 'daily') {

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
    if (!lubridate::is.Date(startdate) || !lubridate::is.Date(enddate)) {
        cli::cli_abort(c(
          "ValueError",
          "x" = "date is not of type Date"
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

}
