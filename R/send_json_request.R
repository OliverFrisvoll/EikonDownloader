#' Send JSON request to the Eikon API
#'
#' Sends a POST request to the API with the given payload and a direction
#'
#' @param directions - The location to send it
#' @param payload - What you are looking for formatted in a specific way
#' @param debug - Default to FALSE, turns on debugging messages.
#'
#' @return Returns the results from the query
#' @export
send_json_request <- function(directions, payload, debug = FALSE) {


    # Combining the directions and payload into one list of lists
    json <- list('Entity' = list('E' = directions, 'W' = payload))

    # Sends a query and sets up a pointer to the location
    query <- httr::POST(
      ek_get_url(),
      httr::add_headers(
        'Content-Type' = 'application/json',
        'x-tr-applicationid' = ek_get_APIKEY()
      ),
      body = json,
      encode = "json"
    )

    # Fetches the content from the query
    results <- httr::content(query)

    # Checks for ErrorCode and then aborts after printing message
    if (is.numeric(results$ErrorCode)) {

        cli::cli_abort(c(
          "Error code: {results$ErrorCode}",
          "x" = "{results$ErrorMessage}"
        ))

    }
    # Returns the results
    results
}