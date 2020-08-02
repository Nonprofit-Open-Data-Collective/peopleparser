#' Determine gender from name matrix
#'
#' This function returns
#' @param x Provide the character vector to parse.
#' @keywords gener
#' @export
#' @examples
#' x <- 'livingston III,  Mr. MICHAEL JOHN9'
#' x <- prep.name(x)
#' x <- strsplit(x,' ')[[1]]
#' cd <- get.census.data(x)
#' determine.gender(cd)
determine.gender <- function(x) {

  male.count <- sum(x[ , 3])
  female.count <- sum(x[ , 4])

  if (male.count == 0 & female.count == 0) {
    return('U')
  }

  total.count <- male.count + female.count

  male.percent <- round(male.count / total.count, 3)  * 100.0
  female.percent <- round(female.count / total.count, 3) * 100.0

  rv <- ifelse(male.percent >= female.percent, 'M', 'F')
  rv <- c(rv, ifelse(rv == 'M', male.percent, female.percent))

  return(rv)
}
