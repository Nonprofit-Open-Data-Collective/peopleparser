# Parse a Full Name into Components

Parses a full name string into components such as salutation, first
name, middle name, last name, suffix, status, and inferred gender.

## Usage

``` r
parse_name(
  x,
  prefixes = prx,
  suffixes = sfx,
  sanitize = FALSE,
  split_initials = FALSE,
  add_nicknames = FALSE,
  split_run_together = FALSE
)
```

## Arguments

- x:

  A character string representing a person's name.

- prefixes:

  A character vector of salutations/prefixes to remove. Defaults to
  [prx](https://nonprofit-open-data-collective.github.io/peopleparser/reference/prx.md).

- suffixes:

  A character vector of suffixes to remove. Defaults to
  [sfx](https://nonprofit-open-data-collective.github.io/peopleparser/reference/sfx.md).

- sanitize:

  Logical; if `TRUE`, run
  [`sanitize_input()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/sanitize_input.md)
  on `x` first. Set `FALSE` (the default) when the input has already
  been sanitized, as
  [`parse_names()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/parse_names.md)
  does for the whole vector.

- split_initials:

  Logical; if `TRUE`, also split a stray initial fused onto a surname
  (Defect 3, e.g. `CWOOLFOLK` -\> `C WOOLFOLK`). Off by default because
  it is unreliable on a single record and can break legitimate names
  absent from the census; enable only where cross-year consensus can vet
  the output. See
  [`deglue_tokens()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/deglue_tokens.md).

- add_nicknames:

  Logical; if `TRUE`, append the nickname columns from
  [`nickname_lookup()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/nickname_lookup.md).
  Defaults to `FALSE`.

- split_run_together:

  Logical; if `TRUE`, first split a surname and given name written as
  one word (`KramerKenneth`, `MURPHYSANDRA`) with
  [`split_run_together()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/split_run_together.md).
  The capital-letter rule needs the original case, so with
  `sanitize = FALSE` only the all-capitals rule can apply. Defaults to
  `FALSE`.

## Value

A one-row `data.frame` with columns `salutation`, `first_name`,
`middle_name`, `last_name`, `suffix`, `status`, `gender`, and
`gender_confidence` (plus the nickname columns if
`add_nicknames = TRUE`).

## Examples

``` r
parse_name("LIVINGSTON III MICHAEL JOHN")
#>   salutation first_name middle_name  last_name suffix status gender
#> 1               MICHAEL        JOHN LIVINGSTON    III             M
#>   gender_confidence
#> 1              99.8
parse_name("livingston III,  Mr. MICHAEL JOHN9", sanitize = TRUE)
#>   salutation first_name middle_name  last_name suffix status gender
#> 1         MR    MICHAEL        JOHN LIVINGSTON    III             M
#>   gender_confidence
#> 1              99.8
```
