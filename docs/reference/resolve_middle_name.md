# Resolve Middle Names as Potential Surnames

Checks if a middle name segment is actually part of the last name.

## Usage

``` r
resolve_middle_name(middle, last, tokens = NULL)
```

## Arguments

- middle:

  Character string of middle name.

- last:

  Character string of last name.

- tokens:

  Optional character vector of the name tokens in their original order.
  When the surname parts sit next to each other there, they are joined
  in that order (`MARY ANN SMITH JONES` gives `SMITH-JONES`, not
  `JONES-SMITH`). Otherwise they are joined middle first, then last.

## Value

A character vector of length 2: updated middle name and last name.
