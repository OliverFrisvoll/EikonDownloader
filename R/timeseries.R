ts_payload_loop <- function(directions, rics, fields, interval, start, end) {

    # Builds the payload to be sent
    payload <- list(
      'rics' = rics,
      'fields' = fields,
      'interval' = interval,
      'startdate' = date_to_JSON(start),
      'enddate' = date_to_JSON(end)
    )

    # Sends the direction and payload, returns the results
    send_json_request(directions, payload)$timeseriesData
}


#' Converts a listed JSON like object to a dataframe
#'
#' @param snippet - A snippet of the JSON
#' @return data.frame
to_dataframe <- function(snippet) {
    # Fetches the column names that should be used for the dataframe
    column_names <- purrr::map_chr(snippet$fields, ~.$name)

    # Converts a list into a dataframe, makes sure the number of rows is correct.
    dataframe_parse <- function(dataPoints) {

        # Changes null values to NA
        purrr::map(dataPoints, ~ifelse(is.null(.), NA, .)) |>
          as.data.frame(col.names = column_names)

    }

    results <- purrr::map_dfr(snippet$dataPoints, dataframe_parse)
    results$RIC.Code <- snippet$ric

    results
}


#' Fetch timeseries of data
#'
#' Returns a timeseries of data based upon the variables given
#'
#' @param rics - Vector of rics for the information requested
#' @param fields - Fields to return
#' @param startdate - Start date of the query
#' @param enddate - End date of the query
#' @param interval - char, interval of data: (minute / hour / daily / weekly / monthly / quarterly / yearly)
#'
#' @return A dataframe with the data requested
#'
#' @export
get_timeseries <- function(rics, fields = '*', startdate, enddate, interval = 'daily') {

    # Changing interval to lowercase
    interval <- tolower(interval)

    # Max rows pr request
    MAX_ROWS <- 2800L

    # Converts vectors to lists
    rics <- as.list(rics)
    fields <- as.list(fields)

    # Checks if date is dateformat
    startdate <- check_if_date(startdate)
    enddate <- check_if_date(enddate)


    date_list <- seq_of_dates(startdate, enddate, interval, MAX_ROWS / length(rics))


    # Sends the requests divided into multiple requests that adhere to the 3000 rows limit imposed
    results <- purrr::pmap(
      date_list,
      ~ts_payload_loop(
        rics = rics,
        fields = fields,
        directions = 'TimeSeries',
        interval = interval,
        start = .x,
        end = .y
      )) |>
      unlist(recursive = FALSE)


    # Removes querries that didn't return anything
    errors <- which(purrr::map_chr(results, ~.$statusCode) == "Error")
    if (length(errors) == 0L) {
        results
    } else {
        results <- results[-errors]
    }

    # Converts the results to a dataframe object.
    purrr::map_dfr(results, to_dataframe)

}


#' Fetches a timeseries given a CUSIP
#'
#' Combines get_datagrid and get_timeseries into one function that firstly uses the CUSIP to fetch RICS and then uses
#' the RICS to lookup the timeseries data between the given dates
#'
#' @param CUSIP - Vector of CUSIPs
#' @param start_date - The start date in date format to start the query
#' @param end_date - The end date in date format to end the query
#'
#' @return Dataframe of the requested information
#'
#' @export
fetch_timeseries <- function(CUSIP, start_date, end_date) {

    cusip_rics <- get_datagrid(CUSIP, 'TR.RICCode')

    timeseries <- get_timeseries(cusip_rics$RIC.Code, startdate = start_date, enddate = end_date) |>
      dplyr::left_join(cusip_rics, by = "RIC.Code")

}