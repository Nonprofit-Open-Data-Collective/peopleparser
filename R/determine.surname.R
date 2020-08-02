#' Determine the Surname (or Last Name)
#'
#' This function uses results from \code{\link[name.parser]{get.census.matrix}} to evaluate and derive the surname of any given character vector of Names.
#' @param x Provide the 'census matrix' that is to be evaluated.  See examples.
#' @keywords matrix surname
#' @export
#' @note The function returns a two element integer vector.  The first element is the ordinal of the recommend/suggested
#' surname.  The second element is the confidence of the recommendation.
#' @examples
#' x <- 'livingston III,  Mr. MICHAEL JOHN9'
#' x <- prep.name(x)
#' x <- strsplit(x,' ')[[1]]
#' cd <- get.census.data(x)
#' print(x)
#' determine.surname(cd)
#' @author mjfii \href{mailto:mick.flanigan@gmail.com}{mick.flanigan@gmail.com}
determine.surname <- function(x) {

  #
  if (class(x)[1] != 'data.table') {
    cat('you must pass in a class of data.table.\n')
    return(c(0,0))
  }

  if (nrow(x) == 0) {
    cat('you must pass in a class of data.table with at least one row.\n')
    return(c(0,0))
  }

  if (nrow(x) == 1) {
    return(c(1,2))
  }

  if (nrow(x) >= 3) {
    x<- x[x$ordinal %in% c(1,nrow(x)), ]
  }

  #
  x$comp_to_zero <- ifelse(x[ , 5] == 0 & x[ , 6] > 0, 1, 0)

  #
  x$greater_than <- ifelse(x[ , 6] > x[ , 5], 1, 0)

  #
  x$high_degree_first_name <- ifelse(x[ , 6] == 0 & x[ , 5] > 0, -1, 0)

  #
  x$max_set_value <- ifelse(x[ , 6] == max(x[ , 6]), 1, 0)

  #
  x$determination_total <- x$greater_than + x$comp_to_zero + x$high_degree_first_name + x$max_set_value

  set.max <- max(x$determination_total)

  #
  rv <- max(x[x$determination_total == set.max, ]$ordinal)

  return(rv)
}
