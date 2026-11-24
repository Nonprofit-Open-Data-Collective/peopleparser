# Surname Position in a Two-Token Name

Keeps the written order (first name, then surname) unless the census
makes it much more likely that the name is written surname first.

## Usage

``` r
two_token_surname(x, data)
```

## Arguments

- x:

  A length-2 character vector of name tokens.

- data:

  Census rows for `x`, as returned by
  [`get_census_data()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/get_census_data.md).

## Value

The position (1 or 2) of the surname.

## Details

Each token gets a smoothed surname share, s = (last + a) / (first +
last + 2a), with pseudo-count a = `.order_pseudo_count`, so thin
evidence moves toward 0.5 (RUVIN, with 106 first-name records, no longer
reads as a given name). A token absent from the census gets s =
`.order_unlisted_share`. The tokens are swapped only when the odds that
the name is written surname first, s1 (1 - s2) / ((1 - s1) s2), exceed
`.order_prior_odds`; two-word Form 990 Part VII names are written first
name first about 98% of the time. An unlisted first token of one or two
letters is initials (`HM CHERRY`, `J MARKEL`), and a lone letter
elsewhere gets s = `.order_initial_share` (`BISHOP J` -\> surname
`BISHOP`; `THOMAS H` keeps `H`, a middle initial left after a stripped
surname).

The settings were tuned on 758,388 two-word Part VII names labelled by
the convention of the other names on the same return: see
data-raw/name_order_eval.R and NEWS.md.
