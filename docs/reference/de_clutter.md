# Remove Nuisance Text From a Name

Strips common noise strings from raw name records — trailing titles,
tenure notes ("AS OF ...", "RESIGNED"), schedule references, date
ranges, and similar clutter — before the name is parsed.

## Usage

``` r
de_clutter(x)
```

## Arguments

- x:

  A character vector of raw, upper-cased name strings.

## Value

A character vector with the nuisance substrings removed.

## Examples

``` r
de_clutter("ROBERT NAGLE - SMFA BOARD OF")
#> [1] "ROBERT NAGLE"
```
