#' Pull Name Matrix bases on character vector
#'
#' This function returns
#' @param x Provide the name character vector to parse.
#' @keywords census name
#' @export
#' @note The return data.table is sorted based on the ordinals of the character vector arguement.
#' @return data.table
#' @examples
#' x <- 'livingston III,  Mr. MICHAEL JOHN9'
#' x <- prep.name(x)
#' x <- strsplit(x,' ')[[1]]
#' get.census.data(x)
get.census.data <- function(x) {

  # since the census data does not have spaces, lets remove dashes of complex last names
  x <- gsub('-', '', x, fixed = TRUE)

  #
  ordinal.set <- data.table::data.table(name = x, ordinal = 1:length(x))
  data.table::setkey(ordinal.set, name)

  #
  if (!exists('census.names')) {
    data("census.names")
  }

  #
  lookup.set <- census.names[census.names$name %in% x, ]

  #
  rv <- merge(ordinal.set, lookup.set, all.x = TRUE)
  rv[is.na(rv)] <- 0

  # sort based on ordinals
  rv <- data.table::setkey(rv, ordinal)

  return(rv)

}
