# Canonical first name

Canonical first name

## Usage

``` r
canonical_first_name(x, gender = NULL, gender_confidence = NULL)
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

## Value

Character vector of canonical first names (see
[`nickname_lookup()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/nickname_lookup.md)).

## Examples

``` r
canonical_first_name(c("BOB", "BILL", "STEVEN", "KATHY", "KAREN"))
#> [1] "ROBERT"  "WILLIAM" "STEPHEN" "KATHY"   "KAREN"  
```
