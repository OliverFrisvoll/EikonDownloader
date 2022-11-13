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
#' @param service - !!WIP!! The service to send the message to
#' @param debug - Default to FALSE, turns on debugging messages.
#'
#' @return Returns the results from the query
#' @export
send_json_request <- function(json, service = "", debug = FALSE) {

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

#' POST request for searchview
#'
#' TODO: Write documentation
#'
#' @param json - The JSON to send
#' @param service - Which service to use
#' @param debug - Should debugging be on or off
#'
#' @return returns the results
POST_searchView <- function(json, service = "/", debug = FALSE) {

    query <- httr::POST(
      paste0(ek_get_searchlight(), service),
      httr::add_headers(
        'Content-Type' = 'application/json',
        'x-tr-applicationid' = ek_get_APIKEY()
      ),
      body = json,
      encode = "json"
    )

    results <- httr::content(query)
}


#' Quick check if the application can be run.
#' TODO: Write documentation
health_searchView <- function() {
    results <- ""

    tryCatch({
        query <- httr::GET(
          paste0(ek_get_searchlight(), "/health"),
          httr::add_headers(
            'Content-Type' = 'text/plain',
            'x-tr-applicationid' = ek_get_APIKEY()
          ),
          encode = "json"
        )

        results <- httr::content(query)

    }, error = function(cond) {
        results <- "NOT OK"

    })

    results == "200 OK"

}