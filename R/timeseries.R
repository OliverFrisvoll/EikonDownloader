#' Get timeseries data from Eikon using RIC as identifier
#'
#' Returns a timeseries of data for the given rics for the given timeperiod and interval.
#' The fields can be specified, by default it returns all the fields
#'
#' @param rics - Char vector of rics for the information requested
#' @param fields - Fields to return, by default all fields are returned these field are different from the datagrid
#' fields
#' @param startdate - Date, start date of the query as a date object (required)
#' @param enddate - Date, end date of the query as a date object (optional, if not supplied, todays date is used)
#' @param interval - char, interval of data: (minute / hour / daily / weekly / monthly / quarterly / yearly) not all
#' data is available for all intervals. For instance minute and hour data is only available one year back
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
    if (!inherits(startdate, "Date")) {
        cli::cli_abort(c(
          "ValueError",
          "x" = "startdate is not of type Date"
        ))
    }
    if (!is.null(enddate) && !inherits(enddate, "Date")) {
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

    # Convert startdate to iso8601
    startdate <- paste0(format(startdate, "%Y-%m-%d"), "T00:00:00")
    if (is.null(enddate)) {
        enddate <- Sys.Date()
    }
    enddate <- paste0(format(enddate, "%Y-%m-%d"), "T00:00:00")

    api <- ek_get_APIKEY()

    ret <- rust_get_ts(
      c(rics),
      c(fields),
      interval,
      startdate,
      enddate,
      api,
      as.integer(ek_get_port())
    )

    if (identical(ret[[1]], "Error")) {
        cli::cli_warn(c(
          "Error",
          "x" = "{ret[[2]]}"
        ))
    } else if (length(names(ret)) > 0) {
        df <- as.data.frame(ret, stringsAsFactors = FALSE)
        df[] <- lapply(df, function(x) {
            if (is.character(x)) replace(x, x == "null", NA_character_) else x
        })
        df
    } else {
        ret
    }

}
