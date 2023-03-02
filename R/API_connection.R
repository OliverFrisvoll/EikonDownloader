#' Function to set api_key
#'
#' @param api_key - The api_key to be used
#'
#' @export
ek_set_APIKEY <- function(api_key = NULL) {

    if (!is.character(api_key) && !is.null(api_key)) {
        cli::cli_abort(c(
          "TypeError",
          "x" = "The key supplied: {api_key} is not a string or NULL"
        ))
    }

    if (is.null(api_key)) {
        invisible(.pkgglobalenv$ek$api_key <- NULL)

    } else {
        .pkgglobalenv$ek$api_key <- api_key
        ek_test_connection()
        invisible(ek_test_connection())

    }
}

#' Function to set api_port
#'
#' Only needed if the Refinitiv Terminal is running on a port that
#' is not between 9000L and 9011L
#'
#' @param port - The new port to use, (default NULL)
#'
#' @export
ek_set_port <- function(port = NULL) {
    if (!is.numeric(port) && !is.null(port)) {
        cli::cli_abort(c(
          "TypeError",
          "x" = "The port supplied: {port} is not a number or NULL"
        ))
    }

    if (is.null(port)) {
        invisible(.pkgglobalenv$ek$port <- NULL)

    } else {
        invisible(.pkgglobalenv$ek$port <- as.integer(port))
    }
}

#' Getting the port that is set
#' @export
ek_get_port <- function() {
    .pkgglobalenv$ek$port
}

#' Check status
ek_get_status <- function(port) {
    address <- paste0(.pkgglobalenv$ek$base_url, ":", port, "/api/status")
    status <- tryCatch({
        httr::http_status(httr::GET(address))$reason == "OK"
    },
      error = function(cond) {
          FALSE
      }
    )

    status
}


#' Tests the connection to Eikon
ek_test_connection <- function() {
    current_port <- ek_get_port()

    if (ek_get_status(current_port)) {
        return(TRUE)
    }

    test_ports <- 9000L:9010L
    test_ports <- test_ports[-current_port]

    for (port in test_ports) {
        status <- ek_get_status(port)
        if (status) {
            break
        }
    }
    if (!status) {
        ek_set_port(current_port)
        cli::cli_abort(c(
          "ConnectionError",
          "x" = "Can't connect to the Refinitiv Terminal on any normal ports",
          "i" = "Make sure the terminal is running or set manual port with ek_set_port(<port>)"
        ))
    } else {
        status
    }
}


#' Fetches the Eikon API_KEY
ek_get_APIKEY <- function() {
    if (is.null(.pkgglobalenv$ek$api_key)) {
        cli::cli_abort(c(
          "Missing API_KEY",
          "x" = "API_KEY not set",
          "i" = "Use ek_set_APIKEY(<API_KEY>) to set an api_key"
        ))

    } else {
        .pkgglobalenv$ek$api_key

    }
}


#' Fetches the url to send data requests to
ek_get_url <- function() {
    paste0(
      .pkgglobalenv$ek$base_url,
      ":",
      .pkgglobalenv$ek$port,
      .pkgglobalenv$ek$data_api
    )
}

#' Fetches the url to send searchlight requests to
ek_get_searchlight <- function() {
    paste0(
      .pkgglobalenv$ek$base_url,
      ":",
      .pkgglobalenv$ek$port,
      .pkgglobalenv$ek$search_api
    )
}

