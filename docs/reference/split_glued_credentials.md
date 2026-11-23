# Split Two Credentials Fused Into One Token

Suffix gaps (data-raw/SUFFIX-GAPS-PART7.md): `JRMD` -\> `c("JR", "MD")`,
`MDMPH` -\> `c("MD", "MPH")`. Splits only when both parts are known
suffixes or credentials of two or more letters, and the whole token is
not itself a census name.
[`deglue_tokens()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/deglue_tokens.md)
applies it only from the third token on, so a given name or initials at
the start are never split.

## Usage

``` r
split_glued_credentials(tok, parts = c(sfx, prx[!grepl(" ", prx)]))
```

## Arguments

- tok:

  A single uppercased name token.

- parts:

  Known suffixes and credentials. Defaults to `sfx` and the single-word
  entries of `prx`.

## Value

The token unchanged, or a length-2 vector of the two credentials.
