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

  # row of each token in census.names (0 when absent), from a hashed index
  # built once per session (R/data_cache.R). This replaced a keyed join per
  # call, whose setup cost dominated parse time.
  i <- census_row(x)
  cn <- census_names_table()
  hit <- i > 0L
  idx <- i; idx[!hit] <- NA_integer_
  pick <- function(v) { out <- v[idx]; out[!hit] <- as.vector(0, typeof(v)); out }

  rv <- list(name = x, ordinal = seq_along(x),
             male_value = pick(cn$male_value),
             female_value = pick(cn$female_value),
             first_name_value = pick(cn$first_name_value),
             last_name_value = pick(cn$last_name_value))
  rv <- data.table::setDT(rv)
  data.table::setattr(rv, "sorted", "ordinal")   # already in ordinal order
  rv
}

# The previous implementation (a keyed join on every call). Kept for the test
# that the fast path returns identical results.
get_census_data_join <- function(x) {
  x <- gsub("-", "", x, fixed = TRUE)
  query <- data.table::data.table(name = x, ordinal = seq_along(x))
  rv <- census_names_table()[query, on = "name"]
  count_cols <- c("male_value", "female_value", "first_name_value", "last_name_value")
  for (col in count_cols) {
    data.table::set(rv, i = which(is.na(rv[[col]])), j = col, value = 0)
  }
  data.table::setcolorder(rv, c("name", "ordinal", count_cols))
  data.table::setkey(rv, ordinal)
  rv
}
