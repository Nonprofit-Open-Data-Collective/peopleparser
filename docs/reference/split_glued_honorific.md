# Split a Title Glued to a Given Name

Defect 2: `MRWILLIAM` -\> `c("MR", "WILLIAM")`. Only splits when the
leading run is a known personal title, the remainder is a strong census
given name, and the whole token is not itself a known census name
(guards `FREDDIE`, `FRANK`, `DREW`).

## Usage

``` r
split_glued_honorific(tok)
```

## Arguments

- tok:

  A single uppercased name token.

## Value

The token unchanged, or a length-2 vector `c(title, given)`.
