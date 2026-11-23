# Ambiguous Suffix Credentials Eligible to Strip

Returns the ambiguous short credentials (e.g. `RM`) that appear inside
the maximal trailing run of known prefix/suffix tokens, provided that
run also contains at least one unambiguous credential. Callers add the
result to the prefix-removal set for that name only.

## Usage

``` r
trailing_ambiguous_credentials(
  name_vec,
  prefixes,
  suffixes,
  ambiguous = .ambiguous_suffix_credentials
)
```

## Arguments

- name_vec:

  A character vector of name tokens.

- prefixes, suffixes:

  The active prefix/suffix removal sets.

- ambiguous:

  The ambiguous short-credential set.

## Value

A character vector of tokens to strip (possibly empty).
