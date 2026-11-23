# Check Whether Tokens Read as Surnames

For each token, compares its census first-name and last-name frequencies
and flags it as a surname when it appears more often in the last-name
position.

## Usage

``` r
check_if_surname(x)
```

## Arguments

- x:

  A character vector of name tokens.

## Value

A logical vector, one element per token, `TRUE` where the token is more
likely a surname than a given name.

## Examples

``` r
check_if_surname(c("MICHAEL", "LIVINGSTON"))
#> [1] FALSE  TRUE
```
