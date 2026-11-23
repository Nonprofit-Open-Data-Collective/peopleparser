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
with 164,850 rows and 5 variables, keyed on `name`:

- name:

  upper-case name (a factor)

- male_value:

  count of men with this first name (1990 lists)

- female_value:

  count of women with this first name (1990 lists)

- first_name_value:

  count as a first name: `male_value + female_value`

- last_name_value:

  count as a surname (2010 surname file)

## Source

U.S. Census Bureau: Frequently Occurring Surnames from the 2010 Census,
and Frequently Occurring Names from the 1990 Census.
<https://www.census.gov/topics/population/genealogy/data.html>

## Details

A frozen copy bundled with the package: it is not downloaded or rebuilt,
and no build script survives. Its contents date from the package's first
commit (2020-08-01), adapted from Michael Flanigan's Name-Parser.
Judging by its contents, the given names are the 1990 Census first-name
lists (1,219 male and 4,275 female names, published as percentages and
scaled here to counts) and the surnames are the 2010 Census surname file
(162,253 names held by 100 or more people, plus an `ALL OTHER NAMES`
row). See
[`vignette("gender-scoring")`](https://nonprofit-open-data-collective.github.io/peopleparser/articles/gender-scoring.md).
