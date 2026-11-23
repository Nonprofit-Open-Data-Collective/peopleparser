# Fix Locative or Compound Surnames by Adding Dashes

This function identifies common surname particles (e.g., *Van*, *De*,
*Von*, *Mc*) that typically appear in compound or locative surnames
(e.g., *Van Dyke*, *De La Rosa*) and merges them with the following word
using a dash (e.g., *Van-Dyke*, *De-La-Rosa*).

## Usage

``` r
fix_locative_surnames(
  x,
  particles = c("LA", "VON", "VAN", "DEL", "DE", "DI", "DEN", "DER", "MC", "O")
)
```

## Arguments

- x:

  A character vector of full names.

- particles:

  A character vector of common surname particles to merge with the
  following word. Matching is case-insensitive.

## Value

A character vector of names with compound surnames corrected by
inserting dashes between the particle and the following surname
component.

## Details

These particles, known as *nobiliary particles* or *locative prefixes*,
often denote origin or family lineage and are part of many compound
surnames in European languages.

## See also

For background on surname particles and compound surnames, see
[Wikipedia: Nobiliary
particle](https://en.wikipedia.org/wiki/Particle_(surname)).

## Examples

``` r
names <- c(
  "Jane Van Dyke",
  "Bob VAN DERVAL",
  "Mary von Diesel",
  "Carlos De La Rosa",
  "VAN CLIBURN",
  "Dylan Van"
)

fix_locative_surnames(names)
#> [1] "Jane Van-Dyke"        "Bob VAN-DERVAL"       "Mary von-Diesel"     
#> [4] "Carlos De-La NA-Rosa" "VAN-CLIBURN"          "Dylan Van"           
#> [1] "Jane Van-Dyke"     "Bob VAN-DERVAL"     "Mary von-Diesel"
#> [4] "Carlos De-La-Rosa" "VAN CLIBURN"        "Dylan Van"
```
