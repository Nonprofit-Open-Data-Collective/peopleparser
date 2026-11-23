# Determine the Surname (Last Name) Position

Uses census first-name / last-name frequencies (see
[`get_census_data()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/get_census_data.md))
to decide which token in a name vector is most likely the surname.
Tokens are ranked so that names appearing (relatively) more often in the
last-name position rank highest; ties break toward higher overall
frequency and then later ordinal position.

## Usage

``` r
determine_surname(x)
```

## Arguments

- x:

  A census-data `data.table` to evaluate, as produced by
  [`get_census_data()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/get_census_data.md).

## Value

An integer giving the `ordinal` (1-based position) of the most likely
surname. Returns `c(0, 0)` if `x` is not a `data.table`, and `c(1, 2)`
when `x` has a single row.

## Author

mjfii <mick.flanigan@gmail.com>

## Examples

``` r
x <- "livingston III,  Mr. MICHAEL JOHN9"
x <- prep_name(x)
x <- strsplit(x, " ")[[1]]
cd <- get_census_data(x)
determine_surname(cd)
#> [1] 1
```
