#' Parse a Vector of Names
#'
#' Parses a character vector of raw names into a data frame of structured name
#' components. Names are sanitized once up front and then parsed with
#' [parse_name()].
#'
#' @section Parallel parsing:
#' By default `parse_names()` runs in the current R session and never starts
#' background processes on its own. It uses parallel workers in two cases:
#'
#' * the caller has set a [future::plan()], for example
#'   `future::plan(future::multisession, workers = 4)`. The workers are reused
#'   across calls until the caller changes the plan;
#' * `workers` is a number above 1. `parse_names()` starts that many
#'   background R sessions for this call and shuts them down when it returns,
#'   restoring the caller's plan.
#'
#' Workers load the installed copy of peopleparser. Each one reports its
#' version and build time, and `parse_names()` stops if any differs from the
#' calling session (for example after a reinstall while R was running, or when
#' the session runs development code through `devtools::load_all()`).
#' Starting workers takes a few seconds, so they pay off only for large
#' inputs.
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
#' @param split_run_together Logical; if `TRUE`, split a surname and given
#'   name written as one word (`KramerKenneth`, `MURPHYSANDRA`) before parsing,
#'   with [split_run_together()]. Defaults to `FALSE`.
#' @param classify Logical; if `TRUE`, add the `name_type` and `org_score`
#'   columns from [classify_names()], computed on the raw input, so that
#'   organisations, placeholders and couples can be set aside. Defaults to
#'   `FALSE`.
#' @param workers `NULL` (default) to use the caller's [future::plan()]
#'   (sequential unless the caller set one), `1` to run in this session
#'   whatever the plan, or a number above 1 to start that many workers for this
#'   call. See *Parallel parsing*.
#' @param ... Reserved for future arguments; currently unused.
#'
#' @return A `data.frame` with one row per input name and columns `name` (the
#'   original input) plus the parsed components returned by [parse_name()]:
#'   `salutation`, `first_name`, `middle_name`, `last_name`, `suffix`, `status`,
#'   `gender`, and `gender_confidence`, plus the nickname columns when
#'   `add_nicknames = TRUE` and `name_type` and `org_score` when
#'   `classify = TRUE`.
#' @keywords parse
#' @export
#' @examples
#' x <- c("livingston III,  Mr. MICHAEL JOHN9", "THOMAS H VON KAMECKE")
#' parse_names(x)
#'
#' \dontrun{
#' # start 4 workers for one large call
#' parse_names(big_vector, workers = 4)
#'
#' # or keep workers running across several calls
#' future::plan(future::multisession, workers = 4)
#' a <- parse_names(batch_1)
#' b <- parse_names(batch_2)
#' future::plan(future::sequential)
#' }
parse_names <- function(x, prefixes = prx, suffixes = sfx,
                        split_initials = FALSE, add_nicknames = FALSE,
                        split_run_together = FALSE, classify = FALSE,
                        workers = NULL, ...) {

  input_names <- x
  if (split_run_together) x <- peopleparser::split_run_together(x)
  x <- sanitize_input(x)

  if (!is.null(workers)) {
    workers <- suppressWarnings(as.integer(workers))
    if (length(workers) != 1 || is.na(workers) || workers < 1) {
      stop("`workers` must be NULL or a single whole number of 1 or more.",
           call. = FALSE)
    }
  }
  if (!is.null(workers) && workers > 1) {
    old_plan <- future::plan(future::multisession, workers = workers)
    on.exit(future::plan(old_plan), add = TRUE)
  }

  sequential <- identical(workers, 1L) ||
    inherits(future::plan(), "uniprocess") || future::nbrOfWorkers() <= 1

  if (sequential || length(x) == 0) {
    parsed_names <- parse_chunk(x, prefixes, suffixes, split_initials)
  } else {
    parsed_names <- parse_on_workers(x, prefixes, suffixes, split_initials)
  }

  out <- data.frame(name = input_names, parsed_names)
  if (add_nicknames) out <- add_nickname_columns(out)
  if (classify) {
    ct <- classify_names(input_names)
    out$name_type <- ct$name_type
    out$org_score <- ct$org_score
  }
  out
}

# Parse a vector of sanitized names in this process.
parse_chunk <- function(x, prefixes, suffixes, split_initials) {
  dplyr::bind_rows(lapply(x, parse_name, prefixes = prefixes,
                          suffixes = suffixes, split_initials = split_initials))
}

# Identify the copy of peopleparser a process has loaded.
pp_fingerprint <- function() {
  d <- utils::packageDescription("peopleparser")
  paste(d$Version, if (is.null(d$Built)) "not installed" else d$Built,
        if (is.null(d$RemoteSha)) "" else d$RemoteSha, sep = " | ")
}

# Parse on the current future plan in chunks; each chunk reports the
# peopleparser build its worker loaded, and a mismatch stops the call.
parse_on_workers <- function(x, prefixes, suffixes, split_initials) {
  n_chunks <- min(length(x), future::nbrOfWorkers() * 4)
  chunks <- split(x, cut(seq_along(x), n_chunks, labels = FALSE))
  res <- furrr::future_map(
    chunks, parse_chunk_on_worker,
    prefixes = prefixes, suffixes = suffixes, split_initials = split_initials,
    fingerprint = pp_fingerprint, expected = pp_fingerprint(),
    .options = furrr::furrr_options(seed = NULL, globals = FALSE,
                                    packages = "peopleparser")
  )
  here <- pp_fingerprint()
  there <- unique(vapply(res, `[[`, "", "fp"))
  if (!all(there == here)) {
    stop("parse_names() workers loaded a different peopleparser than this ",
         "session (session: ", here, "; workers: ",
         paste(setdiff(there, here), collapse = ", "), "). Was it reinstalled ",
         "while R was running, or is this session using devtools::load_all()? ",
         "Restart R, or use workers = 1.", call. = FALSE)
  }
  dplyr::bind_rows(lapply(res, `[[`, "rows"))
}

# Runs on a worker, which resolves parse_chunk() in its own installed
# peopleparser. The fingerprint function is passed in, so the check works even
# when the worker's copy is older than this code; a mismatched worker returns
# before parsing.
parse_chunk_on_worker <- function(xx, prefixes, suffixes, split_initials,
                                  fingerprint, expected) {
  fp <- fingerprint()
  if (!identical(fp, expected)) return(list(fp = fp))
  list(fp = fp, rows = parse_chunk(xx, prefixes, suffixes, split_initials))
}

# Append nickname_lookup() columns to parsed output (uses first_name, gender,
# gender_confidence and salutation).
add_nickname_columns <- function(d) {
  nk <- nickname_lookup(d$first_name, gender = d$gender,
                        gender_confidence = d$gender_confidence,
                        salutation = d$salutation)
  cbind(d, nk)
}
