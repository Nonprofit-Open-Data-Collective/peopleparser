# Position-Restricted Titles and Status Words to Strip

Finds the tokens that may be stripped from this name only because of
where they sit: trailing-only titles and tenure status words inside the
maximal trailing run of known tokens (each with at least two tokens
before it), and a leading-only title in first position (with at least
two tokens after it).

## Usage

``` r
positional_tokens(name_vec, prefixes, suffixes)
```

## Arguments

- name_vec:

  A character vector of name tokens.

- prefixes, suffixes:

  The active prefix/suffix removal sets.

## Value

A list with `titles` (tokens to add to the prefix set for this name) and
`status` (tokens to add to the status set).
