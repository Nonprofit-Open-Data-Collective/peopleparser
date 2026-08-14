#' Look Up Census Name-Frequency Data for a Character Vector
#'
#' Joins each element of a name vector against the [census.names] reference table
#' to retrieve its male, female, first-name, and last-name occurrence counts. The
#' lookup uses a keyed binary-search join on [census.names] (which is keyed on
#' `name`), so it stays fast even though the reference table has ~165k rows.
#'
#' @param x A character vector of name tokens (typically the output of
#'   [prep_name()] split on spaces). Dashes are stripped before lookup because
#'   the census data stores compound names without them.
#'
#' @return A `data.table` with one row per input token, keyed and sorted on
#'   `ordinal` (the token's original position). Columns: `name`, `ordinal`,
#'   `male_value`, `female_value`, `first_name_value`, `last_name_value`. Tokens
#'   absent from the census table get zero counts.
#' @export
#' @examples
#' x <- "livingston III,  Mr. MICHAEL JOHN9"
#' x <- prep_name(x)
#' x <- strsplit(x, " ")[[1]]
#' get_census_data(x)
get_census_data <- function(x) {

  # the census data stores compound last names without dashes
  x <- gsub("-", "", x, fixed = TRUE)

  # ensure the reference table is available (lazy-loaded via LazyData)
  if (!exists("census.names")) {
    utils::data("census.names", envir = environment())
  }

  # keyed binary-search join: census.names is keyed on `name`, so this avoids a
  # full O(n) scan of the ~165k-row table on every lookup
  query <- data.table::data.table(name = x, ordinal = seq_along(x))
  rv <- census.names[query, on = "name"]

  # tokens not found in the census table return NA counts -> set them to zero
  count_cols <- c("male_value", "female_value", "first_name_value", "last_name_value")
  for (col in count_cols) {
    data.table::set(rv, i = which(is.na(rv[[col]])), j = col, value = 0)
  }

  # keep the historical column order (some callers index positionally) and sort
  data.table::setcolorder(rv, c("name", "ordinal", count_cols))
  data.table::setkey(rv, ordinal)

  return(rv)
}
