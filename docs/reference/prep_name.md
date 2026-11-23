# Prep a Name for Parsing

Normalizes raw name strings ahead of parsing: replaces periods with
spaces, upper-cases, strips punctuation (keeping dashes) and digits,
collapses whitespace, folds a set of period-separated abbreviations
(e.g. `PH D` -\> `PHD`), and dashes compound / locative surnames (see
[`fix_locative_surnames()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/fix_locative_surnames.md)).

## Usage

``` r
prep_name(x)
```

## Arguments

- x:

  A character vector of raw names to prep.

## Value

A character vector of cleaned, upper-cased names.

## Examples

``` r
prep_name("livingston III,   MICHAEL JOHN9")
#> [1] "LIVINGSTON III MICHAEL JOHN"
```
