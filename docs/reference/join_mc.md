# Join a Split "MC" Surname Prefix

Inside a name, a standalone `MC` starts a surname written with a space
(`STEVE MC CORMICK`, `DENISE MC DERMOTT`). It is joined to the next word
without a dash (`MCCORMICK`), the spelling the census lists and other
records use. A leading `MC` before two or more words is joined to the
next word with a dash (`MC NELLY TORRES` -\> `MC-NELLY`); before one
word it is left as initials (`MC OLSON`). A trailing `MC` is a
credential (Navy Medical Corps) and is left for the title rules, as is
an `MC` followed by a credential or suffix (`SANFORD MC USN`) or by a
word starting with `MC`.

## Usage

``` r
join_mc(x)
```

## Arguments

- x:

  A character vector of upper-cased, space-separated names.

## Value

`x` with split `MC` surnames joined.

## Details

(This replaces a rule that cut everything after a standalone `MC`, which
turned `CHARLES MC SPADDEN` into `CHARLES MC`.)
