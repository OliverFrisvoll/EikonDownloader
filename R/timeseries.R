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

    # 2020-01-01T00:00:00
    # Convert startdate to iso8601
    startdate <- paste0(lubridate::format_ISO8601(startdate), "T00:00:00")
    enddate <- paste0(lubridate::format_ISO8601(enddate), "T00:00:00")

    api <- ek_get_APIKEY()

    df <- rust_get_ts(
      rics,
      fields,
      interval,
      startdate,
      enddate,
      api
    ) |>
      data.frame()

    suppressWarnings({
        df$TIMESTAMP <- lubridate::as_datetime(df$TIMESTAMP)
        df$HIGH <- as.numeric(df$HIGH)
        df$CLOSE <- as.numeric(df$CLOSE)
        df$LOW <- as.numeric(df$LOW)
        df$OPEN <- as.numeric(df$OPEN)
        df$COUNT <- as.numeric(df$COUNT)
        df$VOLUME <- as.numeric(df$VOLUME)
    })

    df
}
