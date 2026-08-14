#' Remove Character Elements From a Vector
#'
#' Splits a character vector into the elements that match a removal set and those
#' that remain. Used to peel salutations, suffixes, and status flags off a name
#' vector during parsing.
#'
#' @param x A character vector to filter.
#' @param elements A character vector of values to remove from `x`.
#'
#' @return A list with two components: `names` (the elements of `x` that were not
#'   removed) and `removed_names` (the removed elements collapsed into a single
#'   underscore-separated string, or `""` when nothing matched).
#' @keywords remove
#' @export
#' @examples
#' x <- c("MICHAEL", "JOHN", "LIVINGSTON", "III")
#' remove_elements(x, c("JR", "II", "III", "IV"))
remove_elements <- function(x, elements) {

  removed <- x[x %in% elements]
  if (length(removed) == 0) {
    removed <- ""
  } else {
    x <- x[!x %in% elements]
  }

  list(names = x, removed_names = paste0(removed, collapse = "_"))
}
