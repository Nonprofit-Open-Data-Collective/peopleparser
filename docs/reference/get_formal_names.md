# Formal names of a nickname

Formal names of a nickname

## Usage

``` r
get_formal_names(x, gender = NULL, gender_confidence = NULL, sep = ";; ")
```

## Arguments

- x:

  Character vector of first names.

- gender:

  Optional vector of `"M"`, `"F"` or `"U"`, as returned by
  [`parse_name()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/parse_name.md),
  used to choose among formal names.

- gender_confidence:

  Optional vector of gender confidence (0-100), as returned by
  [`parse_name()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/parse_name.md).

- sep:

  Separator for the list columns. Defaults to `";; "`.

## Value

Character vector: the formal forms of each name, most used first, or
`""` if none.

## Examples

``` r
get_formal_names(c("BOB", "PAT", "PAT"), gender = c("M", "F", "M"),
                 gender_confidence = 99)
#> [1] "ROBERT"           "PATRICIA;; PATSY" "PATRICK"         
```
