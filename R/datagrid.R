#' Fetching information from the datagrid
#'
#' Tries to fetch information from the Eikon datagrid location. The direction that seems to work for this is
#' 'DataGrid_StandardAsync' even though I haven't implimented Async possibilities, could possibly do it with the
#' packages promises, but I doesn't seem necessary at the moment. If needed it should be implimented into a loop
#' for the send_json_request function.
#'
#' @param instrument - Vector of Char, can be CUSIP, rics
#' @param fields - Vector of Char, fields to request from the datagrid
#' @param debug - if it should just return the json results, default FALSE
#' @param MAX_ROWS - Max amount of rows to send with each payload, default 10000L
#' @param MP - If the function should be run in paralell, default FALSE // NOT IMPLIMENTED
#' @param rDF - If the function should return a dataframe, default TRUE
#' @param ... - List of named parameters, could be 'SDate' = '2021-07-01', 'EDate' = '2021-09-28', 'Frq' = 'D' for
#' daily data (Frq) with a given start (SDate) and end date (EDate)
#'
#' @return dataframe of the information requested
#'
#' @export
get_datagrid <- function(instrument, fields, debug = FALSE, MAX_ROWS = 6000L, MP = FALSE, rDF = TRUE, ...) {

    # The limit value is around 10,000 data points for version 1.0.2 and below.
    # No enforced limit for version 1.1.0 and above.
    # However, it still has a server timeout around 300 seconds.
    MAX_COMPANIES <- 7000L
    DAYS_PR_YEAR <- 250L

    url <- ek_get_url()
    app_key <- ek_get_APIKEY()


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


    # Converts vector to list
    instrument <- as.list(instrument)

    # Sets the direction
    directions <- 'DataGrid_StandardAsync'

    # Fetches the keyword arguments
    kwargs <- list(...)
    extraparam <- names(kwargs)

    if ("SDate" %in% extraparam & "EDate" %in% extraparam) {

        year_span <- lubridate::interval(lubridate::ymd(kwargs$SDate), lubridate::ymd(kwargs$EDate)) |>
          lubridate::as.duration() |>
          as.numeric("years")

        if ("Frq" %in% extraparam) {

            if (kwargs$Frq %in% c("D")) {
                results_pr_instrument <- year_span * DAYS_PR_YEAR

            } else if (kwargs$Frq %in% c("M")) {
                results_pr_instrument <- year_span * 12

            } else if (kwargs$Frq %in% c("Y", "FY")) {
                results_pr_instrument <- year_span

            }

        } else {
            results_pr_instrument <- year_span * DAYS_PR_YEAR
        }

        chunk_size <- floor(MAX_ROWS / results_pr_instrument)

    } else {
        chunk_size <- MAX_COMPANIES
    }



    suppressWarnings(
      chunks_of_instruments <- split(instrument, 1:(ceiling(length(instrument) / chunk_size)))
    )

    debug_msg(debug, paste("Requests to send: ", length(chunks_of_instruments)))

    # Builds the payload to be sent
    loop <- function(instruments) {

        payload <- list(
          'requests' = list(
            list(
              'instruments' = instruments,
              'fields' = lapply(fields, \(x) list("name" = x)),
              'parameters' = kwargs
            )
          )
        )

        json <- json_builder(directions, payload)
        send_json_request(json, app_key, url, debug)
    }

    results <- future.apply::future_lapply(chunks_of_instruments, loop)

    done_msg(paste("Downloaded: ", prettyunits::pretty_bytes(object.size(results)[1])))

    if (!rDF) {
        return(results)
    }

    info_msg("Building dataframe")

    df <- dg_to_dataframe(results)

    done_msg("Dateframe Built")

    return(df)

}

#' Fetches the headers of a json object
#'
#' @param json_like - json_like object, in reality a nested list
#'
#' @return list of headers
dg_fetch_headers <- function(json_like) {

    header <- c()
    for (col in json_like[[1]][["responses"]][[1]]["headers"][[1]][[1]]) {
        if (length(names(col)) > 1) {
            header <- append(header, paste0(col["field"]))
        } else {
            header <- append(header, col["displayName"])
        }
    }
    header
}

#' Converts a json object to a dataframe
#'
#' @param json_like - json_like object, in reality a nested list
#'
#' @return dataframe
#' @export
dg_to_dataframe <- function(json_like) {

    headers <- json_like |>
      dg_fetch_headers()

    purrr::map_dfr(json_like, \(data)
      purrr::map_dfr(data$responses[[1]]$data, \(y) as.data.frame(
        purrr::map(y, \(x) ifelse(is.null(x), NA, as.character(x))), col.names = headers)
      )
    )
}

