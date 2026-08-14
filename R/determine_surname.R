#' Determine the Surname (Last Name) Position
#'
#' Uses census first-name / last-name frequencies (see [get_census_data()]) to
#' decide which token in a name vector is most likely the surname. Tokens are
#' ranked so that names appearing (relatively) more often in the last-name
#' position rank highest; ties break toward higher overall frequency and then
#' later ordinal position.
#'
#' @param x A census-data `data.table` to evaluate, as produced by
#'   [get_census_data()].
#'
#' @return An integer giving the `ordinal` (1-based position) of the most likely
#'   surname. Returns `c(0, 0)` if `x` is not a `data.table`, and `c(1, 2)` when
#'   `x` has a single row.
#' @keywords matrix surname
#' @export
#' @examples
#' x <- "livingston III,  Mr. MICHAEL JOHN9"
#' x <- prep_name(x)
#' x <- strsplit(x, " ")[[1]]
#' cd <- get_census_data(x)
#' determine_surname(cd)
#' @author mjfii \href{mailto:mick.flanigan@gmail.com}{mick.flanigan@gmail.com}
determine_surname <- function(x) {

  if (class(x)[1] != "data.table") {
    cat("you must pass in a class of data.table.\n")
    return(c(0, 0))
  }
  if (nrow(x) == 0) {
    cat("you must pass in a class of data.table with at least one row.\n")
    return(c(0, 0))
  }
  if (nrow(x) == 1) {
    return(c(1, 2))
  }

  # rank: (1) names that only ever appear as a last name, (2) names absent from
  # the database, (3) relative frequency in the last-name position
  x <-
    x %>%
    dplyr::mutate(
      tot = first_name_value + last_name_value + 1,
      p.first = first_name_value / tot,
      p.last = (1 + last_name_value) / tot
    ) %>%
    dplyr::arrange(-p.last, -tot, -ordinal)

  most.likely <- (x$ordinal)[1]
  return(most.likely)
}
