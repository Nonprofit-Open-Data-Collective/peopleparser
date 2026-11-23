# Parse a Vector of Names

Parses a character vector of raw names into a data frame of structured
name components. Names are sanitized once up front and then parsed in
parallel with
[`furrr::future_map_dfr()`](https://furrr.futureverse.org/reference/future_map.html).

## Usage

``` r
parse_names(
  x,
  prefixes = prx,
  suffixes = sfx,
  split_initials = FALSE,
  add_nicknames = FALSE,
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

- ...:

  Reserved for future arguments; currently unused.

## Value

A `data.frame` with one row per input name and columns `name` (the
original input) plus the parsed components returned by
[`parse_name()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/parse_name.md):
`salutation`, `first_name`, `middle_name`, `last_name`, `suffix`,
`status`, `gender`, and `gender_confidence`, plus the nickname columns
when `add_nicknames = TRUE`.

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
```
