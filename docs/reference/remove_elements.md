# Remove Character Elements From a Vector

Splits a character vector into the elements that match a removal set and
those that remain. Used to peel salutations, suffixes, and status flags
off a name vector during parsing.

## Usage

``` r
remove_elements(x, elements)
```

## Arguments

- x:

  A character vector to filter.

- elements:

  A character vector of values to remove from `x`.

## Value

A list with two components: `names` (the elements of `x` that were not
removed) and `removed_names` (the removed elements collapsed into a
single underscore-separated string, or `""` when nothing matched).

## Examples

``` r
x <- c("MICHAEL", "JOHN", "LIVINGSTON", "III")
remove_elements(x, c("JR", "II", "III", "IV"))
#> $names
#> [1] "MICHAEL"    "JOHN"       "LIVINGSTON"
#> 
#> $removed_names
#> [1] "III"
#> 
```
