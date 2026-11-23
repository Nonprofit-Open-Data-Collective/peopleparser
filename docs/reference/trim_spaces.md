# Collapse and Trim Whitespace

Removes leading and trailing whitespace and collapses runs of internal
whitespace to a single space.

## Usage

``` r
trim_spaces(x)
```

## Arguments

- x:

  A character vector.

## Value

A character vector with normalized whitespace.

## Examples

``` r
trim_spaces("  JOHN   Q   PUBLIC  ")
#> [1] "JOHN Q PUBLIC"
```
