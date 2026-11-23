#' @keywords internal
#'
#' @importFrom data.table data.table setkey setcolorder setorder set
"_PACKAGE"

# Quiet R CMD check notes for non-standard-evaluation column names used with
# dplyr (in determine_surname) and for the lazy-loaded census.names dataset.
utils::globalVariables(c(
  "census.names", "first_name_pairs",
  "first_name_value", "last_name_value",
  "tot", "p.first", "p.last", "ordinal"
))
