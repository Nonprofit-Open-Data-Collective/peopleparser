# Nicknames of a formal first name

Nicknames of a formal first name

## Usage

``` r
get_nicknames(x, sep = ";; ")
```

## Arguments

- x:

  Character vector of first names.

- sep:

  Separator. Defaults to `";; "`.

## Value

Character vector: the nicknames of each name, most used first, or `""`
if none.

## Examples

``` r
get_nicknames(c("RICHARD", "ELIZABETH", "KAREN"))
#> [1] "RICK;; RICH;; DICK;; RICKY;; RICHIE"                     
#> [2] "LIZ;; BETH;; BETSY;; LISA;; LIBBY;; LIZA;; ELLIE;; LIZZY"
#> [3] ""                                                        
```
