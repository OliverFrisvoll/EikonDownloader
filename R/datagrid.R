#' Fetching information from the datagrid
#'
#' Tries to fetch information from the Eikon datagrid location. The direction that seems to work for this is
#' 'DataGrid_StandardAsync' even though I haven't implimented Async possibilities, could possibly do it with the
#' packages promises, but I doesn't seem necessary at the moment. If needed it should be implimented into a loop
#' for the send_json_request function.
#'
#' @param instrument - Vector of Char, can be CUSIP, rics
#' @param fields - Vector of Char, fields to request from the datagrid
#'
#' @return dataframe of the information requested
#'
#' @export
get_datagrid <- function(instrument, fields) {

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

    # Builds the payload to be sent
    payload <- list(
      'requests' = list(
        list(
          'instruments' = instrument,
          'fields' = list(
            list(
              'name' = fields
            )
          )
        )
      )
    )

    # Sends the direction and payload, returns the results
    results <- send_json_request(directions, payload)

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

        cli::cli_warn(c(
          "No Results",
          "x" = "Your query with instruments: {instument[1]}... for fields: {fields[1]}... did not return anything",
          "i" = "Maybe check the spelling?"
        ))

    } else {

        column_names <- purrr::map_chr(results$responses[[1]]$headers[[1]], ~.$displayName)
        purrr::map_dfr(data, ~as.data.frame(., col.names = column_names))

    }
}