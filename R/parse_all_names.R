#' Parse a Set of Names
#'
#' This function returns a data frame of parse attributes based on an input of credit card names.
#' @param x Provide the charater vector to parse.
#' @param ... Alternate arguments for suffixes, prefixes, etc.
#' @keywords parse
#' @export
#' @examples
#' x <- 'livingston III,  Mr. MICHAEL JOHN9'
#' parse.names(x)
parse_names <- function(x, prefixes = prx, suffixes = sfx, ...) {

  # if length(x) > 1 stop and return warning
  
    # if class (x) is dataframe, take first string column
    # if class (x) is factor vector, convert
    # if class (x) is non-string then throw error

    # else use x
  
  input_names <- x
  
  data("census.names")

  # Set up your parallel plan
  future::plan(multisession, workers = max(1, future::availableCores() - 1))

  x <- sanitize_input( x )
  
  parsed_names <- furrr::future_map_dfr(
    x,
    parse_name, prefixes = prx, suffixes = sfx,
    .progress = FALSE  
  )

  df <- data.frame( name=input_names, parsed_names )
  
  return(df)
}
