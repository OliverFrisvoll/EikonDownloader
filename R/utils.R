#' Converts date to JSON formate
#'
#' @param date - The date to convert
#'
#' @return date converted to JSON in string format
date_to_JSON <- function(date) {
    # "converts" to JSON format
    format(date, format = "%Y-%Om-%dT%H:%M:%SZ")
}


#' Divides a date interval into many intervals
#'
#'
#'
#' @param start - date object start date
#' @param end - date object end date
#' @param interval - interval between dates
#' @param RFE - How many rows should be allowed for each RIC
#'
#' @return a list of start and end dates in JSON like format
#'
seq_of_dates <- function(start, end, interval, RFE) {

    # Type checking
    interval <- tolower(interval)


    if (RFE >= 3000) {
        cli::cli_warn(c(
          "Too many rows for each RIC",
          "i" = "The Eikon API only allows 3000 rows to be for each request",
          "x" = "An RFE value of {RFE} may cause some rows the be omitted!"
        ))
    }


    if (start > end) {
        cli::cli_abort(c(
          "Date Error",
          "x" = "The end date {end} is earlier than the start date {start}",
          "i" = "Flip the end date and start date to fix this"
        ))
    }

    # TODO: Find a better solution
    interval_object <- switch(
      interval,
      minute = lubridate::make_difftime(minute = RFE),
      hour = lubridate::make_difftime(hour = RFE),
      daily = lubridate::make_difftime(day = RFE),
      weekly = lubridate::make_difftime(week = RFE),
      monthly = lubridate::make_difftime(day = RFE * 30),
      quaterly = lubridate::make_difftime(day = RFE * 3 * 30),
      yearly = lubridate::make_difftime(day = RFE * 365),
      cli::cli_abort(c(
        "Interval Error",
        "x" = "Could not use the given interval: {interval}",
        "i" = "Try one of [minute/hour/daily/monthly/yearly]"
      ))
    )


    if (end - start > interval_object) {

        # Creates a sequence of dates
        time_vec <- seq(from = start, to = end, by = interval_object)
        time_vec_l <- seq(from = start - lubridate::days(1), to = end, by = interval_object)

        startdate_vec <- c(start, time_vec_l[2:length(time_vec)])
        enddate_vec <- c(time_vec[2:length(time_vec)], end)

        data.frame(start = startdate_vec, end = enddate_vec)

    } else {

        data.frame(start = start, end = end)

    }

}


#' Takes a vector and calculates return
#'
#' Just a simple function for calculating returns.
#'
#' @param prices - Vector with prices
#' @param type - Type of return (simple / log)
#'
#' @return Vector of returns
calculate_returns <- function(prices, type = "simple") {

    # TODO: Write tests
    # Changing type to lowercase
    type <- tolower(type)

    # Available types
    types <- list(
      simple = \(p) { c(NA, (p[2:length(p)] - p[1:(length(p) - 1)]) / p[1:(length(p) - 1)]) },
      log = \(p) { c(NA, diff(log(p))) }
    )

    if (!(type %in% names(types))) {
        cli::cli_abort(c(
          "Return type not available",
          "x" = "The return type: {type} is not available",
          "i" = "Try on of: {names(types)} instead"
        ))
    }

    types[[type]](prices)

}

#' Printing a debug message
#'
#' @param test - Boolean if the message should be printed
#' @param msg - String with message
debug_msg <- function(test, msg) {
    if (test) {
        cat(cli::bg_red(msg), "\n")
    }
}

#' Printing a msg to inform about something
#'
#' @param msg - String with message
info_msg <- function(msg) {
    cli::cli_inform(c(
      "i" = msg
    ))
}


#' Printing a msg when something is done
#'
#' @param msg - String with message
done_msg <- function(msg) {
    cli::cli_inform(c(
      "v" = msg
    ))
}

