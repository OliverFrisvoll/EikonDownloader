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
#' @param ... - List of named parameters, could be 'SDate' = '2021-07-01', 'EDate' = '2021-09-28', 'Frq' = 'D' for
#' daily data (Frq) with a given start (SDate) and end date (EDate)
#'
#' @return dataframe of the information requested
#'
#' @export
get_datagrid <- function(instrument, fields, debug = FALSE, MAX_ROWS = 10000L, ...) {

    # The limit value is around 10,000 data points for version 1.0.2 and below.
    # No enforced limit for version 1.1.0 and above.
    # However, it still has a server timeout around 300 seconds.
    MAX_COMPANIES <- 7000L
    DAYS_PR_YEAR <- 250L

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


    # TODO: ADD EDate if SDate is given

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

            if (kwargs$Frq == "D") {
                results_pr_instrument <- year_span * DAYS_PR_YEAR

            } else if (kwargs$Frq == "M") {
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

    if (!is.null(chunks_of_instruments)) {

        results <- list()
        i <- 1
        m <- length(chunks_of_instruments)
        start <- Sys.time()

        # Builds the payload to be sent
        for (intruments in chunks_of_instruments) {

            payload <- list(
              'requests' = list(
                list(
                  'instruments' = intruments,
                  'fields' = lapply(fields, \(x) list("name" = x)),
                  'parameters' = kwargs
                )
              )
            )

            json <- json_builder(directions, payload)
            new_results <- send_json_request(json)

            if (!length(results)) {

                results <- append(results, new_results)

            } else {
                # MIGHT BE BUGGY
                results$responses[[1]]$data <- append(results$responses[[1]]$data, new_results$responses[[1]]$data)
                results$responses[[1]]$totalRowsCount <- results$responses[[1]]$totalRowsCount + new_results$responses[[1]]$totalRowsCount

                if ("error" %in% names(new_results$responses[[1]])) {
                    results$responses[[1]]$error <- append(results$responses[[1]]$error, new_results$responses[[1]]$error)
                }
                # Works pretty well, for some strange reason.
            }

            if (i %% 5 == 0) {

                elapsed <- round(as.numeric(difftime(time1 = Sys.time(), time2 = start, units = "mins")), 4)
                ETA <- (elapsed / i) * (m - i)
                msg <- paste0("Downloading Data, payload ", i, "/", m, " | Elapsed: ", round(elapsed, 2), " min", " | ETA: ", round(ETA, 2), " min")
                cli::cli_inform(c(
                  "i" = msg
                ))
            }

            i <- i + 1
        }

    }

    cli::cli_inform(c(
      "v" = "Downloaded {prettyunits::pretty_bytes(object.size(results)[1])}"
    ))

    if (debug) {
        return(results)
    }

    cli::cli_inform(c(
      "i" = "Building dataframe"
    ))

    if ("error" %in% names(results$responses[[1]])) {
        # TODO: Add a handler for error code 416: Unable to collect data for the field 'TR.RICCode' and some specific
        #  identifier(s)

        error <- results$responses[[1]]$error[[1]]

        if (error$code == 218) {

            cli::cli_abort(c(
              "No Results",
              "x" = "The field could not be found"
            ))

        }

    }


    data <- results$responses[[1]]$data
    #
    # debug_msg <- results$responses[[1]]$headers[[1]]

    # if (is.null(results$responses[[1]]$headers[[1]][[1]]$displayName)) {
    #     cli::cli_abort(c(
    #       "No Results",
    #       "x" = "The field(s) supplied are not present in any of the instruments",
    #       "i" = "Use the Data Item Browser (DIB) in the Eikon/Refinitiv Terminal to find fields"
    #     ))
    # }

    tryCatch({
        column_names <- purrr::map_chr(results$responses[[1]]$headers[[1]], ~.$displayName)
    }, error = function(e) {
        cli::cli_abort(c(
          "No Results",
          "x" = "The field(s) supplied are not present in any of the instruments",
          "i" = "Use the Data Item Browser (DIB) in the Eikon/Refinitiv Terminal to find fields"
        ))
    })

    data_df <- purrr::map_dfr(data, ~as.data.frame(purrr::map(., \(x) ifelse(is.null(x), NA, as.character(x))), col.names = column_names))

    cli::cli_inform(c(
      "v" = "dataframe built"
    ))

    return(data_df)

}