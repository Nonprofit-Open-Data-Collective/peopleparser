#' Frequency of name occurrence on US birth certificates.
#'
#' A dataset containing names cross-tabbed by whether they
#' are listed as first or last names in the US Census.
#'
#' @format A [data.table::data.table] with 164,850 rows and 5 variables, keyed on
#'   `name`:
#' \describe{
#'   \item{name}{name as listed on US birth certificates}
#'   \item{male_value}{count of times the name is listed for a male}
#'   \item{female_value}{count of times the name is listed for a female}
#'   \item{first_name_value}{count of times the name appears in the first-name position}
#'   \item{last_name_value}{count of times the name appears in the last-name position}
#' }
#' @source \url{https://www.census.gov/en.html}
"census.names"

