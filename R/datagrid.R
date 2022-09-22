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

    # Fetches column_names from the resulting query
    column_names <- purrr::map_chr(results$responses[[1]]$headers[[1]], ~.$displayName)

    # Creates a dataframe out of the results with the column_names found in the previous step.
    purrr::map_dfr(results$responses[[1]]$data, ~as.data.frame(., col.names = column_names))

}