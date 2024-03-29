#' Function to set api_key
#'
#' This function is used to set the app_key to be used in the package. To get an app_key you need to have the Eikon
#' desktop app or the newer Refinitiv terminal installed. You can then get an app_key from the app by typing in
#' appkey in the search field and then creating a new app_key.
#'
#' @param api_key - The api_key to be used
#' @param debug - If TRUE, prints debug messages
#'
#' @export
ek_set_APIKEY <- function(api_key = NULL, debug = FALSE) {

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
        port <- ek_fetch_port(debug = debug)
        ek_set_port(port)
        invisible(port)
    }
}


#' Function to set api_port
#'
#' Just needed to incase it doesn't work on the automatically detected port,
#' this can sometimes be the case after the system hibernates with Eikon or
#' the Refintiv terminal running.
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
#'
#' @param port - The port to check status on
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


#' Fetches Eikon port from file
#'
#' @param debug - If TRUE, prints debug messages
ek_fetch_port <- function(debug = FALSE) {
    port <- NULL
    app_names <- c("Data API Proxy", "Eikon API proxy", "Eikon Scripting Proxy")
    path <- list()

    if (debug) {
        cli::cli_inform("System: {Sys.info()['sysname']}")
    }

    for (app_author in c("Refinitiv", "Thomson Reuters")) {

        if (Sys.info()['sysname'] == "Linux") {
            for (app_name in app_names) {
                if (dir.exists(rappdirs::user_config_dir(app_name, app_author, roaming = TRUE))) {
                    path <- append(path, rappdirs::user_config_dir(app_name, app_author, roaming = TRUE))
                }
            }
        } else {
            for (app_name in app_names) {
                if (dir.exists(rappdirs::user_data_dir(app_name, app_author, roaming = TRUE))) {
                    path <- append(path, rappdirs::user_data_dir(app_name, app_author, roaming = TRUE))
                }
            }
        }
    }

    if (length(path) > 0) {
        port_in_use_file <- file.path(path[[1]], ".portInUse")


        if (file.exists(port_in_use_file)) {
            port_str <- readr::read_file(port_in_use_file)
            if (port_str != "") {
                port <- as.integer(port_str)
                if (debug) {
                    cli::cli_inform("Found port {port}")
                }
                res <- ek_get_status(port)

                if (res) {
                    if (debug) {
                        cli::cli_inform("Port {port} works")
                    }
                    return(port)
                }
            } else {
                if (debug) {
                    cli::cli_inform("{port_in_use_file} is empty")
                }
            }

        } else {
            if (debug) {
                cli::cli_inform(".portInUse file does not exist in folder {port_in_use_file}")
            }
        }

    } else {
        if (debug) {
            cli::cli_inform("Found no path to look for .portInUse")
        }
    }

    if (is.null(port)) {
        if (debug) {
            cli::cli_inform("Trying to find port by bruteforce")
        }
        for (p in 9000L:9060L) {
            if (ek_get_status(p)) {
                port <- p
                break
            }
        }
        if (is.null(port)) {
            cli::cli_abort(c(
              "Cannot connect to the Refinitiv / Eikon Terminal",
              "x" = "Refinitiv / Eikon is not running on this computer",
            ))
        }
    }
    port
}
