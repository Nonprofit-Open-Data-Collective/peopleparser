# U.S. Census first-name and surname frequencies.

Names with how often each is a given name (by gender) and a surname in
U.S. Census Bureau name lists. Used to decide name order and to score
gender.

## Usage

``` r
census.names
```

## Format

A
[data.table::data.table](https://rdrr.io/pkg/data.table/man/data.table.html)
with 195,311 rows and 5 variables, keyed on `name`:

- name:

  upper-case name (a factor)

- male_value:

  people with this first name recorded male (2020)

- female_value:

  people with this first name recorded female (2020)

- first_name_value:

  count as a first name: `male_value + female_value`

- last_name_value:

  people with this surname (2020)

## Source

U.S. Census Bureau, Frequently Occurring First Names and Last Names from
the 2020 Census:
<https://www.census.gov/topics/population/genealogy/data/2020_names.html>

## Details

Built by `data-raw/census_names.R` from the Census Bureau's 2020
release, "Frequently Occurring First Names and Last Names from the 2020
Census" (revised 2026-04-09): 53,615 first names held by 91 or more
people, with counts by sex, and 156,621 surnames held by 92 or more
people, each list ending in an `ALL OTHER NAMES` row. The script
downloads the files, records their hashes in
`data-raw/census-names-src.csv`, and rebuilds the table, so it can be
refreshed when the Bureau publishes new lists.

Until November 2026 the package shipped a table from the 1990 first-name
lists (1,219 male and 4,275 female names, given as percentages and
scaled to counts) and the 2010 surname file. The 2020 lists cover ten
times as many given names and fit Form 990 names better (see NEWS.md).
See
[`vignette("gender-scoring")`](https://nonprofit-open-data-collective.github.io/peopleparser/articles/gender-scoring.md).
