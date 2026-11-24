#' Determine the Surname (Last Name) Position
#'
#' Uses census first-name / last-name frequencies (see [get_census_data()]) to
#' decide which token in a name vector is most likely the surname. Tokens are
#' ranked in three tiers: (1) known names that are overwhelmingly surnames
#' (surname share of at least 0.95), the more common first; (2) tokens absent
#' from the census; (3) all other known names by surname share. Remaining ties
#' break toward the later position. The first tier matters because in the 2020
#' Census lists nearly every common surname also appears, rarely, as a given
#' name (4,999 people are named SMITH), so a pure share would let an unknown
#' token or an initial outrank SMITH in `"SJ SMITH"`.
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

  # rank: (1) known names that are overwhelmingly surnames, more common first,
  # (2) names absent from the census, (3) other names by surname share
  # (base R rather than dplyr: this runs for most names, and dplyr's per-call
  # overhead dominated parse time)
  f <- x$first_name_value; l <- x$last_name_value
  tot <- f + l + 1
  p.last <- (1 + l) / tot
  known <- f + l > 0
  tier <- ifelse(known & p.last >= .surname_tier_min, 1L, ifelse(!known, 2L, 3L))
  score <- ifelse(tier == 1L, tot, ifelse(tier == 3L, p.last, 0))
  ord <- x$ordinal
  most.likely <- ord[order(tier, -score, -tot, -ord)][1]
  return(most.likely)
}

# Surname share at or above which a known name counts as a plain surname in
# determine_surname() (tier 1). Chosen on Form 990 Part VII names: see
# data-raw/census_names.R and NEWS.md.
.surname_tier_min <- 0.95
