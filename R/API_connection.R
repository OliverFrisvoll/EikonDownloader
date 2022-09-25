#' Function to set api_key
#'
#' @param api_key - The api_key to be used
#'
#' @export
ek_set_APIKEY <- function(api_key) {

    if (!is.character(api_key) && !is.null(api_key)) {
        cli::cli_abort(c(
          "TypeError",
          "x" = "The key supplied: {api_key} is not a string or NULL"
        ))
    }

    if (is.null(api_key)) {

        invisible(.pkgglobalenv$ek$api_key <- NULL)

    } else {

        invisible(.pkgglobalenv$ek$api_key <- api_key)

    }


}


#' Fetches the Eikon API_KEY
ek_get_APIKEY <- function() {
    if (is.null(.pkgglobalenv$ek$api_key)) {

        # TODO: Create test
        cli::cli_abort(c(
          "Missing API_KEY",
          "x" = "API_KEY not set",
          "i" = "Use ek_set_APIKEY(<API_KEY>) to set an api_key"
        ))
    } else {
        .pkgglobalenv$ek$api_key
    }
}


#' Fetches the url to send requests to
ek_get_url <- function() {
    paste0(
      .pkgglobalenv$ek$base_url,
      ":",
      .pkgglobalenv$ek$port,
      .pkgglobalenv$ek$api_url
    )
}


