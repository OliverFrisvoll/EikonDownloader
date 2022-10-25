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
#'
#' @return dataframe of the information requested
#'
#' @export
get_datagrid <- function(instrument, fields, ...) {

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

    if (length(kwargs) != 0) {
        # Builds the payload to be sent
        payload <- list(
          'requests' = list(
            list(
              'instruments' = instrument,
              'fields' = lapply(fields, \(x) list("name" = x)),
              'parameters' = kwargs
            )
          )
        )

    } else {
        # Builds the payload to be sent
        payload <- list(
          'requests' = list(
            list(
              'instruments' = instrument,
              'fields' = lapply(fields, \(x) list("name" = x))
            )
          )
        )
    }

    json <- json_builder(directions, payload)
    results <- send_json_request(json)

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

    null_results <- purrr::imap_int(data, ~ifelse(!is.null(.x[[2]]), NA, .y))

    null_results <- null_results[!is.na(null_results)]
    if (length(null_results > 0)) {

        data <- data[-null_results]

    }

    if (length(data) < 0) {

        # TODO: Create test
        cli::cli_warn(c(
          "No Results",
          "x" = "Your query with instruments: {instument[1]}... for fields: {fields[1]}... did not return anything",
          "i" = "Maybe check the spelling?"
        ))

    } else {

        column_names <- purrr::map_chr(results$responses[[1]]$headers[[1]], ~.$displayName)

        loop <- function(data) {
            data <- purrr::map(data, ~ifelse(.x == "", NA, .x))
            as.data.frame(data, col.names = column_names)
        }

        purrr::map_dfr(data, loop)

    }
}