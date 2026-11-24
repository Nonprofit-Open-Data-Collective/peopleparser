# Parse a Vector of Names

Parses a character vector of raw names into a data frame of structured
name components. Names are sanitized once up front and then parsed with
[`parse_name()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/parse_name.md).

## Usage

``` r
parse_names(
  x,
  prefixes = prx,
  suffixes = sfx,
  split_initials = FALSE,
  add_nicknames = FALSE,
  split_run_together = FALSE,
  classify = FALSE,
  workers = NULL,
  ...
)
```

## Arguments

- x:

  A character vector of raw names to parse.

- prefixes:

  A character vector of salutations/prefixes to remove. Defaults to
  [prx](https://nonprofit-open-data-collective.github.io/peopleparser/reference/prx.md).

- suffixes:

  A character vector of suffixes to remove. Defaults to
  [sfx](https://nonprofit-open-data-collective.github.io/peopleparser/reference/sfx.md).

- split_initials:

  Logical; forwarded to
  [`parse_name()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/parse_name.md)
  to enable the opt-in Defect 3 stray-initial split. Defaults to
  `FALSE`.

- add_nicknames:

  Logical; if `TRUE`, append the nickname columns from
  [`nickname_lookup()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/nickname_lookup.md)
  (`first_name_type`, `first_name_formal`, `first_name_nicknames`,
  `first_name_canonical`, `canonical_rule`). Defaults to `FALSE`.

- split_run_together:

  Logical; if `TRUE`, split a surname and given name written as one word
  (`KramerKenneth`, `MURPHYSANDRA`) before parsing, with
  [`split_run_together()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/split_run_together.md).
  Defaults to `FALSE`.

- classify:

  Logical; if `TRUE`, add the `name_type` and `org_score` columns from
  [`classify_names()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/classify_names.md),
  computed on the raw input, so that organisations, placeholders and
  couples can be set aside. Defaults to `FALSE`.

- workers:

  `NULL` (default) to use the caller's
  [`future::plan()`](https://future.futureverse.org/reference/plan.html)
  (sequential unless the caller set one), `1` to run in this session
  whatever the plan, or a number above 1 to start that many workers for
  this call. See *Parallel parsing*.

- ...:

  Reserved for future arguments; currently unused.

## Value

A `data.frame` with one row per input name and columns `name` (the
original input) plus the parsed components returned by
[`parse_name()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/parse_name.md):
`salutation`, `first_name`, `middle_name`, `last_name`, `suffix`,
`status`, `gender`, and `gender_confidence`, plus the nickname columns
when `add_nicknames = TRUE` and `name_type` and `org_score` when
`classify = TRUE`.

## Parallel parsing

By default `parse_names()` runs in the current R session and never
starts background processes on its own. It uses parallel workers in two
cases:

- the caller has set a
  [`future::plan()`](https://future.futureverse.org/reference/plan.html),
  for example `future::plan(future::multisession, workers = 4)`. The
  workers are reused across calls until the caller changes the plan;

- `workers` is a number above 1. `parse_names()` starts that many
  background R sessions for this call and shuts them down when it
  returns, restoring the caller's plan.

Workers load the installed copy of peopleparser. Each one reports its
version and build time, and `parse_names()` stops if any differs from
the calling session (for example after a reinstall while R was running,
or when the session runs development code through
[`devtools::load_all()`](https://devtools.r-lib.org/reference/load_all.html)).
Starting workers takes a few seconds, so they pay off only for large
inputs.

## Examples

``` r
x <- c("livingston III,  Mr. MICHAEL JOHN9", "THOMAS H VON KAMECKE")
parse_names(x)
#>                                 name salutation first_name middle_name
#> 1 livingston III,  Mr. MICHAEL JOHN9         MR    MICHAEL        JOHN
#> 2               THOMAS H VON KAMECKE                THOMAS           H
#>     last_name suffix status gender gender_confidence
#> 1  LIVINGSTON    III             M              99.8
#> 2 VON-KAMECKE                    M              99.9

if (FALSE) { # \dontrun{
# start 4 workers for one large call
parse_names(big_vector, workers = 4)

# or keep workers running across several calls
future::plan(future::multisession, workers = 4)
a <- parse_names(batch_1)
b <- parse_names(batch_2)
future::plan(future::sequential)
} # }
```
