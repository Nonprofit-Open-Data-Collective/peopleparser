#' Parse a Vector of Names
#'
#' Parses a character vector of raw names into a data frame of structured name
#' components. Names are sanitized once up front and then parsed in parallel with
#' [furrr::future_map_dfr()].
#'
#' @param x A character vector of raw names to parse.
#' @param prefixes A character vector of salutations/prefixes to remove.
#'   Defaults to [prx].
#' @param suffixes A character vector of suffixes to remove. Defaults to [sfx].
#' @param split_initials Logical; forwarded to [parse_name()] to enable the
#'   opt-in Defect 3 stray-initial split. Defaults to `FALSE`.
#' @param add_nicknames Logical; if `TRUE`, append the nickname columns from
#'   [nickname_lookup()] (`first_name_type`, `first_name_formal`,
#'   `first_name_nicknames`, `first_name_canonical`, `canonical_rule`).
#'   Defaults to `FALSE`.
#' @param ... Reserved for future arguments; currently unused.
#'
#' @return A `data.frame` with one row per input name and columns `name` (the
#'   original input) plus the parsed components returned by [parse_name()]:
#'   `salutation`, `first_name`, `middle_name`, `last_name`, `suffix`, `status`,
#'   `gender`, and `gender_confidence`, plus the nickname columns when
#'   `add_nicknames = TRUE`.
#' @keywords parse
#' @export
#' @examples
#' x <- c("livingston III,  Mr. MICHAEL JOHN9", "THOMAS H VON KAMECKE")
#' parse_names(x)
parse_names <- function(x, prefixes = prx, suffixes = sfx,
                        split_initials = FALSE, add_nicknames = FALSE, ...) {

  input_names <- x

  # parallelize across a session cluster, restoring the caller's plan on exit
  old_plan <- future::plan(
    future::multisession,
    workers = max(1, future::availableCores() - 1)
  )
  on.exit(future::plan(old_plan), add = TRUE)

  x <- sanitize_input(x)

  parsed_names <- furrr::future_map_dfr(
    x,
    parse_name,
    prefixes = prefixes,
    suffixes = suffixes,
    split_initials = split_initials,
    .progress = FALSE
  )

  out <- data.frame(name = input_names, parsed_names)
  if (add_nicknames) out <- add_nickname_columns(out)
  out
}

# Append nickname_lookup() columns to parsed output (uses first_name, gender,
# gender_confidence and salutation).
add_nickname_columns <- function(d) {
  nk <- nickname_lookup(d$first_name, gender = d$gender,
                        gender_confidence = d$gender_confidence,
                        salutation = d$salutation)
  cbind(d, nk)
}
