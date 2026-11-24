# Split a Surname and Given Name Written as One Word

Some records run a person's surname and given name together:
`KramerKenneth`, `LedbetterJennifer A`, `MURPHYSANDRA`.
`split_run_together()` puts the space back when the evidence is strong,
and leaves every other name alone. The parser's order rules then decide
which part is the surname, as for any other name.

## Usage

``` r
split_run_together(x)
```

## Arguments

- x:

  A character vector of raw names.

## Value

`x`, with a space inserted where a run-together word was split.

## Details

Two rules, both requiring that the whole word is not itself a name in
[census.names](https://nonprofit-open-data-collective.github.io/peopleparser/reference/census.names.md):

- **A capital letter inside a word** (`KramerKenneth`): split at the
  capital when both parts have at least three letters, one is mostly a
  surname and the other mostly a given name in the census (at least 80%
  of 500 or more records), and the first part is not a surname particle
  (`McDonald`, `MacArthur`, `DeShawn`, `LaToya`, `VanDyke` and similar
  are left alone).

- **All capitals** (`MURPHYSANDRA`): only when the word is the name's
  one word of two or more letters (other words are initials, titles or
  suffixes), has at least eight letters, and splits into a strong
  surname (95% of 2,000 or more records) and a strong given name (95% of
  20,000 or more records), each of four or more letters. Words that
  recur in many different Form 990 names (`MARKWALD`, `PEARLSTONE`,
  `GLENFIELD`) are real surnames and are never split.

The all-capitals rule is the riskier of the two: a rare surname can look
like two common names. That is why
[`parse_names()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/parse_names.md)
runs neither rule unless asked (`split_run_together = TRUE`).

## See also

[`vignette("name-types")`](https://nonprofit-open-data-collective.github.io/peopleparser/articles/name-types.md)

## Examples

``` r
split_run_together(c("KramerKenneth", "LedbetterJennifer A", "MURPHYSANDRA",
                     "McDonald", "LaToya Smith", "JOHN MARKWALD", "MARKWALD J"))
#> [1] "Kramer Kenneth"       "Ledbetter Jennifer A" "MURPHY SANDRA"       
#> [4] "McDonald"             "LaToya Smith"         "JOHN MARKWALD"       
#> [7] "MARKWALD J"          
```
