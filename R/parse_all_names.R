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
#' @param ... Reserved for future arguments; currently unused.
#'
#' @return A `data.frame` with one row per input name and columns `name` (the
#'   original input) plus the parsed components returned by [parse_name()]:
#'   `salutation`, `first_name`, `middle_name`, `last_name`, `suffix`, `status`,
#'   `gender`, and `gender_confidence`.
#' @keywords parse
#' @export
#' @examples
#' x <- c("livingston III,  Mr. MICHAEL JOHN9", "THOMAS H VON KAMECKE")
#' parse_names(x)
parse_names <- function(x, prefixes = prx, suffixes = sfx, ...) {

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
    .progress = FALSE
  )

  data.frame(name = input_names, parsed_names)
}
