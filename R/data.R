#' Frequency of name occurrence on US birth certificates.
#'
#' A dataset containing names cross-tabbed by whether they
#' are listed as first or last names in the US Census.
#'
#' @format A data frame with 164850 rows and 5 variables:
#' \describe{
#'   \item{name}{names listed on US birth certificates}
#'   \item{first_name_value}{count of times the name is listed on a birth certificate as a first name}
#'   \item{last_name_value}{count of times the name is listed on a birth certificate as a last name}
#' }
#' @source \url{https://www.census.gov/en.html}
"census.names"

#' Common prefixes used in names
#'
#' A vector of common prefixes
#'
#' @format A character vector with several prefixes 
"prx"

#' Common suffixes used in names
#'
#' A vector of common suffixes
#'
#' @format A character vector with several suffixes 
"sfx"