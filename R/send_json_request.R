#' Send JSON request to the database
#'
#' Sends a post request to the API with the given payload and a direction
#'
#' @param directions - The location to send it
#' @param payload - What you are looking for formatted in a specific way
#' @param debug - Default to FALSE, turns on debugging messages.
#'
#' @return Returns the results from the query
#' @export
send_json_request <- function(directions, payload, debug = FALSE) {

    # Checks if API key is supplied
    if (is.null(ek_profile$api_key)) {
        cli::cli_abort(c(
          "Cannot find: ek_profile",
          "x" = "No api_key supplied",
          "i" = "Do ek_profile$api_key <- <api_key> to set api_key"
        ))
    }

    # Combining the directions and payload into one list of lists
    json <- list('Entity' = list('E' = directions, 'W' = payload))

    # Sends a query and sets up a pointer to the location
    query <- httr::POST(
      ek_profile$url,
      httr::add_headers(
        'Content-Type' = 'application/json',
        'x-tr-applicationid' = ek_profile$api_key
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