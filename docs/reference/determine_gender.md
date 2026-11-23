# Infer Gender from a Census Name Matrix

Aggregates the male and female birth-certificate counts for the supplied
name tokens and returns the majority gender together with its
confidence.

## Usage

``` r
determine_gender(x)
```

## Arguments

- x:

  A `data.table` of census data as returned by
  [`get_census_data()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/get_census_data.md),
  containing the `male_value` and `female_value` columns.

## Value

A character vector of length two: the inferred gender code (`"M"`,
`"F"`, or `"U"` when no counts are available) and the confidence
percentage for that call. When gender is unknown only `"U"` is returned.

## Examples

``` r
x <- "livingston III,  Mr. MICHAEL JOHN9"
x <- prep_name(x)
x <- strsplit(x, " ")[[1]]
cd <- get_census_data(x)
determine_gender(cd)
#> [1] "M"    "99.6"
```
