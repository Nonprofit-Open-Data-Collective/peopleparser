#' Infer Gender from a Census Name Matrix
#'
#' Aggregates the male and female birth-certificate counts for the supplied name
#' tokens and returns the majority gender together with its confidence.
#'
#' @param x A `data.table` of census data as returned by [get_census_data()],
#'   containing the `male_value` and `female_value` columns.
#'
#' @return A character vector of length two: the inferred gender code (`"M"`,
#'   `"F"`, or `"U"` when no counts are available) and the confidence percentage
#'   for that call. When gender is unknown only `"U"` is returned.
#' @keywords gender
#' @export
#' @examples
#' x <- "livingston III,  Mr. MICHAEL JOHN9"
#' x <- prep_name(x)
#' x <- strsplit(x, " ")[[1]]
#' cd <- get_census_data(x)
#' determine_gender(cd)
determine_gender <- function(x) {

  male.count <- sum(x$male_value)
  female.count <- sum(x$female_value)

  if (male.count == 0 & female.count == 0) {
    return("U")
  }

  total.count <- male.count + female.count

  male.percent <- round(male.count / total.count, 3) * 100.0
  female.percent <- round(female.count / total.count, 3) * 100.0

  rv <- ifelse(male.percent >= female.percent, "M", "F")
  rv <- c(rv, ifelse(rv == "M", male.percent, female.percent))

  return(rv)
}
