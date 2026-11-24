# Unknown Credentials at the End of a Name

Finds trailing words that are not in the census and read as a credential
or organisation code the title lists do not know, so that they are
stripped rather than taken as the surname (`ANDREA M GORDON NMF` -\>
`GORDON`, `ANTHONY F CHONG MD FAAFP` -\> `CHONG`). A word missing from
the census at the end of the name counts when it

- follows a known title, suffix or credential (`RN BSN MHA NEA-BC`,
  `SCOTT III NMHC`), or another word stripped by this rule;

- is in `trailing_credentials`, words that end the Part VII names of
  many different people after a surname (built by
  data-raw/trailing_credentials.R), and follows a census surname; or

- is a short code (five letters or fewer, at most one vowel, Y included)
  after a census surname (`BRIAN FRITZ UHC`, `SCOTT WILLIS USMCR`). Only
  the run of such words at the end is taken, and two name words always
  stay. A surname missing from the census after a given name
  (`CYNTHIA SIMON SKJODT`, `NOREEN GORDON SABLOTSKY`) is kept.

## Usage

``` r
unknown_trailing_credentials(name_vec, prefixes, suffixes)
```

## Arguments

- name_vec:

  A character vector of name tokens.

- prefixes, suffixes:

  The active prefix/suffix removal sets.

## Value

A character vector of tokens to strip (possibly empty).
