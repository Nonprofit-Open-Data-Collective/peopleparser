# Determine the Surname (Last Name) Position

Uses census first-name / last-name frequencies (see
[`get_census_data()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/get_census_data.md))
to decide which token in a name vector is most likely the surname.
Tokens are ranked in three tiers: (1) known names that are
overwhelmingly surnames (surname share of at least 0.95), the more
common first; (2) tokens absent from the census; (3) all other known
names by surname share. Remaining ties break toward the later position.
The first tier matters because in the 2020 Census lists nearly every
common surname also appears, rarely, as a given name (4,999 people are
named SMITH), so a pure share would let an unknown token or an initial
outrank SMITH in `"SJ SMITH"`. A single letter comes last of all
(`GLYNN C W SCOTT` -\> `SCOTT`).

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
