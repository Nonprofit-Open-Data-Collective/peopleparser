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
parse.names <- function(x, ...) {

    # if class (x) is dataframe, take first string column
    # if class (x) is factor vector, convert
    # if class (x) is non-string then throw error

    # else use x

  no_cores <- parallel::detectCores() - 1
  cl <- parallel::makeCluster(no_cores)


  input_names <- data.frame(name = x)

  input_names$parsed_name <- parallel::parLapply(cl, input_names$name, parse.name)

  input_names <- data.frame(input_names$name, do.call('rbind', strsplit(as.character(input_names$parsed_name), '|',fixed=TRUE)), stringsAsFactors = FALSE)

  colnames(input_names) <- c('name','salutation','first_name','middle_name', 'last_name','suffix', 'gender', 'gender_confidence')

  parallel::stopCluster(cl)

  return(input_names)
}
