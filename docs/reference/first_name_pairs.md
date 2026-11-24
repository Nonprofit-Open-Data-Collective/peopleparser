# First-name variants: nicknames, spellings, cognates and compounds.

Pairs of first names that are two forms of one given name, observed as
the same person (one EMP_ID) across their own organization's Form 990
Part VII filings, 2010-2024 (15.0 million people). Built in synthid
(`dev/name-variants/`; see the synthid vignette "First-name variants -
how the table was built") and copied here by
`data-raw/first_name_pairs.R`, with some columns dropped and a `formal`
column added. Used by
[`nickname_lookup()`](https://nonprofit-open-data-collective.github.io/peopleparser/reference/nickname_lookup.md).

## Usage

``` r
first_name_pairs
```

## Format

A
[data.table::data.table](https://rdrr.io/pkg/data.table/man/data.table.html)
with 24,967 rows and 13 variables, keyed on `name_short`:

- name_short, name_long:

  the pair, shorter form first

- type:

  `nickname`, `spelling`, `cognate`, `compound` (lexicon), or
  `sound_alike`, `misspelling` (not lexicon)

- lexicon:

  `TRUE` for the reviewed pairs

- n_emp_ids:

  number of people carrying the pair

- freq_short, freq_long:

  national Part VII rows with each first name

- f_short, f_long:

  share of those rows recorded female

- cofiling_rate:

  how often the two forms appear as separate people with one surname on
  one return, per person carrying the pair; high values are weaker
  evidence (JOHN/JOHNNY: father and son)

- flags:

  `""`, `"gender"`, `"cofiling"` or `"cofiling gender"`

- chain_id:

  variant chain: connected component of the lexicon pairs

- formal:

  nickname pairs only: `"short"` or `"long"`, the side that is the
  formal name; `NA` for other types

## Source

synthid `dev/name-variants/first-name-variants.csv`, commit 07c320f
(2026-11-23).

## Details

The 1,002 rows with `lexicon = TRUE` are the pairs seen in 25+ people,
reviewed by hand. The other 23,965 rows are sound-alike and misspelling
pairs from rarer pairs, not reviewed.
