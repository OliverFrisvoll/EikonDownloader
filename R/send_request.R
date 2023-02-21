#' Builds a json like list for the Eikon Data API
#'
#' @param directions - Where
#' @param payload - What
#'
#' @return Nested list that fit into the JSON scheme
json_builder <- function(directions, payload) {
    list('Entity' = list('E' = directions, 'W' = payload))

}


#' Send JSON POST request to the given service
#'
#' Sends a POST request to the given service with a jsonlike object
#'
#' @param json - The nested list resembeling JSON that should be sent to the server
#' @param debug - Default to FALSE, turns on debugging messages
#' @param app_key
#'
#' @return Returns the results from the query
#' @export
send_json_request <- function(json, app_key, url, debug = FALSE) {

    debug_msg(debug, paste0("Payload: ", jsonlite::toJSON(json)))
    debug_msg(debug, paste0("URL: ", url))
    debug_msg(debug, paste0("APP_KEY: ", app_key))

    while (TRUE) {
        # Sends a query and sets up a pointer to the location
        query <- httr::POST(
          url,
          httr::add_headers(
            'Content-Type' = 'application/json',
            'x-tr-applicationid' = app_key
          ),
          body = json,
          encode = "json"
        )

        debug_msg(debug, paste0("Status Code: ", httr::status_code(query)))

        # Fetches the content from the query
        results <- httr::content(query)

        # Checks for ErrorCode and then aborts after printing message
        if (is.numeric(results$ErrorCode)) {
            debug_msg(debug, paste("ErrorCode:", results$ErrorCode))

            if (results$ErrorCode == 2504 |
              results$ErrorCode == 500 |
              results$ErrorCode == 400) {
                Sys.sleep(1)

            } else {
                cli::cli_abort(c(
                  "Error code: {results$ErrorCode}",
                  "x" = "{results$ErrorMessage}"
                ))
            }

        } else {
            break
        }
    }
    # Returns the results
    results
}
